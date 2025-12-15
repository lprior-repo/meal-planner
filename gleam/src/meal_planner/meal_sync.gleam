/// Meal plan synchronization between Tandoor and FatSecret
///
/// This module orchestrates:
/// 1. Fetching recipes from Tandoor
/// 2. Aggregating nutrition information
/// 3. Syncing meals to FatSecret diary
/// 4. Generating grocery lists
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string
import meal_planner/grocery_list.{type GroceryList}
import meal_planner/tandoor/client.{
  type ClientConfig, type RecipeDetail, get_recipe_detail,
}

// ============================================================================
// Types
// ============================================================================

/// A meal selection for planning
pub type MealSelection {
  MealSelection(
    date: String,
    meal_type: String,
    // Using String to avoid import conflicts
    recipe_id: Int,
    servings: Float,
  )
}

/// Aggregated nutrition for a meal
pub type MealNutrition {
  MealNutrition(
    recipe_id: Int,
    recipe_name: String,
    servings: Float,
    calories: Float,
    protein_g: Float,
    fat_g: Float,
    carbs_g: Float,
  )
}

/// Result of syncing a meal to FatSecret
pub type MealSyncResult {
  MealSyncResult(
    meal_selection: MealSelection,
    nutrition: MealNutrition,
    sync_status: SyncStatus,
  )
}

pub type SyncStatus {
  Success(message: String)
  Failed(error: String)
}

// ============================================================================
// Meal Processing
// ============================================================================

/// Fetch recipe details and extract nutrition
pub fn get_meal_nutrition(
  tandoor_config: ClientConfig,
  meal: MealSelection,
) -> Result(MealNutrition, String) {
  use recipe <- result.try(
    get_recipe_detail(tandoor_config, meal.recipe_id)
    |> result.map_error(fn(_e) { "Failed to fetch recipe from Tandoor" }),
  )

  // Extract nutrition from recipe
  let #(calories, protein_g, fat_g, carbs_g) = case recipe.nutrition {
    Some(nutrition) -> {
      // Access nutrition fields - adjust based on actual structure
      #(
        nutrition.calories,
        nutrition.proteins,
        nutrition.fats,
        nutrition.carbohydrates,
      )
    }
    _ -> #(0.0, 0.0, 0.0, 0.0)
  }

  // Scale nutrition by servings
  let serving_scale = meal.servings /. int.to_float(recipe.servings)

  Ok(MealNutrition(
    recipe_id: recipe.id,
    recipe_name: recipe.name,
    servings: meal.servings,
    calories: calories *. serving_scale,
    protein_g: protein_g *. serving_scale,
    fat_g: fat_g *. serving_scale,
    carbs_g: carbs_g *. serving_scale,
  ))
}

/// Generate a grocery list for selected meals
pub fn get_grocery_list_for_meals(
  tandoor_config: ClientConfig,
  meals: List(MealSelection),
) -> Result(GroceryList, String) {
  // Fetch all recipes
  use recipes <- result.try(
    meals
    |> list.map(fn(meal) {
      get_recipe_detail(tandoor_config, meal.recipe_id)
      |> result.map_error(fn(_e) { "Failed to fetch recipe" })
    })
    |> result.all,
  )

  // Collect all ingredients
  let all_ingredients =
    recipes
    |> list.flat_map(fn(recipe) { recipe.steps })
    |> list.flat_map(fn(step) { step.ingredients })

  // Generate grocery list
  Ok(grocery_list.from_ingredients(all_ingredients))
}

// ============================================================================
// Batch Operations
// ============================================================================

/// Sync multiple meals (placeholder)
pub fn sync_meals(
  _tandoor_config: ClientConfig,
  _fatsecret_token: String,
  meals: List(MealSelection),
) -> List(MealSyncResult) {
  // Placeholder for full FatSecret integration
  meals
  |> list.map(fn(meal) {
    let nutrition =
      MealNutrition(
        recipe_id: meal.recipe_id,
        recipe_name: "Unknown",
        servings: meal.servings,
        calories: 0.0,
        protein_g: 0.0,
        fat_g: 0.0,
        carbs_g: 0.0,
      )
    MealSyncResult(
      meal_selection: meal,
      nutrition: nutrition,
      sync_status: Failed("FatSecret sync not yet implemented"),
    )
  })
}

// ============================================================================
// Reporting
// ============================================================================

/// Format sync results as readable report
pub fn format_sync_report(results: List(MealSyncResult)) -> String {
  let successes =
    results
    |> list.filter(fn(r) {
      case r.sync_status {
        Success(_) -> True
        Failed(_) -> False
      }
    })
    |> list.length

  let success_section =
    "✅ Synced "
    <> int.to_string(successes)
    <> "/"
    <> int.to_string(list.length(results))
    <> " meals\n"

  let details =
    results
    |> list.map(fn(r) {
      case r.sync_status {
        Success(msg) -> "  ✓ " <> msg
        Failed(error) -> "  ✗ " <> r.nutrition.recipe_name <> ": " <> error
      }
    })
    |> string.join("\n")

  success_section <> details
}
