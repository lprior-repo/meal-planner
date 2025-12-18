/// Supermarket Create API
///
/// This module provides functions to create new supermarkets in Tandoor.
import gleam/json
import meal_planner/tandoor/api/generic_crud
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

  // Use generic_crud to create supermarket
  generic_crud.create(
    config,
    "/api/supermarket/",
    body,
    supermarket_decoder.decoder(),
  )
}
