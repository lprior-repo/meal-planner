/// Supermarket Update API
///
/// This module provides functions to update existing supermarkets in Tandoor.
import gleam/int
import gleam/json
import gleam/result
import meal_planner/tandoor/api/crud_helpers
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
  let path = "/api/supermarket/" <> int.to_string(id) <> "/"

  // Encode supermarket data to JSON
  let body =
    supermarket_encoder.encode_supermarket_create(supermarket_data)
    |> json.to_string

  // Execute PATCH and parse single response
  use resp <- result.try(crud_helpers.execute_patch(config, path, body))
  crud_helpers.parse_json_single(resp, supermarket_decoder.decoder())
}
