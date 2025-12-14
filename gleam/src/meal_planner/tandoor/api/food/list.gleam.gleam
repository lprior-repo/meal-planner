/// Food List API
///
/// This module provides functions to list foods from the Tandoor API
/// with pagination support.
import gleam/dynamic/decode
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/option.{type Option}
import gleam/result
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
import meal_planner/tandoor/core/http.{type PaginatedResponse}
import meal_planner/tandoor/decoders/recipe/recipe_decoder
import meal_planner/tandoor/types.{type TandoorFood}

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
) -> Result(PaginatedResponse(TandoorFood), TandoorError) {
  // Build query parameters
  let path = case limit, page {
    option.Some(l), option.Some(p) ->
      "/api/food/?page_size="
      <> int.to_string(l)
      <> "&page="
      <> int.to_string(p)
    option.Some(l), option.None -> "/api/food/?page_size=" <> int.to_string(l)
    option.None, option.Some(p) -> "/api/food/?page=" <> int.to_string(p)
    option.None, option.None -> "/api/food/"
  }

  // Build and execute request
  use req <- result.try(client.build_get_request(config, path))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse paginated response
  use body <- result.try(client.parse_json_body(resp.body))

  // Decode paginated response with food items
  decode.run(body, http.paginated_decoder(recipe_decoder.food_decoder()))
  |> result.map_error(fn(err) {
    ParseError("Failed to decode food list: " <> err)
  })
}
