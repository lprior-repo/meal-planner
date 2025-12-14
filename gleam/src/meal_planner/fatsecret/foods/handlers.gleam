/// FatSecret Foods API HTTP handlers
///
/// Routes:
/// - GET /api/fatsecret/foods/:id - Get food details by ID
/// - GET /api/fatsecret/foods/search?q=...&page=0&limit=20 - Search foods
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import meal_planner/fatsecret/foods/service
import meal_planner/fatsecret/foods/types
import wisp

// ============================================================================
// GET /api/fatsecret/foods/:id - Get food details
// ============================================================================

/// Get complete food details by ID
///
/// ## Example Request
/// ```
/// GET /api/fatsecret/foods/12345
/// ```
///
/// ## Example Response (Success)
/// ```json
/// {
///   "food_id": "12345",
///   "food_name": "Banana",
///   "food_type": "Generic",
///   "food_url": "https://...",
///   "servings": [
///     {
///       "serving_id": "1",
///       "serving_description": "1 medium (7\" to 7-7/8\" long)",
///       "calories": 105.0,
///       "carbohydrate": 27.0,
///       "protein": 1.3,
///       "fat": 0.4
///     }
///   ]
/// }
/// ```
///
/// ## Error Responses
/// - 404: Food not found
/// - 500: FatSecret not configured
/// - 502: API error
pub fn handle_get_food(req: wisp.Request, food_id: String) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  let food_id_typed = types.food_id(food_id)

  case service.get_food(food_id_typed) {
    Ok(food) -> {
      json.to_string_builder(food_to_json(food))
      |> wisp.json_response(200)
    }
    Error(service.NotConfigured) -> {
      error_response(
        500,
        "FatSecret API not configured. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET.",
      )
    }
    Error(service.ApiError(inner)) -> {
      error_response(
        502,
        "FatSecret API error: "
          <> service.error_to_string(service.ApiError(inner)),
      )
    }
  }
}

// ============================================================================
// GET /api/fatsecret/foods/search - Search foods
// ============================================================================

/// Search for foods by query string
///
/// ## Query Parameters
/// - q: Search query (required)
/// - page: Page number, 0-indexed (optional, default: 0)
/// - limit: Results per page, 1-50 (optional, default: 20)
///
/// ## Example Request
/// ```
/// GET /api/fatsecret/foods/search?q=banana&page=0&limit=20
/// ```
///
/// ## Example Response
/// ```json
/// {
///   "foods": [
///     {
///       "food_id": "12345",
///       "food_name": "Banana",
///       "food_type": "Generic",
///       "food_description": "Per 1 medium - Calories: 105kcal | Fat: 0.39g | Carbs: 26.95g | Protein: 1.29g"
///     }
///   ],
///   "total_results": 250,
///   "max_results": 20,
///   "page_number": 0
/// }
/// ```
pub fn handle_search_foods(req: wisp.Request) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)

  // Parse query parameters
  let query_params = wisp.get_query(req) |> result.unwrap([])

  let query = get_query_param(query_params, "q")
  let page =
    get_query_param(query_params, "page")
    |> option.then(int.parse)
    |> option.unwrap(0)
  let limit =
    get_query_param(query_params, "limit")
    |> option.then(int.parse)
    |> option.map(clamp_limit)
    |> option.unwrap(20)

  case query {
    None -> {
      error_response(400, "Missing required query parameter: q")
    }
    Some(q) -> {
      case string.is_empty(q) {
        True -> error_response(400, "Query parameter 'q' cannot be empty")
        False ->
          case service.search_foods(q, page, limit) {
            Ok(response) -> {
              json.to_string_builder(search_response_to_json(response))
              |> wisp.json_response(200)
            }
            Error(service.NotConfigured) -> {
              error_response(
                500,
                "FatSecret API not configured. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET.",
              )
            }
            Error(service.ApiError(inner)) -> {
              error_response(
                502,
                "FatSecret API error: "
                  <> service.error_to_string(service.ApiError(inner)),
              )
            }
          }
      }
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Get query parameter value by key
fn get_query_param(
  params: List(#(String, String)),
  key: String,
) -> option.Option(String) {
  list.find(params, fn(param) { param.0 == key })
  |> result.map(fn(param) { param.1 })
  |> option.from_result
}

/// Clamp limit to valid range (1-50)
fn clamp_limit(limit: Int) -> Int {
  case limit {
    _ if limit < 1 -> 1
    _ if limit > 50 -> 50
    _ -> limit
  }
}

/// Create error response JSON
fn error_response(status: Int, message: String) -> wisp.Response {
  json.object([#("error", json.string(message))])
  |> json.to_string_builder
  |> wisp.json_response(status)
}

// ============================================================================
// JSON Encoding
// ============================================================================

/// Encode Food to JSON
fn food_to_json(food: types.Food) -> json.Json {
  json.object([
    #("food_id", json.string(types.food_id_to_string(food.food_id))),
    #("food_name", json.string(food.food_name)),
    #("food_type", json.string(food.food_type)),
    #("food_url", json.string(food.food_url)),
    #("brand_name", option_to_json(food.brand_name, json.string)),
    #("servings", json.array(food.servings, serving_to_json)),
  ])
}

/// Encode Serving to JSON
fn serving_to_json(serving: types.Serving) -> json.Json {
  json.object([
    #("serving_id", json.string(types.serving_id_to_string(serving.serving_id))),
    #("serving_description", json.string(serving.serving_description)),
    #("serving_url", json.string(serving.serving_url)),
    #(
      "metric_serving_amount",
      option_to_json(serving.metric_serving_amount, json.float),
    ),
    #(
      "metric_serving_unit",
      option_to_json(serving.metric_serving_unit, json.string),
    ),
    #("number_of_units", json.float(serving.number_of_units)),
    #("measurement_description", json.string(serving.measurement_description)),
    #("nutrition", nutrition_to_json(serving.nutrition)),
  ])
}

/// Encode Nutrition to JSON
fn nutrition_to_json(nutrition: types.Nutrition) -> json.Json {
  json.object([
    #("calories", json.float(nutrition.calories)),
    #("carbohydrate", json.float(nutrition.carbohydrate)),
    #("protein", json.float(nutrition.protein)),
    #("fat", json.float(nutrition.fat)),
    #("saturated_fat", option_to_json(nutrition.saturated_fat, json.float)),
    #(
      "polyunsaturated_fat",
      option_to_json(nutrition.polyunsaturated_fat, json.float),
    ),
    #(
      "monounsaturated_fat",
      option_to_json(nutrition.monounsaturated_fat, json.float),
    ),
    #("cholesterol", option_to_json(nutrition.cholesterol, json.float)),
    #("sodium", option_to_json(nutrition.sodium, json.float)),
    #("potassium", option_to_json(nutrition.potassium, json.float)),
    #("fiber", option_to_json(nutrition.fiber, json.float)),
    #("sugar", option_to_json(nutrition.sugar, json.float)),
    #("vitamin_a", option_to_json(nutrition.vitamin_a, json.float)),
    #("vitamin_c", option_to_json(nutrition.vitamin_c, json.float)),
    #("calcium", option_to_json(nutrition.calcium, json.float)),
    #("iron", option_to_json(nutrition.iron, json.float)),
  ])
}

/// Encode FoodSearchResponse to JSON
fn search_response_to_json(response: types.FoodSearchResponse) -> json.Json {
  json.object([
    #("foods", json.array(response.foods, search_result_to_json)),
    #("total_results", json.int(response.total_results)),
    #("max_results", json.int(response.max_results)),
    #("page_number", json.int(response.page_number)),
  ])
}

/// Encode FoodSearchResult to JSON
fn search_result_to_json(result: types.FoodSearchResult) -> json.Json {
  json.object([
    #("food_id", json.string(types.food_id_to_string(result.food_id))),
    #("food_name", json.string(result.food_name)),
    #("food_type", json.string(result.food_type)),
    #("food_description", json.string(result.food_description)),
    #("brand_name", option_to_json(result.brand_name, json.string)),
    #("food_url", json.string(result.food_url)),
  ])
}

/// Convert Option to JSON (null if None)
fn option_to_json(
  opt: option.Option(a),
  encoder: fn(a) -> json.Json,
) -> json.Json {
  case opt {
    Some(value) -> encoder(value)
    None -> json.null()
  }
}
