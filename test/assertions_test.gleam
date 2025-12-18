//// Assertions Module Tests
//// Tests for HTTP response validation and JSON parsing utilities

import gleeunit
import gleeunit/should
import meal_planner/test_helpers/assertions

pub fn main() {
  gleeunit.main()
}

// Test assert_status
pub fn assert_status_success_test() {
  let response = #(200, "", "")
  assertions.assert_status(response, 200)
  |> should.be_ok
}

pub fn assert_status_failure_test() {
  let response = #(404, "", "")
  assertions.assert_status(response, 200)
  |> should.be_error
}

// Test assert_valid_json with real JSON parsing
pub fn assert_valid_json_success_test() {
  let body = "{\"name\": \"test\", \"value\": 42}"
  assertions.assert_valid_json(body)
  |> should.be_ok
}

pub fn assert_valid_json_failure_test() {
  let body = "not valid json at all"
  assertions.assert_valid_json(body)
  |> should.be_error
}

pub fn assert_valid_json_empty_object_test() {
  let body = "{}"
  assertions.assert_valid_json(body)
  |> should.be_ok
}

// Test assert_has_field
pub fn assert_has_field_success_test() {
  let json_str = "{\"name\": \"test\"}"
  assertions.assert_has_field(json_str, "name")
  |> should.be_ok
}

pub fn assert_has_field_failure_test() {
  let json_str = "{\"name\": \"test\"}"
  assertions.assert_has_field(json_str, "missing")
  |> should.be_error
}

// Test assert_has_array
pub fn assert_has_array_success_test() {
  let json_str = "{\"items\": [\"a\", \"b\"]}"
  assertions.assert_has_array(json_str, "items")
  |> should.be_ok
}

pub fn assert_has_array_failure_test() {
  let json_str = "{\"items\": \"not_array\"}"
  assertions.assert_has_array(json_str, "items")
  |> should.be_error
}

pub fn assert_has_array_missing_field_test() {
  let json_str = "{}"
  assertions.assert_has_array(json_str, "items")
  |> should.be_error
}

// Test assert_positive_number
pub fn assert_positive_number_success_test() {
  let json_str = "{\"count\": 42}"
  assertions.assert_positive_number(json_str, "count")
  |> should.be_ok
}

pub fn assert_positive_number_zero_failure_test() {
  let json_str = "{\"count\": 0}"
  assertions.assert_positive_number(json_str, "count")
  |> should.be_error
}

pub fn assert_positive_number_negative_failure_test() {
  let json_str = "{\"count\": -5}"
  assertions.assert_positive_number(json_str, "count")
  |> should.be_error
}

pub fn assert_positive_number_missing_field_test() {
  let json_str = "{}"
  assertions.assert_positive_number(json_str, "count")
  |> should.be_error
}

pub fn assert_positive_number_float_test() {
  let json_str = "{\"count\": 42.5}"
  assertions.assert_positive_number(json_str, "count")
  |> should.be_ok
}

// Test assert_non_empty_string
pub fn assert_non_empty_string_success_test() {
  let json_str = "{\"name\": \"test\"}"
  assertions.assert_non_empty_string(json_str, "name")
  |> should.be_ok
}

pub fn assert_non_empty_string_empty_failure_test() {
  let json_str = "{\"name\": \"\"}"
  assertions.assert_non_empty_string(json_str, "name")
  |> should.be_error
}

pub fn assert_non_empty_string_whitespace_failure_test() {
  let json_str = "{\"name\": \"   \"}"
  assertions.assert_non_empty_string(json_str, "name")
  |> should.be_error
}

pub fn assert_non_empty_string_missing_field_test() {
  let json_str = "{}"
  assertions.assert_non_empty_string(json_str, "name")
  |> should.be_error
}
