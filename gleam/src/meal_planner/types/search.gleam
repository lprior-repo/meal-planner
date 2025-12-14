/// Food search types and operations
///
/// Unified search results across USDA and custom foods.

import gleam/dynamic/decode.{type Decoder}
import gleam/json
import gleam/json.{type Json}
import gleam/option.{type Option}
import meal_planner/id
import meal_planner/id.{type FdcId}
import meal_planner/types/custom_food
import meal_planner/types/custom_food.{type CustomFood}

/// Unified search result with source identification
pub type FoodSearchResult {
  /// Custom food result (user-created)
  CustomFoodResult(food: CustomFood)
  /// USDA food result (from national database)
  UsdaFoodResult(
    fdc_id: FdcId,
    description: String,
    data_type: String,
    category: String,
    serving_size: String,
  )
}

/// Search response wrapper with metadata
pub type FoodSearchResponse {
  FoodSearchResponse(
    results: List(FoodSearchResult),
    total_count: Int,
    custom_count: Int,
    usda_count: Int,
  )
}

/// Search error types
pub type FoodSearchError {
  DatabaseError(String)
  InvalidQuery(String)
}

/// Search filter options
pub type SearchFilters {
  SearchFilters(
    verified_only: Bool,
    // Show only verified USDA foundation/SR legacy foods
    branded_only: Bool,
    // Show only branded commercial foods
    category: Option(String),
  )
}

// ============================================================================
// JSON Serialization
// ============================================================================

pub fn food_search_result_to_json(r: FoodSearchResult) -> Json {
  case r {
    CustomFoodResult(food) ->
      json.object([
        #("type", json.string("custom")),
        #("data", custom_food.to_json(food)),
      ])
    UsdaFoodResult(fdc_id, description, data_type, category, serving_size) ->
      json.object([
        #("type", json.string("usda")),
        #(
          "data",
          json.object([
            #("fdc_id", id.fdc_id_to_json(fdc_id)),
            #("description", json.string(description)),
            #("data_type", json.string(data_type)),
            #("category", json.string(category)),
            #("serving_size", json.string(serving_size)),
          ]),
        ),
      ])
  }
}

pub fn food_search_response_to_json(resp: FoodSearchResponse) -> Json {
  json.object([
    #("results", json.array(resp.results, food_search_result_to_json)),
    #("total_count", json.int(resp.total_count)),
    #("custom_count", json.int(resp.custom_count)),
    #("usda_count", json.int(resp.usda_count)),
  ])
}

// ============================================================================
// JSON Deserialization
// ============================================================================

pub fn food_search_result_decoder() -> Decoder(FoodSearchResult) {
  use type_field <- decode.field("type", decode.string)
  case type_field {
    "custom" -> {
      use data <- decode.field("data", custom_food.decoder())
      decode.success(CustomFoodResult(data))
    }
    "usda" -> {
      use data <- decode.field("data", fn(d) {
        use fdc_id <- decode.field("fdc_id", id.fdc_id_decoder())(d)
        use description <- decode.field("description", decode.string)(d)
        use data_type <- decode.field("data_type", decode.string)(d)
        use category <- decode.field("category", decode.string)(d)
        use serving_size <- decode.field("serving_size", decode.string)(d)
        decode.success(UsdaFoodResult(
          fdc_id: fdc_id,
          description: description,
          data_type: data_type,
          category: category,
          serving_size: serving_size,
        ))
      })
      decode.success(data)
    }
    _ -> decode.failure(UsdaFoodResult(fdc_id: 0, description: "", data_type: "", category: None, serving_size: None), "FoodSearchResult")
  }
}

pub fn food_search_response_decoder() -> Decoder(FoodSearchResponse) {
  use results <- decode.field(
    "results",
    decode.list(food_search_result_decoder()),
  )
  use total_count <- decode.field("total_count", decode.int)
  use custom_count <- decode.field("custom_count", decode.int)
  use usda_count <- decode.field("usda_count", decode.int)
  decode.success(FoodSearchResponse(
    results: results,
    total_count: total_count,
    custom_count: custom_count,
    usda_count: usda_count,
  ))
}
