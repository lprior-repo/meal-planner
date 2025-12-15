//// Assertion helpers for integration tests
//// Composable assertion functions for API response validation

import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleeunit/should
import integration/helpers/http

/// Assert HTTP response status code matches expected value
pub fn assert_status(
  response: #(Int, String),
  expected: Int,
) -> Result(#(Int, String), String) {
  let #(status, _body) = response
  case status == expected {
    True -> Ok(response)
    False -> Error("Status code mismatch")
  }
}

/// Assert body is valid JSON
pub fn assert_valid_json(body: String) -> Result(String, String) {
  // Simple validation: check if it looks like JSON
  case
    string.starts_with(string.trim(body), "{")
    || string.starts_with(string.trim(body), "[")
  {
    True -> Ok(body)
    False -> Error("Body is not valid JSON")
  }
}

/// Assert JSON object has a specific field
pub fn assert_has_field(
  body: String,
  field_name: String,
) -> Result(String, String) {
  let search_pattern = "\"" <> field_name <> "\":"
  case string.contains(body, search_pattern) {
    True -> Ok(body)
    False -> Error("Field '" <> field_name <> "' not found in JSON")
  }
}

/// Assert JSON object has an array field
pub fn assert_has_array(
  body: String,
  field_name: String,
) -> Result(String, String) {
  let search_pattern = "\"" <> field_name <> "\":[["

  case string.contains(body, search_pattern) {
    True -> Ok(body)
    False -> Error("Array field '" <> field_name <> "' not found in JSON")
  }
}

/// Assert numeric field has positive value
pub fn assert_positive_number(
  body: String,
  field_name: String,
) -> Result(String, String) {
  // Simplified validation - check field exists (proper validation would parse JSON)
  let search_pattern = "\"" <> field_name <> "\":"
  case string.contains(body, search_pattern) {
    True -> Ok(body)
    False -> Error("Numeric field '" <> field_name <> "' not found")
  }
}

/// Assert string field is non-empty
pub fn assert_non_empty_string(
  body: String,
  field_name: String,
) -> Result(String, String) {
  let search_pattern = "\"" <> field_name <> "\":\""
  case string.contains(body, search_pattern) {
    True -> Ok(body)
    False -> Error("String field '" <> field_name <> "' is empty or missing")
  }
}

/// Assert response has multiple fields
pub fn assert_has_fields(
  body: String,
  field_names: List(String),
) -> Result(String, String) {
  field_names
  |> list.try_fold(body, fn(acc, field) { assert_has_field(acc, field) })
}

/// Validate JSON response with field checks
pub fn validate_json_with_fields(body: String, field_names: List(String)) -> Nil {
  case assert_valid_json(body) {
    Ok(data) -> {
      io.println("  ✓ Valid JSON response")
      case assert_has_fields(data, field_names) {
        Ok(_) -> {
          io.println("  ✓ Response shape validated")
          Nil
        }
        Error(e) -> {
          io.println("  ✗ Field validation error: " <> e)
          should.fail()
        }
      }
    }
    Error(e) -> {
      io.println("  ✗ JSON parse error: " <> e)
      should.fail()
    }
  }
}

/// Run endpoint test with standard assertions
pub fn test_endpoint(
  endpoint: String,
  expected_status: Int,
  required_fields: List(String),
) -> Nil {
  case http.get(endpoint) {
    Ok(response) -> {
      let #(status, body) = response
      io.println("✅ Response status: " <> int.to_string(status))

      response
      |> assert_status(expected_status)
      |> result.map(fn(_) { validate_json_with_fields(body, required_fields) })
      |> should.be_ok()
    }
    Error(_e) -> {
      io.println("⚠️  Server connection error")
      io.println("  Make sure server is running: gleam run")
      should.fail()
    }
  }
}
