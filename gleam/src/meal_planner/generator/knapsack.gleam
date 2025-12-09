/// Knapsack solver module for meal selection based on calorie targets.
/// Uses a greedy algorithm to select meals that best match the target calories.
import gleam/list
import meal_planner/types.{type Recipe, macros_calories}

/// Error type for knapsack solver
pub type KnapsackError {
  /// No recipes provided
  NoRecipes
  /// Target calories is invalid (zero or negative)
  InvalidTarget
  /// Not enough recipes to fill requested meal count
  NotEnoughRecipes
  /// Target calories exceeded
  TargetExceeded(total: Int)
}

/// Calculate calories from a recipe's macros
fn recipe_calories(recipe: Recipe) -> Int {
  let macros = recipe.macros
  let calories = macros_calories(macros)
  let rounded = calories +. 0.5
  // Simple truncation to int
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
  // Validate inputs
  case target_calories <= 0 {
    True -> Error(InvalidTarget)
    False -> {
      case list.length(recipes) {
        0 -> Error(NoRecipes)
        len if len < num_meals -> Error(NotEnoughRecipes)
        _ -> {
          // Calculate per-meal target
          let per_meal_target = target_calories / num_meals

          // Greedy selection: repeatedly pick best matching recipe
          let selected = greedy_select(recipes, per_meal_target, num_meals, [])

          // Verify total doesn't exceed target
          let total = calculate_total_calories(selected)
          case total > target_calories {
            True -> Error(TargetExceeded(total))
            False -> Ok(selected)
          }
        }
      }
    }
  }
}

/// Greedy selection: pick recipe closest to target for each meal
fn greedy_select(
  available: List(Recipe),
  per_meal_target: Int,
  remaining: Int,
  selected: List(Recipe),
) -> List(Recipe) {
  case remaining {
    0 -> selected
    _ -> {
      // Find recipe closest to per_meal_target
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

/// Find the recipe closest to target calories
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

/// Helper to find closest recipe while tracking remaining recipes
fn find_closest_helper(
  remaining: List(Recipe),
  target: Int,
  best: Recipe,
  best_diff: Int,
  excluded: List(Recipe),
) -> Result(#(Recipe, List(Recipe)), Nil) {
  case remaining {
    [] -> {
      // Return best recipe and all others (excluding it)
      let rest = list.append(excluded, [])
      Ok(#(best, rest))
    }
    [recipe, ..rest] -> {
      let cal = recipe_calories(recipe)
      let diff = abs_diff(cal, target)
      case diff < best_diff {
        True -> {
          // This is better, so add previous best to excluded
          find_closest_helper(rest, target, recipe, diff, [best, ..excluded])
        }
        False -> {
          // Previous best is still better
          find_closest_helper(rest, target, best, best_diff, [
            recipe,
            ..excluded
          ])
        }
      }
    }
  }
}

/// Calculate absolute difference between two integers
fn abs_diff(a: Int, b: Int) -> Int {
  let diff = a - b
  case diff < 0 {
    True -> -diff
    False -> diff
  }
}

/// Calculate total calories from a list of recipes
fn calculate_total_calories(recipes: List(Recipe)) -> Int {
  list.fold(recipes, 0, fn(acc, recipe) { acc + recipe_calories(recipe) })
}
