/// Tests for Automation encoder
///
/// This module tests JSON encoding of Automation types.
/// Following TDD: these tests should FAIL first, then pass after implementation.
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/encoders/automation/automation_encoder
import meal_planner/tandoor/types/automation/automation.{
  Automation, FoodAlias, KeywordAlias,
}

/// Test encoding AutomationCreateRequest for FoodAlias
pub fn encode_automation_create_food_alias_test() {
  let create_req =
    automation_encoder.AutomationCreateRequest(
      name: "Tomato Alias",
      description: "Map tomato to tomatoes",
      automation_type: FoodAlias,
      param_1: "tomato",
      param_2: "tomatoes",
      param_3: None,
      order: 10,
      disabled: False,
    )

  let encoded = automation_encoder.encode_automation_create_request(create_req)
  let json_string = json.to_string(encoded)

  // Should produce complete JSON
  json_string
  |> should.equal(
    "{\"name\":\"Tomato Alias\",\"description\":\"Map tomato to tomatoes\",\"type\":\"FOOD_ALIAS\",\"param_1\":\"tomato\",\"param_2\":\"tomatoes\",\"param_3\":null,\"order\":10,\"disabled\":false}",
  )
}

/// Test encoding AutomationCreateRequest with param_3
pub fn encode_automation_create_with_param3_test() {
  let create_req =
    automation_encoder.AutomationCreateRequest(
      name: "Desc Replace",
      description: "",
      automation_type: automation_encoder.DescriptionReplace,
      param_1: ".*",
      param_2: "ads.*",
      param_3: Some("removed"),
      order: 1,
      disabled: False,
    )

  let encoded = automation_encoder.encode_automation_create_request(create_req)
  let json_string = json.to_string(encoded)

  // Should include param_3
  json_string
  |> should.contain("\"param_3\":\"removed\"")
}

/// Test encoding AutomationUpdateRequest (partial)
pub fn encode_automation_update_partial_test() {
  let update_req =
    automation_encoder.AutomationUpdateRequest(
      name: Some("Updated Name"),
      description: None,
      automation_type: None,
      param_1: None,
      param_2: None,
      param_3: None,
      order: Some(5),
      disabled: None,
    )

  let encoded = automation_encoder.encode_automation_update_request(update_req)
  let json_string = json.to_string(encoded)

  // Should only include provided fields
  json_string
  |> should.contain("\"name\":\"Updated Name\"")
  json_string
  |> should.contain("\"order\":5")
}

/// Test encoding disabled automation
pub fn encode_automation_disabled_test() {
  let create_req =
    automation_encoder.AutomationCreateRequest(
      name: "Disabled",
      description: "",
      automation_type: KeywordAlias,
      param_1: "a",
      param_2: "b",
      param_3: None,
      order: 1,
      disabled: True,
    )

  let encoded = automation_encoder.encode_automation_create_request(create_req)
  let json_string = json.to_string(encoded)

  json_string
  |> should.contain("\"disabled\":true")
}
