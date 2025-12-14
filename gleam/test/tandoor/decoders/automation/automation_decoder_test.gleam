/// Tests for Automation decoder
///
/// This module tests JSON decoding of Automation types.
/// Following TDD: these tests should FAIL first, then pass after implementation.
import gleam/dynamic
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/decoders/automation/automation_decoder
import meal_planner/tandoor/types/automation/automation.{
  Automation, DescriptionReplace, FoodAlias,
}

/// Test decoding a FoodAlias automation
pub fn decode_automation_food_alias_test() {
  let json_string =
    "{\"id\":1,\"name\":\"Tomato to Tomatoes\",\"description\":\"Alias singular to plural\",\"type\":\"FOOD_ALIAS\",\"param_1\":\"tomato\",\"param_2\":\"tomatoes\",\"param_3\":null,\"order\":10,\"disabled\":false,\"created_at\":\"2024-01-01T00:00:00Z\",\"updated_at\":\"2024-01-01T00:00:00Z\"}"

  let result =
    json.parse(json_string, using: decode.dynamic)
    |> should.be_ok
    |> decode.run(automation_decoder.automation_decoder())

  result
  |> should.be_ok
  |> should.equal(Automation(
    id: 1,
    name: "Tomato to Tomatoes",
    description: "Alias singular to plural",
    automation_type: FoodAlias,
    param_1: "tomato",
    param_2: "tomatoes",
    param_3: None,
    order: 10,
    disabled: False,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  ))
}

/// Test decoding a DescriptionReplace automation
pub fn decode_automation_description_replace_test() {
  let json_string =
    "{\"id\":2,\"name\":\"Remove ads\",\"description\":\"Strip advertising from imported recipes\",\"type\":\"DESCRIPTION_REPLACE\",\"param_1\":\".*\",\"param_2\":\"Visit our site.*\",\"param_3\":\"<removed>\",\"order\":1,\"disabled\":false,\"created_at\":\"2024-01-02T00:00:00Z\",\"updated_at\":\"2024-01-02T00:00:00Z\"}"

  let result =
    json.parse(json_string, using: decode.dynamic)
    |> should.be_ok
    |> decode.run(automation_decoder.automation_decoder())

  result
  |> should.be_ok
  |> should.equal(Automation(
    id: 2,
    name: "Remove ads",
    description: "Strip advertising from imported recipes",
    automation_type: DescriptionReplace,
    param_1: ".*",
    param_2: "Visit our site.*",
    param_3: Some("<removed>"),
    order: 1,
    disabled: False,
    created_at: "2024-01-02T00:00:00Z",
    updated_at: "2024-01-02T00:00:00Z",
  ))
}

/// Test decoding disabled automation
pub fn decode_automation_disabled_test() {
  let json_string =
    "{\"id\":3,\"name\":\"Old rule\",\"description\":\"\",\"type\":\"UNIT_ALIAS\",\"param_1\":\"tsp\",\"param_2\":\"teaspoon\",\"param_3\":null,\"order\":5,\"disabled\":true,\"created_at\":\"2024-01-03T00:00:00Z\",\"updated_at\":\"2024-01-03T00:00:00Z\"}"

  let result =
    json.parse(json_string, using: decode.dynamic)
    |> should.be_ok
    |> decode.run(automation_decoder.automation_decoder())

  result
  |> should.be_ok
  |> fn(a: Automation) {
    a.disabled
    |> should.be_true
  }
}

/// Test decoding list of automations
pub fn decode_automation_list_test() {
  let json_string =
    "[{\"id\":1,\"name\":\"Rule 1\",\"description\":\"\",\"type\":\"FOOD_ALIAS\",\"param_1\":\"a\",\"param_2\":\"b\",\"param_3\":null,\"order\":1,\"disabled\":false,\"created_at\":\"2024-01-01T00:00:00Z\",\"updated_at\":\"2024-01-01T00:00:00Z\"},{\"id\":2,\"name\":\"Rule 2\",\"description\":\"\",\"type\":\"KEYWORD_ALIAS\",\"param_1\":\"c\",\"param_2\":\"d\",\"param_3\":null,\"order\":2,\"disabled\":false,\"created_at\":\"2024-01-02T00:00:00Z\",\"updated_at\":\"2024-01-02T00:00:00Z\"}]"

  let result =
    json.parse(json_string, using: decode.dynamic)
    |> should.be_ok
    |> decode.run(decode.list(automation_decoder.automation_decoder()))

  result
  |> should.be_ok
  |> fn(list) {
    list
    |> should.have_length(2)
  }
}

/// Test decoding with empty description
pub fn decode_automation_empty_description_test() {
  let json_string =
    "{\"id\":4,\"name\":\"Simple rule\",\"description\":\"\",\"type\":\"FOOD_ALIAS\",\"param_1\":\"x\",\"param_2\":\"y\",\"param_3\":null,\"order\":1,\"disabled\":false,\"created_at\":\"2024-01-04T00:00:00Z\",\"updated_at\":\"2024-01-04T00:00:00Z\"}"

  let result =
    json.parse(json_string, using: decode.dynamic)
    |> should.be_ok
    |> decode.run(automation_decoder.automation_decoder())

  result
  |> should.be_ok
  |> fn(a: Automation) {
    a.description
    |> should.equal("")
  }
}
