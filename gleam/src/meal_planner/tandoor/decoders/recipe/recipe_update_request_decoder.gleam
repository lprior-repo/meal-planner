/// Decoder for RecipeUpdate from JSON
///
/// This module provides a JSON decoder for recipe update requests
/// following the gleam/dynamic/decode pattern.
import gleam/dynamic/decode
import gleam/option

/// Decode JSON to RecipeUpdate fields (all optional for PATCH)
/// 
/// Expected JSON structure (all fields optional):
/// ```json
/// {
///   "name": "Updated Name",
///   "description": "Updated description",
///   "servings": 6,
///   "servings_text": "6 people",
///   "working_time": 45,
///   "waiting_time": 90
/// }
/// ```
pub fn recipe_update_request_decoder() -> decode.Decoder(
  #(
    option.Option(String),
    option.Option(String),
    option.Option(Int),
    option.Option(String),
    option.Option(Int),
    option.Option(Int),
  ),
) {
  use name <- decode.optional_field("name", option.None, decode.optional(decode.string))
  use description <- decode.optional_field(
    "description",
    option.None,
    decode.optional(decode.string),
  )
  use servings <- decode.optional_field("servings", option.None, decode.optional(decode.int))
  use servings_text <- decode.optional_field(
    "servings_text",
    option.None,
    decode.optional(decode.string),
  )
  use working_time <- decode.optional_field(
    "working_time",
    option.None,
    decode.optional(decode.int),
  )
  use waiting_time <- decode.optional_field(
    "waiting_time",
    option.None,
    decode.optional(decode.int),
  )
  decode.success(#(name, description, servings, servings_text, working_time, waiting_time))
}
