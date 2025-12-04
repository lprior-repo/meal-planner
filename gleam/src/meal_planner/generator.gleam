/// Generator module for meal slot regeneration using knapsack solver
import gleam/list
import meal_planner/generator/knapsack.{type KnapsackError}
import meal_planner/meal_plan.{type DailyPlan, type Meal, Meal}
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
  // Validate slot name
  use idx <- result_then(slot_index(slot))

  // Check that slot exists in daily plan
  case list.length(day_plan.meals) > idx {
    False -> Error(SlotNotFound(slot))
    True -> {
      // Validate inputs
      case list.length(available_recipes) {
        0 -> Error(NoRecipesAvailable)
        _ ->
          case target <= 0 {
            True -> Error(InvalidTarget)
            False -> {
              // Calculate remaining calories for this slot
              let remaining =
                calculate_remaining_calories(day_plan, idx, target)

              // Use knapsack solver to find single best recipe
              case knapsack.solve(remaining, available_recipes, 1) {
                Ok(recipes) ->
                  case list.first(recipes) {
                    Ok(recipe) -> Ok(recipe)
                    Error(Nil) -> Error(NoRecipesAvailable)
                  }
                Error(ks_error) -> Error(KnapsackError(ks_error))
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
