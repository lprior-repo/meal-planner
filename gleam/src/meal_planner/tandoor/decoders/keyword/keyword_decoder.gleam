/// Keyword decoder for Tandoor SDK
///
/// This module provides JSON decoders for Keyword types from the Tandoor API.
/// It follows the gleam/dynamic decode pattern for type-safe JSON parsing.
///
/// The decoder handles:
/// - Required fields (id, name, label, etc.)
/// - Optional fields (icon, parent)
/// - Tree structure fields (parent, numchild, full_name)
import gleam/dynamic/decode
import gleam/option.{None}
import meal_planner/tandoor/types/keyword/keyword.{type Keyword, Keyword}

/// Decode a Keyword from JSON
///
/// This decoder handles all fields of a keyword including optional icon and parent.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "vegetarian",
///   "label": "Vegetarian",
///   "description": "Vegetarian recipes",
///   "icon": "🥗",
///   "parent": null,
///   "numchild": 0,
///   "created_at": "2024-01-01T00:00:00Z",
///   "updated_at": "2024-01-01T00:00:00Z",
///   "full_name": "Vegetarian"
/// }
/// ```
pub fn keyword_decoder() -> decode.Decoder(Keyword) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use label <- decode.field("label", decode.string)
  use description <- decode.field("description", decode.string)
  use icon <- decode.optional_field(
    "icon",
    None,
    decode.optional(decode.string),
  )
  use parent <- decode.field("parent", decode.optional(decode.int))
  use numchild <- decode.field("numchild", decode.int)
  use created_at <- decode.field("created_at", decode.string)
  use updated_at <- decode.field("updated_at", decode.string)
  use full_name <- decode.field("full_name", decode.string)

  decode.success(Keyword(
    id: id,
    name: name,
    label: label,
    description: description,
    icon: icon,
    parent: parent,
    numchild: numchild,
    created_at: created_at,
    updated_at: updated_at,
    full_name: full_name,
  ))
}
