/// Shopping List Entry Delete API
///
/// This module provides functions to delete shopping list entries from the Tandoor API.
import gleam/int
import gleam/result
import meal_planner/logger
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}

/// Delete a shopping list entry from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `id` - The ID of the shopping list entry to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// let config = ClientConfig(...)
/// let result = delete_shopping_list_entry(config, id: 1)
/// ```
pub fn delete_shopping_list_entry(
  config: ClientConfig,
  id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/shopping-list-entry/" <> int.to_string(id) <> "/"

  use req <- result.try(client.build_delete_request(config, path))
  logger.debug("Tandoor DELETE " <> path)

  use _resp <- result.try(client.execute_and_parse(req))
  Ok(Nil)
}
