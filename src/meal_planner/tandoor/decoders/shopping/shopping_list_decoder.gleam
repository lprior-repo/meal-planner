/// Shopping List decoder for Tandoor SDK
///
/// This module provides decoders for shopping list types.
import gleam/dynamic/decode.{type Decoder}
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/decoders/shopping/shopping_list_entry_decoder
import meal_planner/tandoor/types/shopping/shopping_list.{
  type ShoppingList, ShoppingList,
}

/// Decoder for shopping lists
///
/// This decoder handles the complete shopping list including all entries.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "Weekly Groceries",
///   "entries": [...],
///   "created_by": 1,
///   "created_at": "2024-01-01T00:00:00Z",
///   "updated_at": "2024-01-01T00:00:00Z"
/// }
/// ```
pub fn decoder() -> Decoder(ShoppingList) {
  use id <- decode.field("id", ids.shopping_list_id_decoder())
  use name <- decode.field("name", decode.optional(decode.string))
  use entries <- decode.field(
    "entries",
    decode.list(shopping_list_entry_decoder.decoder()),
  )
  use created_by <- decode.field("created_by", ids.user_id_decoder())
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)

  decode.success(ShoppingList(
    id: id,
    name: name,
    entries: entries,
    created_by: created_by,
    created_at: created_at,
    updated_at: updated_at,
  ))
}
