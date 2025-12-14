/// Supermarket Get API
///
/// This module provides functions to retrieve a specific supermarket from Tandoor API.
import gleam/dynamic/decode
import gleam/httpc
import gleam/int
import gleam/json
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
import meal_planner/tandoor/decoders/supermarket/supermarket_decoder
import meal_planner/tandoor/types/supermarket/supermarket.{type Supermarket}

/// Get a single supermarket by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `id` - Supermarket ID
///
/// # Returns
/// Result with supermarket details or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_supermarket(config, id: 1)
/// ```
pub fn get_supermarket(
  config: ClientConfig,
  id id: Int,
) -> Result(Supermarket, TandoorError) {
  let path = "/api/supermarket/" <> int.to_string(id) <> "/"

  // Build and execute request
  use req <- result.try(client.build_get_request(config, path, []))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, supermarket_decoder.decoder()) {
        Ok(supermarket) -> Ok(supermarket)
        Error(errors) -> {
          let error_msg =
            "Failed to decode supermarket: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}
