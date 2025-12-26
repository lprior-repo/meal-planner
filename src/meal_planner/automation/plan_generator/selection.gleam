//// Recipe Selection and Categorization
////
//// Implements recipe pool management:
//// - Categorization by meal type (breakfast/lunch/dinner)
//// - Selection of top-scoring recipes
//// - Recipe pool validation

import gleam/float
import gleam/list
import meal_planner/automation/plan_generator/types.{
  type GenerationError, type RecipePool, type ScoredRecipe, InsufficientRecipes,
  RecipePool,
}

/// Minimum recipes required for each meal type
pub const min_breakfasts: Int = 7

pub const min_lunches: Int = 2

pub const min_dinners: Int = 2

/// Categorize scored recipes by meal type
///
/// Uses simple category-based heuristic:
/// - "Breakfast" category → breakfasts
/// - All other categories split between lunch and dinner
pub fn categorize_recipes(scored: List(ScoredRecipe)) -> RecipePool {
  let breakfasts =
    scored
    |> list.filter(fn(sr) {
      sr.recipe.category == "Breakfast" || sr.recipe.category == "breakfast"
    })

  let non_breakfasts =
    scored
    |> list.filter(fn(sr) {
      sr.recipe.category != "Breakfast" && sr.recipe.category != "breakfast"
    })

  // Split non-breakfasts into lunch and dinner (50/50 for now)
  let half = list.length(non_breakfasts) / 2
  let lunches = list.take(non_breakfasts, half)
  let dinners = list.drop(non_breakfasts, half)

  RecipePool(breakfasts: breakfasts, lunches: lunches, dinners: dinners)
}

/// Select top N recipes by score
pub fn select_top_recipes(
  recipes: List(ScoredRecipe),
  count: Int,
) -> List(ScoredRecipe) {
  recipes
  |> list.sort(fn(a, b) { float.compare(b.score, a.score) })
  |> list.take(count)
}

/// Validate recipe pool has sufficient recipes
pub fn validate_pool(pool: RecipePool) -> Result(Nil, GenerationError) {
  let breakfast_count = list.length(pool.breakfasts)
  let lunch_count = list.length(pool.lunches)
  let dinner_count = list.length(pool.dinners)

  case breakfast_count < min_breakfasts {
    True ->
      Error(InsufficientRecipes(
        category: "breakfasts",
        required: min_breakfasts,
        available: breakfast_count,
      ))
    False ->
      case lunch_count < min_lunches {
        True ->
          Error(InsufficientRecipes(
            category: "lunches",
            required: min_lunches,
            available: lunch_count,
          ))
        False ->
          case dinner_count < min_dinners {
            True ->
              Error(InsufficientRecipes(
                category: "dinners",
                required: min_dinners,
                available: dinner_count,
              ))
            False -> Ok(Nil)
          }
      }
  }
}
