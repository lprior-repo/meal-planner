/// Decoder for IngredientCreateRequest from JSON
///
/// This module provides a JSON decoder for ingredient creation requests
/// following the gleam/dynamic/decode pattern.
import gleam/dynamic/decode
import gleam/option

/// Decode JSON to IngredientCreateRequest fields
/// 
/// Expected JSON structure:
/// ```json
/// {
///   "food": 123,
///   "unit": 45,
///   "amount": 250.0,
///   "note": "diced",
///   "order": 1,
///   "is_header": false,
///   "no_amount": false,
///   "original_text": "250g tomatoes, diced"
/// }
/// ```
pub fn ingredient_create_request_decoder() -> decode.Decoder(
  #(
    option.Option(Int),
    option.Option(Int),
    Float,
    option.Option(String),
    Int,
    Bool,
    Bool,
    option.Option(String),
  ),
) {
  use food <- decode.optional_field("food", option.None, decode.optional(decode.int))
  use unit <- decode.optional_field("unit", option.None, decode.optional(decode.int))
  use amount <- decode.field("amount", decode.float)
  use note <- decode.optional_field("note", option.None, decode.optional(decode.string))
  use order <- decode.field("order", decode.int)
  use is_header <- decode.field("is_header", decode.bool)
  use no_amount <- decode.field("no_amount", decode.bool)
  use original_text <- decode.optional_field(
    "original_text",
    option.None,
    decode.optional(decode.string),
  )
  decode.success(#(food, unit, amount, note, order, is_header, no_amount, original_text))
}
