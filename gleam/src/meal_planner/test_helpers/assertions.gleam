//// Test Assertions Module
//// Provides utilities for validating HTTP responses and JSON data in tests

import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/result
import gleam/string

/// Error type for assertion failures
pub type AssertionError {
  StatusMismatch(expected: Int, got: Int)
  InvalidJson(message: String)
  FieldMissing(field: String)
  NotAnArray(field: String)
  NotPositive(field: String, value: Float)
  EmptyString(field: String)
  DecodingError(message: String)
}

/// Assert HTTP status code matches expected value
pub fn assert_status(
  response: #(Int, a, b),
  expected: Int,
) -> Result(Nil, AssertionError) {
  let #(status, _headers, _body) = response
  case status == expected {
    True -> Ok(Nil)
    False -> Error(StatusMismatch(expected: expected, got: status))
  }
}

/// Assert string is valid JSON by attempting to parse it
pub fn assert_valid_json(
  body: String,
) -> Result(dynamic.Dynamic, AssertionError) {
  json.parse(body, decode.dynamic)
  |> result.map_error(fn(_) { InvalidJson("Failed to parse JSON: " <> body) })
}

/// Decoder that extracts a field
fn field_decoder(field_name: String) -> decode.Decoder(dynamic.Dynamic) {
  use field <- decode.field(field_name, decode.dynamic)
  decode.success(field)
}

/// Decoder that extracts an array field
fn array_field_decoder(
  field_name: String,
) -> decode.Decoder(List(dynamic.Dynamic)) {
  use arr <- decode.field(field_name, decode.list(decode.dynamic))
  decode.success(arr)
}

/// Decoder that extracts a float field
fn float_field_decoder(field_name: String) -> decode.Decoder(Float) {
  use val <- decode.field(field_name, decode.float)
  decode.success(val)
}

/// Decoder that extracts an int field and converts to float
fn int_as_float_field_decoder(field_name: String) -> decode.Decoder(Float) {
  use val <- decode.field(field_name, decode.int)
  decode.success(int.to_float(val))
}

/// Decoder that extracts a string field
fn string_field_decoder(field_name: String) -> decode.Decoder(String) {
  use val <- decode.field(field_name, decode.string)
  decode.success(val)
}

/// Assert JSON object has a specific field
pub fn assert_has_field(
  json_str: String,
  field_name: String,
) -> Result(dynamic.Dynamic, AssertionError) {
  use parsed <- result.try(assert_valid_json(json_str))

  decode.run(parsed, field_decoder(field_name))
  |> result.map_error(fn(_) { FieldMissing(field_name) })
}

/// Assert JSON object has a field that is an array
pub fn assert_has_array(
  json_str: String,
  field_name: String,
) -> Result(List(dynamic.Dynamic), AssertionError) {
  use parsed <- result.try(assert_valid_json(json_str))

  decode.run(parsed, array_field_decoder(field_name))
  |> result.map_error(fn(_) { NotAnArray(field_name) })
}

/// Assert JSON object has a field with a positive number (int or float)
pub fn assert_positive_number(
  json_str: String,
  field_name: String,
) -> Result(Float, AssertionError) {
  use parsed <- result.try(assert_valid_json(json_str))

  // Try to decode as float first, then as int
  let number_result =
    decode.run(parsed, float_field_decoder(field_name))
    |> result.lazy_or(fn() {
      decode.run(parsed, int_as_float_field_decoder(field_name))
    })

  use value <- result.try(
    number_result
    |> result.map_error(fn(_) { FieldMissing(field_name) }),
  )

  case value >. 0.0 {
    True -> Ok(value)
    False -> Error(NotPositive(field_name, value))
  }
}

/// Assert JSON object has a field with a non-empty string
pub fn assert_non_empty_string(
  json_str: String,
  field_name: String,
) -> Result(String, AssertionError) {
  use parsed <- result.try(assert_valid_json(json_str))

  use value <- result.try(
    decode.run(parsed, string_field_decoder(field_name))
    |> result.map_error(fn(_) { FieldMissing(field_name) }),
  )

  let value = string.trim(value)

  case value {
    "" -> Error(EmptyString(field_name))
    _ -> Ok(value)
  }
}
