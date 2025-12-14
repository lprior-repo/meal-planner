/// Step Create API
///
/// This module provides functions to create new steps in the Tandoor API.
import gleam/json
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/recipe/step_decoder
import meal_planner/tandoor/encoders/recipe/step_encoder.{
  type StepCreateRequest, encode_step_create,
}
import meal_planner/tandoor/types/recipe/step.{type Step}

/// Create a new step in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `request` - Step data to create
///
/// # Returns
/// Result with created step or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let request = StepCreateRequest(
///   name: "Prepare ingredients",
///   instruction: "Chop all vegetables finely",
///   ingredients: [1, 2, 3],
///   time: 15,
///   order: 0,
///   show_as_header: False,
///   show_ingredients_table: True,
///   file: None
/// )
/// let result = create_step(config, request)
/// ```
pub fn create_step(
  config: ClientConfig,
  request: StepCreateRequest,
) -> Result(Step, TandoorError) {
  // Encode step data to JSON
  let request_body = encode_step_create(request) |> json.to_string

  // Execute POST request using CRUD helper
  use resp <- result.try(crud_helpers.execute_post(
    config,
    "/api/step/",
    request_body,
  ))

  // Parse JSON response using single object helper
  crud_helpers.parse_json_single(resp, step_decoder.step_decoder())
}
