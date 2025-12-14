/// Step Get API
///
/// This module provides functions to get a single step by ID from the
/// Tandoor API.
import gleam/int
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/recipe/step_decoder
import meal_planner/tandoor/types/recipe/step.{type Step}

/// Get a single step by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `step_id` - The ID of the step to fetch
///
/// # Returns
/// Result with step details or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_step(config, step_id: 42)
/// ```
pub fn get_step(
  config: ClientConfig,
  step_id step_id: Int,
) -> Result(Step, TandoorError) {
  // Build path with step ID
  let path = "/api/step/" <> int.to_string(step_id) <> "/"

  // Execute GET request using CRUD helper
  use resp <- result.try(crud_helpers.execute_get(config, path, []))

  // Parse JSON response using single object helper
  crud_helpers.parse_json_single(resp, step_decoder.step_decoder())
}
