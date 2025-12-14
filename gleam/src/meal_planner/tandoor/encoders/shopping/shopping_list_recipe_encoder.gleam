/// Shopping list recipe encoder for Tandoor SDK
///
/// This module provides JSON encoders for ShoppingListRecipe types for the Tandoor API.
/// It follows the gleam/json encoding pattern for type-safe JSON serialization.
///
/// The encoders handle:
/// - Required fields (always encoded)
/// - Optional fields (encoded as null or omitted based on API requirements)
/// - Clean, minimal JSON output matching Tandoor API expectations
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import meal_planner/tandoor/core/ids.{
  type MealPlanId, type RecipeId,
}
import meal_planner/tandoor/types/shopping/shopping_list_recipe.{
  type ShoppingListRecipeCreate, type ShoppingListRecipeUpdate,
  ShoppingListRecipeCreate, ShoppingListRecipeUpdate,
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Encode an optional integer ID
fn encode_optional_int(opt: Option(a), to_int: fn(a) -> Int) -> Json {
  case opt {
    Some(value) -> json.int(to_int(value))
    None -> json.null()
  }
}

// ============================================================================
// Shopping List Recipe Create Encoder
// ============================================================================

/// Encode a ShoppingListRecipeCreate to JSON
///
/// This encoder creates JSON for shopping list recipe creation requests.
/// It handles all optional and required fields according to the Tandoor API.
///
/// # Example
/// ```gleam
/// let list = ShoppingListRecipeCreate(
///   name: "Weekly Meal Prep",
///   recipe: Some(recipe_id(100)),
///   mealplan: None,
///   servings: 4.0,
/// )
/// let encoded = encode_shopping_list_recipe_create(list)
/// ```
///
/// # Arguments
/// * `list` - The shopping list recipe create request to encode
///
/// # Returns
/// JSON representation of the shopping list recipe create request
pub fn encode_shopping_list_recipe_create(
  list: ShoppingListRecipeCreate,
) -> Json {
  json.object([
    #("name", json.string(list.name)),
    #("recipe", encode_optional_int(list.recipe, ids.recipe_id_to_int)),
    #("mealplan", encode_optional_int(list.mealplan, ids.meal_plan_id_to_int)),
    #("servings", json.float(list.servings)),
  ])
}

// ============================================================================
// Shopping List Recipe Update Encoder
// ============================================================================

/// Encode a ShoppingListRecipeUpdate to JSON
///
/// This encoder creates JSON for shopping list recipe update requests.
/// It handles all optional and required fields according to the Tandoor API.
///
/// # Example
/// ```gleam
/// let update = ShoppingListRecipeUpdate(
///   name: "Updated Meal Prep",
///   recipe: Some(recipe_id(100)),
///   mealplan: Some(meal_plan_id(5)),
///   servings: 6.0,
/// )
/// let encoded = encode_shopping_list_recipe_update(update)
/// ```
///
/// # Arguments
/// * `update` - The shopping list recipe update request to encode
///
/// # Returns
/// JSON representation of the shopping list recipe update request
pub fn encode_shopping_list_recipe_update(
  update: ShoppingListRecipeUpdate,
) -> Json {
  json.object([
    #("name", json.string(update.name)),
    #("recipe", encode_optional_int(update.recipe, ids.recipe_id_to_int)),
    #("mealplan", encode_optional_int(update.mealplan, ids.meal_plan_id_to_int)),
    #("servings", json.float(update.servings)),
  ])
}
