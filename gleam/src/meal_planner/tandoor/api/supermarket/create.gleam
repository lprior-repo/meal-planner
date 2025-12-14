/// Supermarket Create API
///
/// This module provides functions to create new supermarkets in Tandoor.
import gleam/json
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
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
  // Encode request data to JSON
  let body =
    supermarket_create_encoder.encode_supermarket_create(request)
    |> json.to_string

  // Execute POST and parse single response
  use resp <- result.try(crud_helpers.execute_post(
    config,
    "/api/supermarket/",
    body,
  ))
  crud_helpers.parse_json_single(resp, supermarket_decoder.decoder())
}
