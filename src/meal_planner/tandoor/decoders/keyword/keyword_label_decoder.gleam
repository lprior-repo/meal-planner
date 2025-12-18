/// KeywordLabel decoder for Tandoor SDK
///
/// This module provides JSON decoders for KeywordLabel type used in list responses.
import gleam/dynamic/decode
import meal_planner/tandoor/types/keyword/keyword_label.{
  type KeywordLabel, KeywordLabel,
}

/// Decode a KeywordLabel from JSON
///
/// This decoder handles the lightweight keyword label used in list/overview responses.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "vegetarian",
///   "label": "Vegetarian"
/// }
/// ```
pub fn keyword_label_decoder() -> decode.Decoder(KeywordLabel) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use label <- decode.field("label", decode.string)

  decode.success(KeywordLabel(id: id, name: name, label: label))
}
