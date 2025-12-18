/// Step Update API
///
/// This module provides functions to update existing steps in the Tandoor API.
import gleam/json
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/recipe/step_decoder
import meal_planner/tandoor/encoders/recipe/step_encoder.{
  type StepUpdateRequest, encode_step_update,
}
import meal_planner/tandoor/types/recipe/step.{type Step}

/// Update an existing step in Tandoor API (partial update via PATCH)
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `step_id` - The ID of the step to update
/// * `request` - Step fields to update (only Some() fields will be updated)
///
/// # Returns
/// Result with updated step or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let request = StepUpdateRequest(
///   name: Some("Prepare ingredients carefully"),
///   instruction: None,
///   ingredients: None,
///   time: Some(20),
///   order: None,
///   show_as_header: None,
///   show_ingredients_table: None,
///   file: None
/// )
/// let result = update_step(config, step_id: 42, request: request)
/// ```
pub fn update_step(
  config: ClientConfig,
  step_id step_id: Int,
  request request: StepUpdateRequest,
) -> Result(Step, TandoorError) {
  // Encode step update data to JSON
  let request_body = encode_step_update(request) |> json.to_string

  // Update step using generic CRUD function
  generic_crud.update(
    config,
    "/api/step/",
    step_id,
    request_body,
    step_decoder.step_decoder(),
  )
}

/// Replace an existing step in Tandoor API (full update via PUT)
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `step_id` - The ID of the step to replace
/// * `request` - Complete step data to replace existing step
///
/// # Returns
/// Result with updated step or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let request = StepCreateRequest(
///   name: "Updated step name",
///   instruction: "Updated instructions",
///   ingredients: [1, 2],
///   time: 30,
///   order: 1,
///   show_as_header: False,
///   show_ingredients_table: True,
///   file: None
/// )
/// let result = replace_step(config, step_id: 42, request: request)
/// ```
pub fn replace_step(
  config: ClientConfig,
  step_id step_id: Int,
  request request: step_encoder.StepCreateRequest,
) -> Result(Step, TandoorError) {
  // Encode step data to JSON (use create encoder for full replacement)
  let request_body = step_encoder.encode_step_create(request) |> json.to_string

  // Note: PUT is not directly supported by generic_crud, use PATCH as workaround
  // For full replacement semantics, PATCH with all fields is equivalent
  generic_crud.update(
    config,
    "/api/step/",
    step_id,
    request_body,
    step_decoder.step_decoder(),
  )
}
