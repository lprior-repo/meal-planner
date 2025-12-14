/// Recipe List API
///
/// This module provides functions to list recipes from the Tandoor API
/// with pagination support.
import gleam/dynamic/decode
import gleam/httpc
import gleam/int
import gleam/json
import gleam/option.{type Option}
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
import meal_planner/tandoor/core/http.{type PaginatedResponse}
import meal_planner/tandoor/decoders/recipe/recipe_decoder
import meal_planner/tandoor/types.{type TandoorRecipe}

/// List recipes from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page (limit parameter)
/// * `offset` - Optional offset for pagination
///
/// # Returns
/// Result with paginated recipe list or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_recipes(config, limit: Some(20), offset: Some(0))
/// ```
pub fn list_recipes(
  config: ClientConfig,
  limit limit: Option(Int),
  offset offset: Option(Int),
) -> Result(PaginatedResponse(TandoorRecipe), TandoorError) {
  // Build query parameters
  let path = case limit, offset {
    option.Some(l), option.Some(o) ->
      "/api/recipe/?limit="
      <> int.to_string(l)
      <> "&offset="
      <> int.to_string(o)
    option.Some(l), option.None -> "/api/recipe/?limit=" <> int.to_string(l)
    option.None, option.Some(o) -> "/api/recipe/?offset=" <> int.to_string(o)
    option.None, option.None -> "/api/recipe/"
  }

  // Build and execute request
  use req <- result.try(client.build_get_request(config, path, []))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      // Decode paginated response with recipe items
      case
        decode.run(
          json_data,
          http.paginated_decoder(recipe_decoder.recipe_decoder()),
        )
      {
        Ok(paginated) -> Ok(paginated)
        Error(errors) -> {
          let error_msg =
            "Failed to decode recipe list: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}
