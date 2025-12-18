/// Decoder for CreateRecipeRequest from JSON
///
/// This module provides a JSON decoder for recipe creation requests
/// following the gleam/dynamic/decode pattern.
import gleam/dynamic/decode
import gleam/option

/// Decode JSON to CreateRecipeRequest type
/// 
/// Expected JSON structure:
/// ```json
/// {
///   "name": "Recipe Name",
///   "description": "Optional description",
///   "servings": 4,
///   "servings_text": "4 people",
///   "working_time": 30,
///   "waiting_time": 60
/// }
/// ```
pub fn create_recipe_request_decoder() -> decode.Decoder(
  #(
    String,
    option.Option(String),
    Int,
    option.Option(String),
    option.Option(Int),
    option.Option(Int),
  ),
) {
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field(
    "description",
    option.None,
    decode.optional(decode.string),
  )
  use servings <- decode.field("servings", decode.int)
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
  decode.success(#(
    name,
    description,
    servings,
    servings_text,
    working_time,
    waiting_time,
  ))
}
