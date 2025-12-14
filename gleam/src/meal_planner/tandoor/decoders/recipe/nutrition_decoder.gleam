/// NutritionInfo decoder for Tandoor SDK
///
/// This module provides JSON decoders for the NutritionInfo type,
/// which includes detailed nutrition information with source tracking.
///
/// The decoder handles all optional Float fields and the source string,
/// making it resilient to partial nutrition data from various sources.
import gleam/dynamic/decode
import meal_planner/tandoor/types/recipe/nutrition.{
  type NutritionInfo, NutritionInfo,
}

// ============================================================================
// NutritionInfo Decoder
// ============================================================================

/// Decode NutritionInfo from JSON
///
/// This decoder handles nutrition information with optional fields
/// for all macronutrients. It's designed to work with partial data
/// where some nutritional values may be missing.
///
/// Example JSON structure:
/// ```json
/// {
///   "id": 1,
///   "carbohydrates": 45.0,
///   "fats": 12.0,
///   "proteins": 25.0,
///   "calories": 380.0,
///   "source": "USDA"
/// }
/// ```
///
/// All nutritional fields (carbohydrates, fats, proteins, calories, source)
/// are optional and will be decoded as Option(Float) or Option(String).
pub fn nutrition_info_decoder() -> decode.Decoder(NutritionInfo) {
  use id <- decode.field("id", decode.int)
  use carbohydrates <- decode.field(
    "carbohydrates",
    decode.optional(decode.float),
  )
  use fats <- decode.field("fats", decode.optional(decode.float))
  use proteins <- decode.field("proteins", decode.optional(decode.float))
  use calories <- decode.field("calories", decode.optional(decode.float))
  use source <- decode.field("source", decode.optional(decode.string))

  decode.success(NutritionInfo(
    id: id,
    carbohydrates: carbohydrates,
    fats: fats,
    proteins: proteins,
    calories: calories,
    source: source,
  ))
}
