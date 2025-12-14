/// Shopping list entry encoder for Tandoor SDK
///
/// This module provides JSON encoders for ShoppingListEntry types for the Tandoor API.
/// It follows the gleam/json encoding pattern for type-safe JSON serialization.
///
/// The encoders handle:
/// - Required fields (always encoded)
/// - Optional fields (encoded as null or omitted based on API requirements)
/// - Clean, minimal JSON output matching Tandoor API expectations
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import meal_planner/tandoor/core/ids.{
  type FoodId, type IngredientId, type ShoppingListId, type UnitId,
}
import meal_planner/tandoor/types/shopping/shopping_list_entry.{
  type ShoppingListEntryCreate, type ShoppingListEntryUpdate,
  ShoppingListEntryCreate, ShoppingListEntryUpdate,
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

/// Encode an optional string
fn encode_optional_string(opt: Option(String)) -> Json {
  case opt {
    Some(value) -> json.string(value)
    None -> json.null()
  }
}

// ============================================================================
// Shopping List Entry Create Encoder
// ============================================================================

/// Encode a ShoppingListEntryCreate to JSON
///
/// This encoder creates JSON for shopping list entry creation requests.
/// It handles all optional and required fields according to the Tandoor API.
///
/// # Example
/// ```gleam
/// let entry = ShoppingListEntryCreate(
///   list_recipe: Some(shopping_list_id(1)),
///   food: Some(food_id(42)),
///   unit: None,
///   amount: 2.5,
///   order: 0,
///   checked: False,
///   ingredient: None,
///   completed_at: None,
///   delay_until: None,
///   mealplan_id: Some(10),
/// )
/// let encoded = encode_shopping_list_entry_create(entry)
/// ```
///
/// # Arguments
/// * `entry` - The shopping list entry create request to encode
///
/// # Returns
/// JSON representation of the shopping list entry create request
pub fn encode_shopping_list_entry_create(
  entry: ShoppingListEntryCreate,
) -> Json {
  json.object([
    #("list_recipe", encode_optional_int(entry.list_recipe, ids.shopping_list_id_to_int)),
    #("food", encode_optional_int(entry.food, ids.food_id_to_int)),
    #("unit", encode_optional_int(entry.unit, ids.unit_id_to_int)),
    #("amount", json.float(entry.amount)),
    #("order", json.int(entry.order)),
    #("checked", json.bool(entry.checked)),
    #("ingredient", encode_optional_int(entry.ingredient, ids.ingredient_id_to_int)),
    #("completed_at", encode_optional_string(entry.completed_at)),
    #("delay_until", encode_optional_string(entry.delay_until)),
    #("mealplan_id", case entry.mealplan_id {
      Some(id) -> json.int(id)
      None -> json.null()
    }),
  ])
}

// ============================================================================
// Shopping List Entry Update Encoder
// ============================================================================

/// Encode a ShoppingListEntryUpdate to JSON
///
/// This encoder creates JSON for shopping list entry update requests.
/// It handles all optional and required fields according to the Tandoor API.
///
/// # Example
/// ```gleam
/// let update = ShoppingListEntryUpdate(
///   list_recipe: Some(shopping_list_id(1)),
///   food: Some(food_id(42)),
///   unit: None,
///   amount: 3.0,
///   order: 1,
///   checked: True,
///   ingredient: None,
///   completed_at: Some("2025-12-14T14:00:00Z"),
///   delay_until: None,
/// )
/// let encoded = encode_shopping_list_entry_update(update)
/// ```
///
/// # Arguments
/// * `update` - The shopping list entry update request to encode
///
/// # Returns
/// JSON representation of the shopping list entry update request
pub fn encode_shopping_list_entry_update(
  update: ShoppingListEntryUpdate,
) -> Json {
  json.object([
    #("list_recipe", encode_optional_int(update.list_recipe, ids.shopping_list_id_to_int)),
    #("food", encode_optional_int(update.food, ids.food_id_to_int)),
    #("unit", encode_optional_int(update.unit, ids.unit_id_to_int)),
    #("amount", json.float(update.amount)),
    #("order", json.int(update.order)),
    #("checked", json.bool(update.checked)),
    #("ingredient", encode_optional_int(update.ingredient, ids.ingredient_id_to_int)),
    #("completed_at", encode_optional_string(update.completed_at)),
    #("delay_until", encode_optional_string(update.delay_until)),
  ])
}
