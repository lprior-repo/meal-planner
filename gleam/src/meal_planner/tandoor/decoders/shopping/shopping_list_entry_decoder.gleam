/// Shopping List Entry decoder for Tandoor SDK
///
/// Provides JSON decoders for ShoppingListEntry types from the Tandoor API.
/// The API returns nested Food and Unit objects, not just IDs.
///
/// Example API response:
/// ```json
/// {
///   "id": 1,
///   "list_recipe": 5,
///   "food": { "id": 10, "name": "Tomato", ... },
///   "unit": { "id": 2, "name": "piece", ... },
///   "amount": 3.0,
///   "order": 0,
///   "checked": false,
///   "created_at": "2025-12-14T12:00:00Z",
///   "completed_at": null
/// }
/// ```
import gleam/dynamic/decode
import gleam/option.{type Option}
import meal_planner/tandoor/decoders/food/food_decoder
import meal_planner/tandoor/decoders/unit/unit_decoder
import meal_planner/tandoor/types/food/food.{type Food}
import meal_planner/tandoor/types/unit/unit.{type Unit}

/// Shopping list entry from API response
/// Contains nested Food and Unit objects instead of IDs
pub type ShoppingListEntryResponse {
  ShoppingListEntryResponse(
    /// Entry ID
    id: Int,
    /// Associated shopping list recipe ID (optional)
    list_recipe: Option(Int),
    /// Food item (nested object, optional)
    food: Option(Food),
    /// Unit of measurement (nested object, optional)
    unit: Option(Unit),
    /// Amount/quantity
    amount: Float,
    /// Display order in the list
    order: Int,
    /// Whether this item has been checked off
    checked: Bool,
    /// Creation timestamp (ISO 8601)
    created_at: String,
    /// When the item was checked/completed (optional)
    completed_at: Option(String),
  )
}

/// Decode a single shopping list entry from JSON
///
/// Handles the nested Food and Unit objects returned by the API.
pub fn decode_entry() -> decode.Decoder(ShoppingListEntryResponse) {
  use id <- decode.field("id", decode.int)
  use list_recipe <- decode.field("list_recipe", decode.optional(decode.int))
  use food <- decode.field("food", decode.optional(food_decoder.food_decoder()))
  use unit <- decode.field("unit", decode.optional(unit_decoder.decode_unit()))
  use amount <- decode.field("amount", decode.float)
  use order <- decode.field("order", decode.int)
  use checked <- decode.field("checked", decode.bool)
  use created_at <- decode.field("created_at", decode.string)
  use completed_at <- decode.field(
    "completed_at",
    decode.optional(decode.string),
  )

  decode.success(ShoppingListEntryResponse(
    id: id,
    list_recipe: list_recipe,
    food: food,
    unit: unit,
    amount: amount,
    order: order,
    checked: checked,
    created_at: created_at,
    completed_at: completed_at,
  ))
}

/// Decode a list of shopping list entries from JSON
///
/// Used for paginated API responses that return multiple entries.
///
/// Example JSON:
/// ```json
/// {
///   "results": [
///     { "id": 1, "food": {...}, ... },
///     { "id": 2, "food": {...}, ... }
///   ]
/// }
/// ```
pub fn decode_entry_list() -> decode.Decoder(List(ShoppingListEntryResponse)) {
  use results <- decode.field("results", decode.list(decode_entry()))
  decode.success(results)
}
