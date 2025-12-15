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
import meal_planner/fatsecret/handlers_helpers as helpers
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
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  let food_id_typed = types.food_id(food_id)

  case service.get_food(food_id_typed) {
    Ok(food) -> {
      helpers.encode_food(food)
      |> json.to_string
      |> wisp.json_response(200)
    Error(service.NotConfigured) -> {
      helpers.error_response(
        500,
        "FatSecret API not configured. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET.",
      )
    Error(service.ApiError(inner)) -> {
      helpers.error_response(
        502,
        "FatSecret API error: "
          <> service.error_to_string(service.ApiError(inner)),
      )
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
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.require_method(req, http.Get)

  let query_params = wisp.get_query(req)

  let query = helpers.get_query_param(query_params, "q")
  let page =
    helpers.parse_int_param(query_params, "page")
    |> option.unwrap(0)
  let limit =
    helpers.parse_int_param(query_params, "limit")
    |> option.map(helpers.clamp_limit)
    |> option.unwrap(20)

  case helpers.validate_required_string(query, "q") {
    Error(#(status, msg)) -> helpers.error_response(status, msg)
    Ok(q) ->
      case service.search_foods(q, page, limit) {
        Ok(response) -> {
          search_response_to_json(response)
          |> json.to_string
          |> wisp.json_response(200)
        }
        Error(service.NotConfigured) -> {
          helpers.error_response(
            500,
            "FatSecret API not configured. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET.",
          )
        }
        Error(service.ApiError(inner)) -> {
          helpers.error_response(
            502,
            "FatSecret API error: "
              <> service.error_to_string(service.ApiError(inner)),
          )
        }
      }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Encode FoodSearchResponse to JSON
fn search_response_to_json(response: types.FoodSearchResponse) -> json.Json {
  json.object([
    #("foods", json.array(response.foods, helpers.encode_food_search_result)),
    #("total_results", json.int(response.total_results)),
    #("max_results", json.int(response.max_results)),
    #("page_number", json.int(response.page_number)),
  ])
}
