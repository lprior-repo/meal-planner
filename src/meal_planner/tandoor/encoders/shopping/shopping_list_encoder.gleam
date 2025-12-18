/// Shopping List encoder for Tandoor SDK
///
/// This module provides JSON encoders for shopping list and entry create/update requests.
/// It follows the gleam/json encoding pattern for type-safe JSON serialization.
///
/// The encoders handle:
/// - Shopping list create/update requests
/// - Shopping list entry create/update requests
/// - Required fields (amount, order, checked)
/// - Optional fields (food, unit, list_recipe, ingredient, etc.)
/// - Clean, minimal JSON output matching Tandoor API expectations
///
/// TDD Implementation: GREEN phase - making tests pass
import gleam/json.{type Json}
import gleam/option.{type Option}
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/shopping/shopping_list.{
  type ShoppingListCreate, type ShoppingListUpdate, ShoppingListCreate,
  ShoppingListUpdate,
}
import meal_planner/tandoor/types/shopping/shopping_list_entry.{
  type ShoppingListEntryCreate, type ShoppingListEntryUpdate,
  ShoppingListEntryCreate, ShoppingListEntryUpdate,
}

// ============================================================================
// Shopping List Create/Update Encoders
// ============================================================================

/// Encode a ShoppingListCreate request to JSON
///
/// This encoder creates JSON for shopping list creation requests.
/// Only the optional name field is included.
///
/// # Example
/// ```gleam
/// let list = ShoppingListCreate(name: Some("Weekly Groceries"))
/// let encoded = encode_list_create(list)
/// // JSON: {"name": "Weekly Groceries"}
/// ```
///
/// # Arguments
/// * `list` - The shopping list create request to encode
///
/// # Returns
/// JSON representation of the list create request
pub fn encode_list_create(list: ShoppingListCreate) -> Json {
  let ShoppingListCreate(name) = list

  json.object([#("name", encode_optional_string(name))])
}

/// Encode a ShoppingListUpdate request to JSON
///
/// This encoder creates JSON for shopping list update requests.
/// Only the optional name field is included.
///
/// # Example
/// ```gleam
/// let update = ShoppingListUpdate(name: Some("Monthly Groceries"))
/// let encoded = encode_list_update(update)
/// // JSON: {"name": "Monthly Groceries"}
/// ```
///
/// # Arguments
/// * `list` - The shopping list update request to encode
///
/// # Returns
/// JSON representation of the list update request
pub fn encode_list_update(list: ShoppingListUpdate) -> Json {
  let ShoppingListUpdate(name) = list

  json.object([#("name", encode_optional_string(name))])
}

// ============================================================================
// Shopping List Entry Create Encoder
// ============================================================================

/// Encode a ShoppingListEntryCreate request to JSON
///
/// This encoder creates JSON for shopping list entry creation requests.
/// It includes required fields (amount, order, checked) and optional fields
/// (food, unit, list_recipe, ingredient, completed_at, delay_until, mealplan_id).
///
/// # Example
/// ```gleam
/// let entry = ShoppingListEntryCreate(
///   list_recipe: None,
///   food: Some(food_id(42)),
///   unit: Some(unit_id(1)),
///   amount: 2.5,
///   order: 0,
///   checked: False,
///   ingredient: None,
///   completed_at: None,
///   delay_until: None,
///   mealplan_id: None,
/// )
/// let encoded = encode_entry_create(entry)
/// // JSON: {"food": 42, "unit": 1, "amount": 2.5, "order": 0, "checked": false}
/// ```
///
/// # Arguments
/// * `entry` - The shopping list entry create request to encode
///
/// # Returns
/// JSON representation of the entry create request
pub fn encode_entry_create(entry: ShoppingListEntryCreate) -> Json {
  let ShoppingListEntryCreate(
    list_recipe,
    food,
    unit,
    amount,
    order,
    checked,
    ingredient,
    completed_at,
    delay_until,
    mealplan_id,
  ) = entry

  json.object([
    #("list_recipe", encode_optional_shopping_list_id(list_recipe)),
    #("food", encode_optional_food_id(food)),
    #("unit", encode_optional_unit_id(unit)),
    #("amount", json.float(amount)),
    #("order", json.int(order)),
    #("checked", json.bool(checked)),
    #("ingredient", encode_optional_ingredient_id(ingredient)),
    #("completed_at", encode_optional_string(completed_at)),
    #("delay_until", encode_optional_string(delay_until)),
    #("mealplan_id", encode_optional_int(mealplan_id)),
  ])
}

// ============================================================================
// Shopping List Entry Update Encoder
// ============================================================================

/// Encode a ShoppingListEntryUpdate request to JSON
///
/// This encoder creates JSON for shopping list entry update requests.
/// It includes the same fields as the create request except for mealplan_id.
///
/// # Example
/// ```gleam
/// let update = ShoppingListEntryUpdate(
///   list_recipe: None,
///   food: Some(food_id(42)),
///   unit: Some(unit_id(1)),
///   amount: 3.0,
///   order: 1,
///   checked: True,
///   ingredient: None,
///   completed_at: Some("2025-12-14T10:30:00Z"),
///   delay_until: None,
/// )
/// let encoded = encode_entry_update(update)
/// ```
///
/// # Arguments
/// * `entry` - The shopping list entry update request to encode
///
/// # Returns
/// JSON representation of the entry update request
pub fn encode_entry_update(entry: ShoppingListEntryUpdate) -> Json {
  let ShoppingListEntryUpdate(
    list_recipe,
    food,
    unit,
    amount,
    order,
    checked,
    ingredient,
    completed_at,
    delay_until,
  ) = entry

  json.object([
    #("list_recipe", encode_optional_shopping_list_id(list_recipe)),
    #("food", encode_optional_food_id(food)),
    #("unit", encode_optional_unit_id(unit)),
    #("amount", json.float(amount)),
    #("order", json.int(order)),
    #("checked", json.bool(checked)),
    #("ingredient", encode_optional_ingredient_id(ingredient)),
    #("completed_at", encode_optional_string(completed_at)),
    #("delay_until", encode_optional_string(delay_until)),
  ])
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Encode optional ShoppingListId
fn encode_optional_shopping_list_id(id: Option(ids.ShoppingListId)) -> Json {
  case id {
    option.Some(id) -> json.int(ids.shopping_list_id_to_int(id))
    option.None -> json.null()
  }
}

/// Encode optional Food Int ID
fn encode_optional_food_id(id: Option(Int)) -> Json {
  case id {
    option.Some(i) -> json.int(i)
    option.None -> json.null()
  }
}

/// Encode optional Unit Int ID
fn encode_optional_unit_id(id: Option(Int)) -> Json {
  case id {
    option.Some(i) -> json.int(i)
    option.None -> json.null()
  }
}

/// Encode optional IngredientId
fn encode_optional_ingredient_id(id: Option(ids.IngredientId)) -> Json {
  case id {
    option.Some(id) -> json.int(ids.ingredient_id_to_int(id))
    option.None -> json.null()
  }
}

/// Encode optional String
fn encode_optional_string(value: Option(String)) -> Json {
  case value {
    option.Some(s) -> json.string(s)
    option.None -> json.null()
  }
}

/// Encode optional Int
fn encode_optional_int(value: Option(Int)) -> Json {
  case value {
    option.Some(i) -> json.int(i)
    option.None -> json.null()
  }
}
