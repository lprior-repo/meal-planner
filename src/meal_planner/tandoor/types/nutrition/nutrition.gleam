/// Tandoor NutritionInfo Type Module
///
/// Provides the NutritionInfo type for recipe nutritional information.
///
/// Based on Tandoor API 2.3.6 specification.
import gleam/dynamic/decode
import gleam/int
import gleam/json.{type Json}
import gleam/option.{type Option}

// ============================================================================
// Types
// ============================================================================

/// Nutrition information per serving
///
/// Represents comprehensive nutrition data for a recipe,
/// including all macronutrients and the ability to track the data source.
///
/// All numeric fields are Float values to match the Tandoor API response format.
///
/// Fields:
/// - id: Unique identifier for this nutrition record
/// - carbohydrates: Total carbohydrates in grams
/// - fats: Total fats in grams
/// - proteins: Total proteins in grams
/// - calories: Total calories (kcal)
/// - source: Where this nutrition data came from (e.g., "USDA", "manual", "calculated")
pub type NutritionInfo {
  NutritionInfo(
    id: Int,
    carbohydrates: Float,
    fats: Float,
    proteins: Float,
    calories: Float,
    source: String,
  )
}

// ============================================================================
// Decoder
// ============================================================================

/// Decode NutritionInfo from JSON
///
/// This decoder handles nutrition information with all macronutrients.
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
pub fn nutrition_info_decoder() -> decode.Decoder(NutritionInfo) {
  use id <- decode.field("id", decode.int)
  use carbohydrates <- decode.optional_field("carbohydrates", 0.0, decode.float)
  use fats <- decode.optional_field("fats", 0.0, decode.float)
  use proteins <- decode.optional_field("proteins", 0.0, decode.float)
  use calories <- decode.optional_field("calories", 0.0, decode.float)
  use source <- decode.optional_field("source", "", decode.string)

  decode.success(NutritionInfo(
    id: id,
    carbohydrates: carbohydrates,
    fats: fats,
    proteins: proteins,
    calories: calories,
    source: source,
  ))
}

/// Decoder that accepts both int and float values, converting int to float
///
/// This is needed because the Tandoor API may return integers for some
/// nutritional values instead of floats.
fn decode_flexible_float() -> decode.Decoder(Float) {
  decode.one_of(decode.float, or: [
    decode.int |> decode.map(fn(n) { int.to_float(n) }),
  ])
}

/// Decode NutritionInfo from JSON with flexible float handling
///
/// Same as nutrition_info_decoder but uses decode_flexible_float() to handle
/// cases where Tandoor API returns integers instead of floats.
pub fn nutrition_info_flexible_decoder() -> decode.Decoder(NutritionInfo) {
  use id <- decode.field("id", decode.int)
  use carbohydrates <- decode.optional_field(
    "carbohydrates",
    0.0,
    decode_flexible_float(),
  )
  use fats <- decode.optional_field("fats", 0.0, decode_flexible_float())
  use proteins <- decode.optional_field(
    "proteins",
    0.0,
    decode_flexible_float(),
  )
  use calories <- decode.optional_field(
    "calories",
    0.0,
    decode_flexible_float(),
  )
  use source <- decode.optional_field("source", "", decode.string)

  decode.success(NutritionInfo(
    id: id,
    carbohydrates: carbohydrates,
    fats: fats,
    proteins: proteins,
    calories: calories,
    source: source,
  ))
}

// ============================================================================
// Encoder
// ============================================================================

/// Encode a NutritionInfo to JSON
///
/// This encoder creates complete JSON for NutritionInfo objects.
///
/// Example:
/// ```gleam
/// let nutrition = NutritionInfo(
///   id: 1,
///   carbohydrates: 45.0,
///   fats: 12.0,
///   proteins: 25.0,
///   calories: 380.0,
///   source: "USDA"
/// )
/// let encoded = encode_nutrition_info(nutrition)
/// json.to_string(encoded)
/// ```
pub fn encode_nutrition_info(nutrition: NutritionInfo) -> Json {
  json.object([
    #("id", json.int(nutrition.id)),
    #("carbohydrates", json.float(nutrition.carbohydrates)),
    #("fats", json.float(nutrition.fats)),
    #("proteins", json.float(nutrition.proteins)),
    #("calories", json.float(nutrition.calories)),
    #("source", json.string(nutrition.source)),
  ])
}
