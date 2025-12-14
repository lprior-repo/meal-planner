/// Food decoder for Tandoor SDK
///
/// This module provides JSON decoders for Food types from the Tandoor API.
/// It follows the gleam/dynamic decode pattern for type-safe JSON parsing.
///
/// The decoders handle:
/// - Required fields (will fail if missing)
/// - Optional fields (use decode.optional for nullable values)
/// - Nested objects (recipe as FoodSimple)
import gleam/dynamic/decode
import gleam/option.{type Option}
import meal_planner/tandoor/types/food/food.{type Food, Food}
import meal_planner/tandoor/types/food/food_simple.{type FoodSimple, FoodSimple}

// ============================================================================
// Food Decoder
// ============================================================================

/// Decode a complete Food from JSON
///
/// This decoder handles all fields of a food item including the optional
/// nested recipe reference.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "name": "Tomato",
///   "plural_name": "Tomatoes",
///   "description": "Fresh red tomatoes",
///   "recipe": null,
///   "food_onhand": true,
///   "supermarket_category": null,
///   "ignore_shopping": false
/// }
/// ```
pub fn decode_food(json: dynamic.Dynamic) -> Result(Food, decode.DecodeErrors) {
  let decoder = {
    use id <- decode.field("id", decode.int)
    use name <- decode.field("name", decode.string)
    use plural_name <- decode.field(
      "plural_name",
      decode.optional(decode.string),
    )
    use description <- decode.field("description", decode.string)
    use recipe <- decode.field("recipe", decode.optional(decode_food_simple))
    use food_onhand <- decode.field("food_onhand", decode.optional(decode.bool))
    use supermarket_category <- decode.field(
      "supermarket_category",
      decode.optional(decode.int),
    )
    use ignore_shopping <- decode.field("ignore_shopping", decode.bool)

    decode.success(Food(
      id: id,
      name: name,
      plural_name: plural_name,
      description: description,
      recipe: recipe,
      food_onhand: food_onhand,
      supermarket_category: supermarket_category,
      ignore_shopping: ignore_shopping,
    ))
  }

  decode.run(json, decoder)
}

// ============================================================================
// FoodSimple Decoder
// ============================================================================

/// Decode a FoodSimple from JSON
///
/// Minimal food reference with ID, name, and optional plural name.
/// Used when a food is embedded as a reference (e.g., in recipe field).
pub fn decode_food_simple(
  json: dynamic.Dynamic,
) -> Result(FoodSimple, decode.DecodeErrors) {
  let decoder = {
    use id <- decode.field("id", decode.int)
    use name <- decode.field("name", decode.string)
    use plural_name <- decode.field(
      "plural_name",
      decode.optional(decode.string),
    )

    decode.success(FoodSimple(id: id, name: name, plural_name: plural_name))
  }

  decode.run(json, decoder)
}
