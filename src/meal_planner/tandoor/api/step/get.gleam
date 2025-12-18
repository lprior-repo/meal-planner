/// Step Get API
///
/// This module provides functions to get a single step by ID from the
/// Tandoor API.
import meal_planner/tandoor/api/generic_crud
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
  // Get step using generic CRUD function
  generic_crud.get(config, "/api/step/", step_id, step_decoder.step_decoder())
}
