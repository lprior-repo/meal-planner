/// Step Delete API
///
/// This module provides functions to delete steps from the Tandoor API.
import gleam/int
import gleam/result
import meal_planner/tandoor/api/crud_helpers
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
  // Build path with step ID
  let path = "/api/step/" <> int.to_string(step_id) <> "/"

  // Execute DELETE request using CRUD helper
  use resp <- result.try(crud_helpers.execute_delete(config, path))

  // Parse empty response (204 No Content expected)
  crud_helpers.parse_empty_response(resp)
}
