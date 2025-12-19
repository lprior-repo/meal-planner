/// Generators for property-based testing of FatSecret decoders
///
/// This module provides simple list-based generators for testing edge cases in
/// FatSecret API response handling.
import gleam/list

/// Generator for flexible float string variants
///
/// Generates valid float formats that work reliably across all environments.
/// These are the string formats FatSecret API commonly returns.
pub fn flexible_float_strings() -> List(String) {
  [
    // Standard float strings with decimal point
    "0.0", "1.0", "2.0", "5.0", "42.0", "100.0", "999.0",
    // Common decimal values
    "1.5", "3.14", "0.99", "42.42", "100.1",
    "0.5", "0.25", "10.5", "99.99",
    // Larger decimal values
    "123.456", "1.001",
  ]
}

/// Generator for single or array JSON string structures
///
/// Generates JSON strings that match FatSecret's quirk of returning:
/// - Single object for 1 result
/// - Array for multiple results
///
/// Returns List of raw JSON strings for testing
pub fn single_or_array_json_strings() -> List(String) {
  [
    // Single object
    "{\"food_id\": \"123\", \"name\": \"Apple\"}",
    // Array with 2 items
    "[{\"food_id\": \"123\", \"name\": \"Apple\"}, {\"food_id\": \"456\", \"name\": \"Banana\"}]",
    // Empty array
    "[]",
  ]
}

/// Generator for flexible float JSON strings (number or string)
///
/// Returns JSON strings that can be either:
/// - Actual number: {"value": 1.5}
/// - String number: {"value": "1.5"}
pub fn flexible_float_json_strings() -> List(String) {
  flexible_float_strings()
  |> list.flat_map(fn(s) {
    [
      // String variant
      "{\"value\": \"" <> s <> "\"}",
      // Number variant (for simple cases)
      "{\"value\": " <> s <> "}",
    ]
  })
}
