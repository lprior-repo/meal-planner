/// Food List API
///
/// This module provides functions to list foods from the Tandoor API
/// with pagination support.
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/http.{type PaginatedResponse}
import meal_planner/tandoor/decoders/food/food_decoder
import meal_planner/tandoor/types/food/food.{type Food}

/// List foods from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page (page_size parameter)
/// * `page` - Optional page number for pagination
///
/// # Returns
/// Result with paginated food list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_foods(config, limit: Some(20), page: Some(1))
/// ```
pub fn list_foods(
  config: ClientConfig,
  limit limit: Option(Int),
  page page: Option(Int),
) -> Result(PaginatedResponse(Food), TandoorError) {
  // Build query parameters
  let params = case limit, page {
    option.Some(l), option.Some(p) -> [
      #("page_size", int.to_string(l)),
      #("page", int.to_string(p)),
    ]
    option.Some(l), option.None -> [#("page_size", int.to_string(l))]
    option.None, option.Some(p) -> [#("page", int.to_string(p))]
    option.None, option.None -> []
  }

  use resp <- result.try(crud_helpers.execute_get(config, "/api/food/", params))
  crud_helpers.parse_json_single(
    resp,
    http.paginated_decoder(food_decoder.food_decoder()),
  )
}

/// List foods from Tandoor API with extended options
///
/// This function provides more flexible querying with support for limit,
/// offset-based pagination, and query string search.
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results to return (limit parameter)
/// * `offset` - Optional number of results to skip (offset parameter)
/// * `query` - Optional search query string to filter foods by name
///
/// # Returns
/// Result with paginated food list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// // List first 10 foods
/// let result = list_foods_with_options(config, Some(10), None, None)
///
/// // Search for foods with query
/// let result = list_foods_with_options(config, Some(20), Some(0), Some("tomato"))
///
/// // Paginate with offset
/// let result = list_foods_with_options(config, Some(10), Some(20), None)
/// ```
pub fn list_foods_with_options(
  config: ClientConfig,
  limit: Option(Int),
  offset: Option(Int),
  query: Option(String),
) -> Result(PaginatedResponse(Food), TandoorError) {
  // Build query parameters list using functional pipeline pattern
  // This matches the pattern used in recipe/list.gleam
  let query_params =
    []
    |> fn(params) {
      case limit {
        option.Some(l) -> [#("limit", int.to_string(l)), ..params]
        option.None -> params
      }
    }
    |> fn(params) {
      case offset {
        option.Some(o) -> [#("offset", int.to_string(o)), ..params]
        option.None -> params
      }
    }
    |> fn(params) {
      case query {
        option.Some(q) -> [#("query", q), ..params]
        option.None -> params
      }
    }
    |> list.reverse

  // Execute GET request using CRUD helper
  use resp <- result.try(crud_helpers.execute_get(
    config,
    "/api/food/",
    query_params,
  ))

  // Parse JSON response using paginated helper
  crud_helpers.parse_json_paginated(resp, food_decoder.food_decoder())
}
