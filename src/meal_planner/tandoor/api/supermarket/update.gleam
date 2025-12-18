/// Supermarket Update API
///
/// This module provides functions to update existing supermarkets in Tandoor.
import gleam/json
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
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
  // Encode supermarket data to JSON
  let body =
    supermarket_encoder.encode_supermarket_create(supermarket_data)
    |> json.to_string

  // Use generic_crud to update supermarket
  generic_crud.update(
    config,
    "/api/supermarket/",
    id,
    body,
    supermarket_decoder.decoder(),
  )
}
