/// FatSecret Foods JSON decoders
///
/// This module provides type-safe decoders for FatSecret API responses.
///
/// FatSecret API quirks handled:
/// 1. Single vs array: Returns object for 1 result, array for multiple
/// 2. Numeric strings: Some numbers come as "95" instead of 95
/// 3. Missing optionals: Many nutrition fields may be absent
/// 4. Inconsistent null handling: Some fields are missing vs null
import gleam/dynamic
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/option.{type Option}
import meal_planner/fatsecret/foods/types.{
  type Food, type FoodSearchResponse, type FoodSearchResult, type Nutrition,
  type Serving, Food, FoodSearchResponse, FoodSearchResult, Nutrition, Serving,
}

// ============================================================================
// Helper Decoders for FatSecret Quirks
// ============================================================================

/// Decode a float that might be a string ("95.5") or number (95.5)
fn flexible_float() -> decode.Decoder(Float) {
  decode.one_of(
    decode.float,
    or: [
      {
        use s <- decode.then(decode.string)
        case float.parse(s) {
          Ok(f) -> decode.success(f)
          Error(_) -> decode.failure(0.0, "Float")
        }
      },
    ],
  )
}

/// Decode an optional float that might be a string, number, or missing
fn optional_flexible_float() -> decode.Decoder(Option(Float)) {
  decode.optional(flexible_float())
}

/// Decode an int that might be a string ("95") or number (95)
fn flexible_int() -> decode.Decoder(Int) {
  decode.one_of(
    decode.int,
    or: [
      {
        use s <- decode.then(decode.string)
        case int.parse(s) {
          Ok(i) -> decode.success(i)
          Error(_) -> decode.failure(0, "Int")
        }
      },
    ],
  )
}

// ============================================================================
// Nutrition Decoder
// ============================================================================

/// Decoder for Nutrition information
///
/// Handles FatSecret's inconsistent numeric formats and missing fields.
/// Required macros (calories, protein, fat, carbs) must be present.
/// Micronutrients are optional and may be missing or null.
pub fn nutrition_decoder() -> decode.Decoder(Nutrition) {
  use calories <- decode.field("calories", flexible_float())
  use carbohydrate <- decode.field("carbohydrate", flexible_float())
  use protein <- decode.field("protein", flexible_float())
  use fat <- decode.field("fat", flexible_float())
  use saturated_fat <- decode.field("saturated_fat", optional_flexible_float())
  use polyunsaturated_fat <- decode.field(
    "polyunsaturated_fat",
    optional_flexible_float(),
  )
  use monounsaturated_fat <- decode.field(
    "monounsaturated_fat",
    optional_flexible_float(),
  )
  use cholesterol <- decode.field("cholesterol", optional_flexible_float())
  use sodium <- decode.field("sodium", optional_flexible_float())
  use potassium <- decode.field("potassium", optional_flexible_float())
  use fiber <- decode.field("fiber", optional_flexible_float())
  use sugar <- decode.field("sugar", optional_flexible_float())
  use vitamin_a <- decode.field("vitamin_a", optional_flexible_float())
  use vitamin_c <- decode.field("vitamin_c", optional_flexible_float())
  use calcium <- decode.field("calcium", optional_flexible_float())
  use iron <- decode.field("iron", optional_flexible_float())

  decode.success(Nutrition(
    calories: calories,
    carbohydrate: carbohydrate,
    protein: protein,
    fat: fat,
    saturated_fat: saturated_fat,
    polyunsaturated_fat: polyunsaturated_fat,
    monounsaturated_fat: monounsaturated_fat,
    cholesterol: cholesterol,
    sodium: sodium,
    potassium: potassium,
    fiber: fiber,
    sugar: sugar,
    vitamin_a: vitamin_a,
    vitamin_c: vitamin_c,
    calcium: calcium,
    iron: iron,
  ))
}

/// Convenience wrapper to decode Nutrition from dynamic data
pub fn decode_nutrition(
  json: dynamic.Dynamic,
) -> Result(Nutrition, List(decode.DecodeError)) {
  decode.run(json, nutrition_decoder())
}

// ============================================================================
// Serving Decoder
// ============================================================================

/// Decoder for a single Serving
///
/// Handles metric serving info which may be missing for some serving types.
/// Includes complete nutrition information.
pub fn serving_decoder() -> decode.Decoder(Serving) {
  use serving_id_str <- decode.field("serving_id", decode.string)
  use serving_description <- decode.field("serving_description", decode.string)
  use serving_url <- decode.field("serving_url", decode.string)
  use metric_serving_amount <- decode.field(
    "metric_serving_amount",
    optional_flexible_float(),
  )
  use metric_serving_unit <- decode.field(
    "metric_serving_unit",
    decode.optional(decode.string),
  )
  use number_of_units <- decode.field("number_of_units", flexible_float())
  use measurement_description <- decode.field(
    "measurement_description",
    decode.string,
  )

  // Nutrition info is nested in the serving object
  use calories <- decode.field("calories", flexible_float())
  use carbohydrate <- decode.field("carbohydrate", flexible_float())
  use protein <- decode.field("protein", flexible_float())
  use fat <- decode.field("fat", flexible_float())
  use saturated_fat <- decode.field("saturated_fat", optional_flexible_float())
  use polyunsaturated_fat <- decode.field(
    "polyunsaturated_fat",
    optional_flexible_float(),
  )
  use monounsaturated_fat <- decode.field(
    "monounsaturated_fat",
    optional_flexible_float(),
  )
  use cholesterol <- decode.field("cholesterol", optional_flexible_float())
  use sodium <- decode.field("sodium", optional_flexible_float())
  use potassium <- decode.field("potassium", optional_flexible_float())
  use fiber <- decode.field("fiber", optional_flexible_float())
  use sugar <- decode.field("sugar", optional_flexible_float())
  use vitamin_a <- decode.field("vitamin_a", optional_flexible_float())
  use vitamin_c <- decode.field("vitamin_c", optional_flexible_float())
  use calcium <- decode.field("calcium", optional_flexible_float())
  use iron <- decode.field("iron", optional_flexible_float())

  let nutrition =
    Nutrition(
      calories: calories,
      carbohydrate: carbohydrate,
      protein: protein,
      fat: fat,
      saturated_fat: saturated_fat,
      polyunsaturated_fat: polyunsaturated_fat,
      monounsaturated_fat: monounsaturated_fat,
      cholesterol: cholesterol,
      sodium: sodium,
      potassium: potassium,
      fiber: fiber,
      sugar: sugar,
      vitamin_a: vitamin_a,
      vitamin_c: vitamin_c,
      calcium: calcium,
      iron: iron,
    )

  decode.success(Serving(
    serving_id: types.serving_id(serving_id_str),
    serving_description: serving_description,
    serving_url: serving_url,
    metric_serving_amount: metric_serving_amount,
    metric_serving_unit: metric_serving_unit,
    number_of_units: number_of_units,
    measurement_description: measurement_description,
    nutrition: nutrition,
  ))
}

/// Convenience wrapper to decode a Serving from dynamic data
pub fn decode_serving(
  json: dynamic.Dynamic,
) -> Result(Serving, List(decode.DecodeError)) {
  decode.run(json, serving_decoder())
}

/// Decode servings list handling single-vs-array quirk
///
/// FatSecret returns:
/// - `{"serving": {...}}` for 1 serving
/// - `{"serving": [{...}, {...}]}` for multiple servings
fn servings_list_decoder() -> decode.Decoder(List(Serving)) {
  decode.one_of(
    // Try array first
    decode.list(serving_decoder()),
    or: [
      // Fallback to single object wrapped in list
      {
        use single <- decode.then(serving_decoder())
        decode.success([single])
      },
    ],
  )
}

// ============================================================================
// Food Decoder
// ============================================================================

/// Decoder for complete Food details from food.get.v4
///
/// Handles the servings array/object quirk and optional brand_name.
pub fn food_decoder() -> decode.Decoder(Food) {
  use food_id_str <- decode.field("food_id", decode.string)
  use food_name <- decode.field("food_name", decode.string)
  use food_type <- decode.field("food_type", decode.string)
  use food_url <- decode.field("food_url", decode.string)
  use brand_name <- decode.field("brand_name", decode.optional(decode.string))
  use servings <- decode.field("servings", {
    use servings_obj <- decode.field("serving", servings_list_decoder())
    decode.success(servings_obj)
  })

  decode.success(Food(
    food_id: types.food_id(food_id_str),
    food_name: food_name,
    food_type: food_type,
    food_url: food_url,
    brand_name: brand_name,
    servings: servings,
  ))
}

/// Decode Food from food.get.v4 response
///
/// The response wraps the food in a "food" key:
/// `{"food": {...}}`
pub fn decode_food_response(
  json: dynamic.Dynamic,
) -> Result(Food, List(decode.DecodeError)) {
  decode.run(json, decode.at(["food"], food_decoder()))
}

// ============================================================================
// Search Result Decoders
// ============================================================================

/// Decoder for a single food search result
pub fn food_search_result_decoder() -> decode.Decoder(FoodSearchResult) {
  use food_id_str <- decode.field("food_id", decode.string)
  use food_name <- decode.field("food_name", decode.string)
  use food_type <- decode.field("food_type", decode.string)
  use food_description <- decode.field("food_description", decode.string)
  use brand_name <- decode.field("brand_name", decode.optional(decode.string))
  use food_url <- decode.field("food_url", decode.string)

  decode.success(FoodSearchResult(
    food_id: types.food_id(food_id_str),
    food_name: food_name,
    food_type: food_type,
    food_description: food_description,
    brand_name: brand_name,
    food_url: food_url,
  ))
}

/// Decode search results list handling single-vs-array quirk
///
/// FatSecret returns:
/// - `{"food": {...}}` for 1 result
/// - `{"food": [{...}, {...}]}` for multiple results
fn food_search_list_decoder() -> decode.Decoder(List(FoodSearchResult)) {
  decode.one_of(
    // Try array first
    decode.list(food_search_result_decoder()),
    or: [
      // Fallback to single object wrapped in list
      {
        use single <- decode.then(food_search_result_decoder())
        decode.success([single])
      },
    ],
  )
}

/// Decoder for foods.search response
///
/// Handles pagination metadata and the food array/object quirk.
pub fn food_search_response_decoder() -> decode.Decoder(FoodSearchResponse) {
  use foods <- decode.field("foods", {
    use food_list <- decode.field("food", food_search_list_decoder())
    use max_results <- decode.field("max_results", flexible_int())
    use total_results <- decode.field("total_results", flexible_int())
    use page_number <- decode.field("page_number", flexible_int())

    decode.success(FoodSearchResponse(
      foods: food_list,
      max_results: max_results,
      total_results: total_results,
      page_number: page_number,
    ))
  })

  decode.success(foods)
}

/// Decode FoodSearchResponse from foods.search API response
pub fn decode_food_search_response(
  json: dynamic.Dynamic,
) -> Result(FoodSearchResponse, List(decode.DecodeError)) {
  decode.run(json, food_search_response_decoder())
}
