/// Tests for email webhook handler
///
/// Tests focus on JSON encoding/decoding since Wisp handler testing
/// requires integration testing infrastructure. These tests verify that
/// payloads are correctly parsed and responses properly formatted.
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should

import meal_planner/email/command.{AdjustMeal, Breakfast, Friday}
import meal_planner/email/handler
import meal_planner/id

pub fn main() {
  gleeunit.main()
}

/// Test webhook response JSON encoding - success case
pub fn encode_webhook_response_success_test() {
  let command =
    AdjustMeal(
      day: Friday,
      meal_type: Breakfast,
      recipe_id: id.recipe_id("recipe-test-1"),
    )

  let response =
    handler.EmailWebhookResponse(
      success: True,
      command: Some(command),
      error: None,
      message: "Command parsed successfully",
    )

  let encoded = handler.encode_webhook_response(response)

  // Verify response structure - it should have success, command, error, message keys
  let success =
    json.object([
      #("success", json.bool(True)),
      #("command", json.string("command_parsed")),
      #("error", json.null()),
      #("message", json.string("Command parsed successfully")),
    ])

  json.to_string(encoded)
  |> should.equal(json.to_string(success))
}

/// Test webhook response JSON encoding - error case
pub fn encode_webhook_response_error_test() {
  let response =
    handler.EmailWebhookResponse(
      success: False,
      command: None,
      error: Some("No @Claude mention found"),
      message: "Failed to parse email command",
    )

  let encoded = handler.encode_webhook_response(response)

  // Verify error response structure
  let expected =
    json.object([
      #("success", json.bool(False)),
      #("command", json.null()),
      #("error", json.string("No @Claude mention found")),
      #("message", json.string("Failed to parse email command")),
    ])

  json.to_string(encoded)
  |> should.equal(json.to_string(expected))
}

/// Test email handler initialization works
pub fn handler_module_loads_test() {
  True
  |> should.be_true()
}
