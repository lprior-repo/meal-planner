/// Meal plan synchronization between Tandoor and FatSecret
///
/// This module orchestrates:
/// 1. Fetching recipes from Tandoor
/// 2. Aggregating nutrition information
/// 3. Syncing meals to FatSecret diary
/// 4. Generating grocery lists
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import meal_planner/fatsecret/core/config.{type FatSecretConfig}
import meal_planner/fatsecret/core/errors.{type FatSecretError}
import meal_planner/fatsecret/core/oauth.{type AccessToken}
import meal_planner/fatsecret/diary/client as diary_client
import meal_planner/fatsecret/diary/types.{
  type MealType, Breakfast, Custom, Dinner, Lunch, Snack, date_to_int,
  food_entry_id_to_string,
}
import meal_planner/grocery_list.{type GroceryList}
import meal_planner/tandoor/client.{type ClientConfig, get_recipe_detail}

// ============================================================================
// Types
// ============================================================================

/// A meal selection for planning
pub type MealSelection {
  MealSelection(
    date: String,
    meal_type: String,
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
    |> result.map_error(fn(_) { "Failed to fetch recipe from Tandoor" }),
  )

  let #(calories, protein_g, fat_g, carbs_g) = case recipe.nutrition {
    Some(nutrition) -> #(
      nutrition.calories,
      nutrition.proteins,
      nutrition.fats,
      nutrition.carbohydrates,
    )
    None -> #(0.0, 0.0, 0.0, 0.0)
  }

  let serving_scale = meal.servings /. int.to_float(recipe.servings)

  MealNutrition(
    recipe_id: recipe.id,
    recipe_name: recipe.name,
    servings: meal.servings,
    calories: calories *. serving_scale,
    protein_g: protein_g *. serving_scale,
    fat_g: fat_g *. serving_scale,
    carbs_g: carbs_g *. serving_scale,
  )
  |> Ok
}

/// Generate a grocery list for selected meals
pub fn get_grocery_list_for_meals(
  tandoor_config: ClientConfig,
  meals: List(MealSelection),
) -> Result(GroceryList, String) {
  use recipes <- result.try(
    meals
    |> list.map(fn(meal) {
      get_recipe_detail(tandoor_config, meal.recipe_id)
      |> result.map_error(fn(_) { "Failed to fetch recipe" })
    })
    |> result.all,
  )

  let all_ingredients =
    recipes
    |> list.flat_map(fn(recipe) { recipe.steps })
    |> list.flat_map(fn(step) { step.ingredients })

  grocery_list.from_ingredients(all_ingredients)
  |> Ok
}

// ============================================================================
// FatSecret Synchronization
// ============================================================================

/// Sync multiple meals to FatSecret diary
///
/// This function:
/// 1. Fetches recipe nutrition from Tandoor
/// 2. Converts each meal to a FatSecret diary entry
/// 3. Creates entries in user's FatSecret diary
/// 4. Returns sync results (success/failure for each meal)
pub fn sync_meals(
  tandoor_config: ClientConfig,
  fatsecret_config: FatSecretConfig,
  fatsecret_token: AccessToken,
  meals: List(MealSelection),
) -> List(MealSyncResult) {
  meals
  |> list.map(sync_single_meal(
    tandoor_config,
    fatsecret_config,
    fatsecret_token,
    _,
  ))
}

/// Sync a single meal to FatSecret
fn sync_single_meal(
  tandoor_config: ClientConfig,
  fatsecret_config: FatSecretConfig,
  fatsecret_token: AccessToken,
  meal: MealSelection,
) -> MealSyncResult {
  case get_meal_nutrition(tandoor_config, meal) {
    Error(err) ->
      MealSyncResult(
        meal_selection: meal,
        nutrition: MealNutrition(
          recipe_id: meal.recipe_id,
          recipe_name: "Unknown",
          servings: meal.servings,
          calories: 0.0,
          protein_g: 0.0,
          fat_g: 0.0,
          carbs_g: 0.0,
        ),
        sync_status: Failed(err),
      )

    Ok(nutrition) ->
      case date_to_int(meal.date) {
        Error(_) ->
          MealSyncResult(
            meal_selection: meal,
            nutrition: nutrition,
            sync_status: Failed("Invalid date format: " <> meal.date),
          )

        Ok(date_int) -> {
          let meal_type_enum = parse_meal_type(meal.meal_type)
          let entry_input =
            Custom(
              food_entry_name: nutrition.recipe_name,
              serving_description: format_servings(nutrition.servings),
              number_of_units: 1.0,
              meal: meal_type_enum,
              date_int: date_int,
              calories: nutrition.calories,
              carbohydrate: nutrition.carbs_g,
              protein: nutrition.protein_g,
              fat: nutrition.fat_g,
            )

          case
            diary_client.create_food_entry(
              fatsecret_config,
              fatsecret_token,
              entry_input,
            )
          {
            Error(err) ->
              MealSyncResult(
                meal_selection: meal,
                nutrition: nutrition,
                sync_status: Failed(format_api_error(err)),
              )

            Ok(entry_id) ->
              MealSyncResult(
                meal_selection: meal,
                nutrition: nutrition,
                sync_status: Success(
                  nutrition.recipe_name
                  <> " logged to FatSecret (ID: "
                  <> food_entry_id_to_string(entry_id)
                  <> ")",
                ),
              )
          }
        }
      }
  }
}

// ============================================================================
// Batch Operations
// ============================================================================

/// Generate a report of sync operations
pub fn format_sync_report(results: List(MealSyncResult)) -> String {
  let total = list.length(results)
  let successes =
    results
    |> list.filter(fn(r) {
      case r.sync_status {
        Success(_) -> True
        Failed(_) -> False
      }
    })
    |> list.length

  let header =
    "✅ Synced "
    <> int.to_string(successes)
    <> "/"
    <> int.to_string(total)
    <> " meals\n"

  let details =
    results
    |> list.map(format_sync_result)
    |> string.join("\n")

  header <> details
}

fn format_sync_result(result: MealSyncResult) -> String {
  case result.sync_status {
    Success(msg) -> "  ✓ " <> msg
    Failed(error) -> "  ✗ " <> result.nutrition.recipe_name <> ": " <> error
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Parse meal type string to MealType enum
fn parse_meal_type(meal_type_str: String) -> MealType {
  let normalized =
    meal_type_str
    |> string.lowercase
    |> string.trim

  case normalized {
    "breakfast" -> Breakfast
    "lunch" -> Lunch
    "dinner" -> Dinner
    "snack" -> Snack
    "other" -> Snack
    _ -> Lunch
  }
}

/// Format servings as human-readable string
fn format_servings(servings: Float) -> String {
  servings
  |> float_to_string
  |> fn(s) { s <> " servings" }
}

/// Convert FatSecret API error to human-readable message
fn format_api_error(err: FatSecretError) -> String {
  case err {
    _ -> "FatSecret API error: unable to create diary entry"
  }
}

/// Convert float to string with 1 decimal place
fn float_to_string(f: Float) -> String {
  let int_part = float_to_int(f)
  let frac = f -. int.to_float(int_part)
  let decimal_part = float_to_int(frac *. 10.0)

  int.to_string(int_part) <> "." <> int.to_string(abs_int(decimal_part))
}

/// Get absolute value of integer
fn abs_int(i: Int) -> Int {
  case i < 0 {
    True -> -i
    False -> i
  }
}

/// Convert float to int by truncation
@external(erlang, "erlang", "trunc")
fn float_to_int(f: Float) -> Int
