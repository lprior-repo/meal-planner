/// Supermarket Get API
///
/// This module provides functions to retrieve a specific supermarket from Tandoor API.
import gleam/int
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
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

  // Execute GET and parse single response
  use resp <- result.try(crud_helpers.execute_get(config, path, []))
  crud_helpers.parse_json_single(resp, supermarket_decoder.decoder())
}
