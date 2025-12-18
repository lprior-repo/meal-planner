/// Cuisine decoder for Tandoor SDK
///
/// This module provides JSON decoders for Cuisine types from the Tandoor API.
/// It follows the gleam/dynamic decode pattern for type-safe JSON parsing.
///
/// The decoder handles:
/// - Required fields (id, name, num_recipes, timestamps)
/// - Optional fields (description, icon, parent)
/// - Hierarchical structure (parent for nested cuisines)
import gleam/dynamic/decode
import gleam/option
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/cuisine/cuisine.{type Cuisine, Cuisine}

/// Decode a Cuisine from JSON
///
/// This decoder handles all fields of a cuisine including optional description, icon, and parent.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "Italian",
///   "description": "Traditional Italian cuisine",
///   "icon": "🇮🇹",
///   "parent": null,
///   "num_recipes": 42,
///   "created_at": "2024-01-01T00:00:00Z",
///   "updated_at": "2024-01-01T00:00:00Z"
/// }
/// ```
pub fn cuisine_decoder() -> decode.Decoder(Cuisine) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field(
    "description",
    option.None,
    decode.optional(decode.string),
  )
  use icon <- decode.optional_field(
    "icon",
    option.None,
    decode.optional(decode.string),
  )
  use parent <- decode.field("parent", decode.optional(decode.int))
  use num_recipes <- decode.field("num_recipes", decode.int)
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)

  decode.success(Cuisine(
    id: ids.cuisine_id_from_int(id),
    name: name,
    description: description,
    icon: icon,
    parent: option.map(parent, ids.cuisine_id_from_int),
    num_recipes: num_recipes,
    created_at: created_at,
    updated_at: updated_at,
  ))
}
