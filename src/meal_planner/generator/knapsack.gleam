/// Knapsack solver module for meal selection based on calorie targets.
/// Uses a greedy algorithm to select meals that best match the target calories.
import gleam/int
import gleam/list
import meal_planner/logger
import meal_planner/types/macros
import meal_planner/types/recipe.{type Recipe}

/// Error type for knapsack solver
pub type KnapsackError {
  /// No recipes provided
  NoRecipes
  /// Target calories is invalid (zero or negative)
  InvalidTarget
  /// Number of meals is invalid (zero or negative)
  InvalidMealCount
  /// Not enough recipes to fill requested meal count
  NotEnoughRecipes
  /// Target calories exceeded
  TargetExceeded(total: Int)
}

/// Convert KnapsackError to a human-readable error message
pub fn error_to_string(error: KnapsackError) -> String {
  case error {
    NoRecipes -> "No recipes available for meal selection"
    InvalidTarget -> "Target calories must be greater than zero"
    InvalidMealCount -> "Number of meals must be greater than zero"
    NotEnoughRecipes ->
      "Not enough unique recipes to fill all requested meal slots"
    TargetExceeded(total) ->
      "Selected meals exceed target calories. Total: "
      <> int.to_string(total)
      <> " calories"
  }
}

fn recipe_calories(recipe: Recipe) -> Int {
  let macros = recipe.macros
  let calories = macros.calories(macros)
  let rounded = calories +. 0.5
  case rounded >=. 0.0 {
    True -> float_to_int(rounded)
    False -> 0
  }
}

@external(erlang, "erlang", "trunc")
fn float_to_int(f: Float) -> Int

/// Solve the knapsack problem using a greedy approach.
/// Selects meals closest to the per-meal calorie target in each iteration.
///
/// # Arguments
/// * `target_calories` - Total calorie budget
/// * `recipes` - List of available recipes
/// * `num_meals` - Number of meals to select
///
/// # Returns
/// * `Ok(List(Recipe))` - Selected recipes if successful
/// * `Error(KnapsackError)` - Error if constraints cannot be met
pub fn solve(
  target_calories: Int,
  recipes: List(Recipe),
  num_meals: Int,
) -> Result(List(Recipe), KnapsackError) {
  case num_meals <= 0 {
    True -> {
      logger.error(
        "Knapsack solver failed: Invalid number of meals ("
        <> int.to_string(num_meals)
        <> ")",
      )
      Error(InvalidMealCount)
    }
    False ->
      case target_calories <= 0 {
        True -> {
          logger.error(
            "Knapsack solver failed: Invalid target calories ("
            <> int.to_string(target_calories)
            <> ")",
          )
          Error(InvalidTarget)
        }
        False ->
          case list.length(recipes) {
            0 -> {
              logger.error(
                "Knapsack solver failed: No recipes available for selection",
              )
              Error(NoRecipes)
            }
            len if len < num_meals -> {
              logger.error(
                "Knapsack solver failed: Not enough recipes. Need "
                <> int.to_string(num_meals)
                <> " meals but only have "
                <> int.to_string(len)
                <> " recipes",
              )
              Error(NotEnoughRecipes)
            }
            _ -> {
              let per_meal_target = target_calories / num_meals
              logger.debug(
                "Knapsack solver: Selecting "
                <> int.to_string(num_meals)
                <> " meals from "
                <> int.to_string(list.length(recipes))
                <> " recipes. Target: "
                <> int.to_string(target_calories)
                <> " cal, per-meal: "
                <> int.to_string(per_meal_target)
                <> " cal",
              )

              let selected =
                greedy_select(recipes, per_meal_target, num_meals, [])

              let total = calculate_total_calories(selected)
              case total > target_calories {
                True -> {
                  logger.error(
                    "Knapsack solver failed: Selected meals exceed target. Total: "
                    <> int.to_string(total)
                    <> " cal, target: "
                    <> int.to_string(target_calories)
                    <> " cal",
                  )
                  Error(TargetExceeded(total))
                }
                False -> {
                  logger.info(
                    "Knapsack solver succeeded: Selected "
                    <> int.to_string(list.length(selected))
                    <> " meals with total "
                    <> int.to_string(total)
                    <> " calories (target: "
                    <> int.to_string(target_calories)
                    <> ")",
                  )
                  Ok(selected)
                }
              }
            }
          }
      }
  }
}

fn greedy_select(
  available: List(Recipe),
  per_meal_target: Int,
  remaining: Int,
  selected: List(Recipe),
) -> List(Recipe) {
  case remaining {
    0 -> selected
    _ -> {
      case find_closest_recipe(available, per_meal_target) {
        Ok(#(recipe, rest)) -> {
          greedy_select(rest, per_meal_target, remaining - 1, [
            recipe,
            ..selected
          ])
        }
        Error(Nil) -> selected
      }
    }
  }
}

fn find_closest_recipe(
  recipes: List(Recipe),
  target: Int,
) -> Result(#(Recipe, List(Recipe)), Nil) {
  case recipes {
    [] -> Error(Nil)
    [first, ..rest] -> {
      let first_cal = recipe_calories(first)
      find_closest_helper(rest, target, first, abs_diff(first_cal, target), [])
    }
  }
}

fn find_closest_helper(
  remaining: List(Recipe),
  target: Int,
  best: Recipe,
  best_diff: Int,
  excluded: List(Recipe),
) -> Result(#(Recipe, List(Recipe)), Nil) {
  case remaining {
    [] -> {
      let rest = list.append(excluded, [])
      Ok(#(best, rest))
    }
    [recipe, ..rest] -> {
      let cal = recipe_calories(recipe)
      let diff = abs_diff(cal, target)
      case diff < best_diff {
        True -> {
          find_closest_helper(rest, target, recipe, diff, [best, ..excluded])
        }
        False -> {
          find_closest_helper(rest, target, best, best_diff, [
            recipe,
            ..excluded
          ])
        }
      }
    }
  }
}

fn abs_diff(a: Int, b: Int) -> Int {
  let diff = a - b
  case diff < 0 {
    True -> -diff
    False -> diff
  }
}

fn calculate_total_calories(recipes: List(Recipe)) -> Int {
  list.fold(recipes, 0, fn(acc, recipe) { acc + recipe_calories(recipe) })
}
