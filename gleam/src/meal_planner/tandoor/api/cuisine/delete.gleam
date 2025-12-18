/// Cuisine Delete API
///
/// This module provides functions to delete cuisines from the Tandoor API.
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/ids.{type CuisineId, cuisine_id_to_int}

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
/// let cuisine_id = ids.cuisine_id_from_int(5)
/// let result = delete_cuisine(config, cuisine_id: cuisine_id)
/// ```
pub fn delete_cuisine(
  config: ClientConfig,
  cuisine_id cuisine_id: CuisineId,
) -> Result(Nil, TandoorError) {
  generic_crud.delete(config, "/api/cuisine/", cuisine_id_to_int(cuisine_id))
}
