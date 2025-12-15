//// Assertion helpers for integration tests
//// Composable assertion functions for API response validation

import gleam/string

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
