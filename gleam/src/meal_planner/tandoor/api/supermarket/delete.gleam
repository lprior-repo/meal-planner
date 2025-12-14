/// Supermarket Delete API
///
/// This module provides functions to delete supermarkets from the Tandoor API.
import gleam/int
import gleam/result
import meal_planner/tandoor/api/crud_helpers
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
  let path = "/api/supermarket/" <> int.to_string(id) <> "/"

  // Execute DELETE and verify empty response
  use resp <- result.try(crud_helpers.execute_delete(config, path))
  crud_helpers.parse_empty_response(resp)
}
