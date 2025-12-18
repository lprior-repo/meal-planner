/// Supermarket Get API
///
/// This module provides functions to retrieve a specific supermarket from Tandoor API.
import meal_planner/tandoor/api/generic_crud
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
  // Use generic_crud to get supermarket
  generic_crud.get(
    config,
    "/api/supermarket/",
    id,
    supermarket_decoder.decoder(),
  )
}
