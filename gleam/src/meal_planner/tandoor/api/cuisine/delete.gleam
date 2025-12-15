/// Cuisine Delete API
///
/// This module provides functions to delete cuisines from the Tandoor API.
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}

/// Delete a cuisine from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `cuisine_id` - ID of the cuisine to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_cuisine(config, cuisine_id: 5)
/// ```
pub fn delete_cuisine(
  config: ClientConfig,
  cuisine_id cuisine_id: Int,
) -> Result(Nil, TandoorError) {
  generic_crud.delete(config, "/api/cuisine/", cuisine_id)
}
