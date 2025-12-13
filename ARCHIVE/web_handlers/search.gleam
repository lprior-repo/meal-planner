/// Food search handler with rate limiting
///
/// This module provides the search endpoint for USDA foods
/// with built-in rate limiting to prevent abuse
///
import gleam/http
import gleam/int
import gleam/json
import gleam/list
import gleam/string
import meal_planner/id
import meal_planner/storage/foods
import meal_planner/web/middleware
import pog
import wisp

/// Handle food search requests with rate limiting
/// GET /api/foods/search?q=query&limit=50
pub fn handle_search(
  req: wisp.Request,
  conn: pog.Connection,
  rate_limit_state: middleware.RateLimitState,
) -> #(wisp.Response, middleware.RateLimitState) {
  use <- wisp.require_method(req, http.Get)

  // Get current timestamp (in production, use proper time module)
  let current_time = 1_702_425_600

  // Extract client IP
  let client_ip = middleware.get_client_ip(req)

  // Check rate limit
  let rate_config = middleware.default_rate_limit()
  case middleware.check_rate_limit(client_ip, rate_limit_state, rate_config, current_time) {
    Error(retry_after) -> {
      // Rate limited - return 429
      #(middleware.rate_limit_response(retry_after), rate_limit_state)
    }
    Ok(new_state) -> {
      // Process search request
      case get_search_params(req) {
        Error(error_msg) -> {
          let response =
            json.object([
              #("status", json.string("error")),
              #("error", json.string(error_msg)),
            ])
            |> json.to_string
          #(wisp.json_response(response, 400), new_state)
        }
        Ok(#(query, limit)) -> {
          // Perform search
          case foods.search_foods(conn, query, limit) {
            Error(_) -> {
              let response =
                json.object([
                  #("status", json.string("error")),
                  #("error", json.string("Search failed")),
                ])
                |> json.to_string
              #(wisp.json_response(response, 500), new_state)
            }
            Ok(results) -> {
              // Build response
              let response =
                json.object([
                  #("status", json.string("success")),
                  #("count", json.int(list.length(results))),
                  #("results", json.array(results, food_to_json)),
                ])
                |> json.to_string
              #(wisp.json_response(response, 200), new_state)
            }
          }
        }
      }
    }
  }
}

/// Extract search parameters from request
fn get_search_params(req: wisp.Request) -> Result(#(String, Int), String) {
  case wisp.get_query(req) {
    [#("q", query), ..] -> {
      // Get limit parameter (default 50, max 100)
      let limit = case list.key_find(wisp.get_query(req), "limit") {
        Ok(limit_str) -> {
          case int.parse(limit_str) {
            Ok(n) if n > 0 && n <= 100 -> n
            _ -> 50
          }
        }
        Error(_) -> 50
      }

      case string.is_empty(query) {
        True -> Error("Search query cannot be empty")
        False -> Ok(#(query, limit))
      }
    }
    _ -> Error("Missing required parameter: q")
  }
}

/// Convert food to JSON
fn food_to_json(food: foods.UsdaFood) -> json.Json {
  json.object([
    #("fdc_id", json.int(id.fdc_id_to_int(food.fdc_id))),
    #("description", json.string(food.description)),
    #("data_type", json.string(food.data_type)),
    #("category", json.string(food.category)),
    #("serving_size", json.string(food.serving_size)),
  ])
}
