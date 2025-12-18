/// Ingredient decoder for Tandoor SDK
///
/// This module provides JSON decoders for Ingredient types from the Tandoor API.
/// It follows the gleam/dynamic decode pattern for type-safe JSON parsing.
///
/// The decoders handle:
/// - Required fields (will fail if missing)
/// - Optional fields (use decode.optional for nullable values)
/// - Nested objects (food and unit references)
import gleam/dynamic
import gleam/dynamic/decode
import meal_planner/tandoor/decoders/food/food_decoder
import meal_planner/tandoor/decoders/unit/unit_decoder
import meal_planner/tandoor/types/recipe/ingredient.{type Ingredient, Ingredient}

// ============================================================================
// Ingredient Decoders
// ============================================================================

/// Ingredient decoder - returns a Decoder for use with decode.field, decode.optional, etc.
///
/// This is the core decoder that can be composed with other decoders.
pub fn ingredient_decoder() -> decode.Decoder(Ingredient) {
  use id <- decode.field("id", decode.int)
  use food <- decode.field("food", decode.optional(food_decoder.food_decoder()))
  use unit <- decode.field("unit", decode.optional(unit_decoder.decode_unit()))
  use amount <- decode.field("amount", decode.float)
  use note <- decode.field("note", decode.optional(decode.string))
  use order <- decode.field("order", decode.int)
  use is_header <- decode.field("is_header", decode.bool)
  use no_amount <- decode.field("no_amount", decode.bool)
  use original_text <- decode.field(
    "original_text",
    decode.optional(decode.string),
  )

  decode.success(Ingredient(
    id: id,
    food: food,
    unit: unit,
    amount: amount,
    note: note,
    order: order,
    is_header: is_header,
    no_amount: no_amount,
    original_text: original_text,
  ))
}

/// Decode an Ingredient from JSON - convenience wrapper
///
/// This decoder handles all fields of an ingredient including the optional
/// food and unit references.
///
/// This function is a convenience wrapper around ingredient_decoder()
/// for direct use with JSON data.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "food": {"id": 5, "name": "Tomato", ...},
///   "unit": {"id": 2, "name": "gram", ...},
///   "amount": 250.0,
///   "note": "diced",
///   "order": 1,
///   "is_header": false,
///   "no_amount": false,
///   "original_text": "250g tomatoes, diced"
/// }
/// ```
pub fn decode_ingredient(
  json: dynamic.Dynamic,
) -> Result(Ingredient, List(decode.DecodeError)) {
  decode.run(json, ingredient_decoder())
}
