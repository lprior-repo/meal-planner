/// Supermarket Create API
///
/// This module provides functions to create new supermarkets in Tandoor.
import gleam/dynamic/decode
import gleam/httpc
import gleam/json
import gleam/result
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError,
}
import meal_planner/tandoor/decoders/supermarket/supermarket_decoder
import meal_planner/tandoor/encoders/supermarket/supermarket_create_encoder
import meal_planner/tandoor/types/supermarket/supermarket.{type Supermarket}
import meal_planner/tandoor/types/supermarket/supermarket_create.{
  type SupermarketCreateRequest,
}

/// Create a new supermarket
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `request` - Supermarket creation request data
///
/// # Returns
/// Result with created supermarket or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let request = SupermarketCreateRequest(
///   name: "Whole Foods",
///   description: Some("Natural grocery store")
/// )
/// let result = create_supermarket(config, request)
/// ```
pub fn create_supermarket(
  config: ClientConfig,
  request: SupermarketCreateRequest,
) -> Result(Supermarket, TandoorError) {
  let path = "/api/supermarket/"

  // Encode request data to JSON
  let body =
    supermarket_create_encoder.encode_supermarket_create(request)
    |> json.to_string

  // Build and execute request
  use req <- result.try(client.build_post_request(config, path, body))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Convert to ApiResponse and parse JSON
  let api_resp = client.ApiResponse(resp.status, resp.headers, resp.body)
  client.parse_json_body(api_resp, fn(dyn) {
    decode.run(dyn, supermarket_decoder.decoder())
    |> result.map_error(fn(_) { "Failed to decode created supermarket" })
  })
}
