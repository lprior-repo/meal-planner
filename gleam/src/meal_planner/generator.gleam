/// Generator module for meal slot regeneration using knapsack solver
import gleam/int
import gleam/list
import meal_planner/generator/knapsack.{type KnapsackError}
import meal_planner/logger
import meal_planner/meal_plan.{type DailyPlan, DailyPlan, Meal}
import meal_planner/types.{type Recipe, macros_calories}

/// Error type for generator functions
pub type GeneratorError {
  /// Invalid slot name (not breakfast, lunch, or dinner)
  InvalidSlot(slot: String)
  /// Slot not found in daily plan
  SlotNotFound(slot: String)
  /// Knapsack solver returned an error
  KnapsackError(error: KnapsackError)
  /// No recipes available for selection
  NoRecipesAvailable
  /// Target calories is invalid
  InvalidTarget
  /// Not enough recipes returned from solver (less than requested)
  InsufficientRecipes(needed: Int, got: Int)
}

/// Convert GeneratorError to a human-readable error message
pub fn error_to_string(error: GeneratorError) -> String {
  case error {
    InvalidSlot(slot) ->
      "Invalid meal slot '" <> slot <> "'. Must be breakfast, lunch, or dinner"
    SlotNotFound(slot) ->
      "Meal slot '" <> slot <> "' not found in daily plan"
    KnapsackError(ks_error) ->
      "Meal selection failed: " <> knapsack.error_to_string(ks_error)
    NoRecipesAvailable -> "No recipes available for meal planning"
    InvalidTarget -> "Invalid calorie target. Must be positive and at least 300 calories"
    InsufficientRecipes(needed, got) ->
      "Not enough meals selected. Needed "
      <> int.to_string(needed)
      <> " but only got "
      <> int.to_string(got)
  }
}

/// Get the index of a meal slot (0=breakfast, 1=lunch, 2=dinner)
fn slot_index(slot: String) -> Result(Int, GeneratorError) {
  case slot {
    "breakfast" -> Ok(0)
    "lunch" -> Ok(1)
    "dinner" -> Ok(2)
    _ -> Error(InvalidSlot(slot))
  }
}

/// Calculate remaining calories for a meal slot
/// Returns target - sum(other meals)
fn calculate_remaining_calories(
  day_plan: DailyPlan,
  slot_index: Int,
  target: Int,
) -> Int {
  let other_meals =
    list.index_map(day_plan.meals, fn(meal, idx) {
      case idx == slot_index {
        True -> 0
        False -> {
          let macros = meal.recipe.macros
          let calories = macros_calories(macros)
          let rounded = calories +. 0.5
          case rounded >=. 0.0 {
            True -> float_to_int(rounded)
            False -> 0
          }
        }
      }
    })

  let other_total = list.fold(other_meals, 0, fn(acc, cal) { acc + cal })
  target - other_total
}

@external(erlang, "erlang", "trunc")
fn float_to_int(f: Float) -> Int

/// Regenerate a single meal slot in a daily plan
/// Calculates remaining calories for the slot and uses knapsack solver to find best recipe
///
/// # Arguments
/// * `day_plan` - The daily meal plan
/// * `slot` - Slot name: "breakfast", "lunch", or "dinner"
/// * `target` - Total calorie target for the day
/// * `available_recipes` - List of recipes to choose from
///
/// # Returns
/// * `Ok(Recipe)` - New recipe for the slot
/// * `Error(GeneratorError)` - Error if slot is invalid or solver fails
pub fn regenerate_slot(
  day_plan: DailyPlan,
  slot: String,
  target: Int,
  available_recipes: List(Recipe),
) -> Result(Recipe, GeneratorError) {
  logger.debug(
    "Regenerating slot '"
    <> slot
    <> "' for day '"
    <> day_plan.day_name
    <> "' with target "
    <> int.to_string(target)
    <> " calories",
  )

  // Validate slot name
  use idx <- result_then(slot_index(slot))

  // Check that slot exists in daily plan
  case list.length(day_plan.meals) > idx {
    False -> {
      logger.error(
        "Regenerate slot failed: Slot '"
        <> slot
        <> "' not found in daily plan",
      )
      Error(SlotNotFound(slot))
    }
    True -> {
      // Validate inputs
      case list.length(available_recipes) {
        0 -> {
          logger.error("Regenerate slot failed: No recipes available")
          Error(NoRecipesAvailable)
        }
        recipe_count ->
          case target <= 0 {
            True -> {
              logger.error(
                "Regenerate slot failed: Invalid target ("
                <> int.to_string(target)
                <> ")",
              )
              Error(InvalidTarget)
            }
            False -> {
              // Calculate remaining calories for this slot
              let remaining =
                calculate_remaining_calories(day_plan, idx, target)

              logger.debug(
                "Slot '"
                <> slot
                <> "' has "
                <> int.to_string(remaining)
                <> " remaining calories. Selecting from "
                <> int.to_string(recipe_count)
                <> " recipes",
              )

              // Use knapsack solver to find single best recipe
              case knapsack.solve(remaining, available_recipes, 1) {
                Ok(recipes) ->
                  case list.first(recipes) {
                    Ok(recipe) -> {
                      logger.info(
                        "Successfully regenerated slot '"
                        <> slot
                        <> "' with recipe: "
                        <> recipe.name,
                      )
                      Ok(recipe)
                    }
                    Error(Nil) -> {
                      logger.error(
                        "Regenerate slot failed: Knapsack solver returned empty list",
                      )
                      Error(NoRecipesAvailable)
                    }
                  }
                Error(ks_error) -> {
                  logger.error(
                    "Regenerate slot failed: "
                    <> knapsack.error_to_string(ks_error),
                  )
                  Error(KnapsackError(ks_error))
                }
              }
            }
          }
      }
    }
  }
}

/// Generate a meal plan with one locked food
///
/// # Arguments
/// * `target` - Total calorie target for the day
/// * `locked_food` - Recipe that must be included in the plan
/// * `available_recipes` - List of recipes to choose from for other meals
///
/// # Returns
/// * `Ok(DailyPlan)` - Full day plan including locked food
/// * `Error(GeneratorError)` - Error if solver fails or insufficient recipes
pub fn generate_with_locked(
  target: Int,
  locked_food: Recipe,
  available_recipes: List(Recipe),
) -> Result(DailyPlan, GeneratorError) {
  logger.debug(
    "Generating meal plan with locked food: "
    <> locked_food.name
    <> ". Target: "
    <> int.to_string(target)
    <> " calories",
  )

  // Validate target
  case target <= 0 {
    True -> {
      logger.error(
        "Generate with locked failed: Invalid target ("
        <> int.to_string(target)
        <> ")",
      )
      Error(InvalidTarget)
    }
    False -> {
      // Validate available recipes
      case list.length(available_recipes) {
        0 -> {
          logger.error(
            "Generate with locked failed: No recipes available for other slots",
          )
          Error(NoRecipesAvailable)
        }
        _recipe_count -> {
          // Calculate calories for locked food
          let locked_calories =
            macros_calories(locked_food.macros)
            |> fn(f) { float_to_int(f +. 0.5) }()

          // Calculate remaining calories for other meals
          let remaining = target - locked_calories

          logger.debug(
            "Locked food '"
            <> locked_food.name
            <> "' has "
            <> int.to_string(locked_calories)
            <> " calories. Remaining: "
            <> int.to_string(remaining)
            <> " calories for 2 meals",
          )

          // If remaining is negative or too small, return error
          case remaining < 100 {
            True -> {
              logger.error(
                "Generate with locked failed: Not enough remaining calories ("
                <> int.to_string(remaining)
                <> "). Locked food uses "
                <> int.to_string(locked_calories)
                <> " of "
                <> int.to_string(target)
                <> " target",
              )
              Error(InvalidTarget)
            }
            False -> {
              // Use knapsack solver to find 2 best recipes for remaining meals
              case knapsack.solve(remaining, available_recipes, 2) {
                Error(ks_error) -> {
                  logger.error(
                    "Generate with locked failed: "
                    <> knapsack.error_to_string(ks_error),
                  )
                  Error(KnapsackError(ks_error))
                }
                Ok(selected_recipes) -> {
                  let selected_count = list.length(selected_recipes)

                  // Verify we got exactly 2 recipes
                  case selected_count {
                    2 -> {
                      // Build the daily plan with locked food and selected meals
                      let meal1 = Meal(recipe: locked_food, portion_size: 1.0)
                      case list.first(selected_recipes) {
                        Ok(recipe2) -> {
                          let meal2 = Meal(recipe: recipe2, portion_size: 1.0)
                          case list.rest(selected_recipes) {
                            Ok(rest) ->
                              case list.first(rest) {
                                Ok(recipe3) -> {
                                  let meal3 =
                                    Meal(recipe: recipe3, portion_size: 1.0)
                                  logger.info(
                                    "Successfully generated meal plan with locked food '"
                                    <> locked_food.name
                                    <> "' and 2 additional meals",
                                  )
                                  Ok(
                                    DailyPlan(day_name: "generated", meals: [
                                      meal1,
                                      meal2,
                                      meal3,
                                    ]),
                                  )
                                }
                                Error(_) -> {
                                  logger.error(
                                    "Generate with locked failed: Could not extract second recipe from list",
                                  )
                                  Error(InsufficientRecipes(2, 1))
                                }
                              }
                            Error(_) -> {
                              logger.error(
                                "Generate with locked failed: Could not get rest of recipe list",
                              )
                              Error(InsufficientRecipes(2, 1))
                            }
                          }
                        }
                        Error(_) -> {
                          logger.error(
                            "Generate with locked failed: Could not extract first recipe from list",
                          )
                          Error(InsufficientRecipes(2, 0))
                        }
                      }
                    }
                    _ -> {
                      logger.error(
                        "Generate with locked failed: Knapsack solver returned "
                        <> int.to_string(selected_count)
                        <> " recipes instead of 2",
                      )
                      Error(InsufficientRecipes(2, selected_count))
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

/// Helper for chaining Result operations
fn result_then(result: Result(a, e), f: fn(a) -> Result(b, e)) -> Result(b, e) {
  case result {
    Ok(val) -> f(val)
    Error(err) -> Error(err)
  }
}
