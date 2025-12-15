/// Step Delete API
///
/// This module provides functions to delete steps from the Tandoor API.
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}

/// Delete a step from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `step_id` - The ID of the step to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_step(config, step_id: 42)
/// ```
pub fn delete_step(
  config: ClientConfig,
  step_id step_id: Int,
) -> Result(Nil, TandoorError) {
  // Delete step using generic CRUD function
  generic_crud.delete(config, "/api/step/", step_id)
}
