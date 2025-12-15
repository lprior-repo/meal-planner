/// Supermarket Delete API
///
/// This module provides functions to delete supermarkets from the Tandoor API.
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}

/// Delete a supermarket from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `id` - The ID of the supermarket to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// let config = ClientConfig(...)
/// let result = delete_supermarket(config, id: 1)
/// ```
pub fn delete_supermarket(
  config: ClientConfig,
  id: Int,
) -> Result(Nil, TandoorError) {
  // Use generic_crud to delete supermarket
  generic_crud.delete(config, "/api/supermarket/", id)
}
