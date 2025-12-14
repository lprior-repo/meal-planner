/// Supermarket Update API
///
/// This module provides functions to update existing supermarkets in Tandoor.
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
import meal_planner/tandoor/encoders/supermarket/supermarket_encoder
import meal_planner/tandoor/types/supermarket/supermarket.{type Supermarket}
import meal_planner/tandoor/types/supermarket/supermarket_create.{
  type SupermarketCreateRequest,
}

/// Update an existing supermarket in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `id` - Supermarket ID to update
/// * `supermarket_data` - Updated supermarket data (name, description)
///
/// # Returns
/// Result with updated supermarket or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let supermarket_data = SupermarketCreateRequest(
///   name: "Whole Foods Market",
///   description: Some("Updated description")
/// )
/// let result = update_supermarket(config, id: 1, supermarket_data: supermarket_data)
/// ```
pub fn update_supermarket(
  config: ClientConfig,
  id id: Int,
  supermarket_data supermarket_data: SupermarketCreateRequest,
) -> Result(Supermarket, TandoorError) {
  let path = "/api/supermarket/" <> int.to_string(id) <> "/"

  // Encode supermarket data to JSON
  let request_body =
    supermarket_encoder.encode_supermarket_create(supermarket_data)
    |> json.to_string

  // Build and execute PATCH request
  use req <- result.try(client.build_patch_request(config, path, request_body))

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
            "Failed to decode updated supermarket: " <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}
