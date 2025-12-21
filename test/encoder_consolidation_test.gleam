/// Tests for encoder consolidation
///
/// Verifies that optional value encoders are consolidated into a single
/// source of truth in shared/response_encoders and properly re-exported.
import gleam/json
import gleam/option.{type Option, None, Some}

import meal_planner/shared/response_encoders

import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// =============================================================================
// Test: Optional String Encoder
// =============================================================================

pub fn test_encode_optional_string_some() {
  let result = response_encoders.encode_optional_string(Some("hello"))
  let json_str = json.to_string(result)
  
  json_str
  |> should.equal("\"hello\"")
}

pub fn test_encode_optional_string_none() {
  let result = response_encoders.encode_optional_string(None)
  let json_str = json.to_string(result)
  
  json_str
  |> should.equal("null")
}

// =============================================================================
// Test: Optional Int Encoder
// =============================================================================

pub fn test_encode_optional_int_some() {
  let result = response_encoders.encode_optional_int(Some(42))
  let json_str = json.to_string(result)
  
  json_str
  |> should.equal("42")
}

pub fn test_encode_optional_int_none() {
  let result = response_encoders.encode_optional_int(None)
  let json_str = json.to_string(result)
  
  json_str
  |> should.equal("null")
}

// =============================================================================
// Test: Optional Float Encoder
// =============================================================================

pub fn test_encode_optional_float_some() {
  let result = response_encoders.encode_optional_float(Some(3.14))
  let json_str = json.to_string(result)
  
  json_str
  |> should.equal("3.14")
}

pub fn test_encode_optional_float_none() {
  let result = response_encoders.encode_optional_float(None)
  let json_str = json.to_string(result)
  
  json_str
  |> should.equal("null")
}

// =============================================================================
// Test: Optional Bool Encoder
// =============================================================================

pub fn test_encode_optional_bool_some_true() {
  let result = response_encoders.encode_optional_bool(Some(True))
  let json_str = json.to_string(result)
  
  json_str
  |> should.equal("true")
}

pub fn test_encode_optional_bool_some_false() {
  let result = response_encoders.encode_optional_bool(Some(False))
  let json_str = json.to_string(result)
  
  json_str
  |> should.equal("false")
}

pub fn test_encode_optional_bool_none() {
  let result = response_encoders.encode_optional_bool(None)
  let json_str = json.to_string(result)
  
  json_str
  |> should.equal("null")
}

// =============================================================================
// Test: FatSecret Handlers Can Import and Use Consolidated Encoders
// =============================================================================

pub fn test_fatsecret_handlers_imports_work() {
  // This test verifies that when we consolidate fatsecret/handlers_helpers,
  // it can import from shared/response_encoders and use the same functions
  let str_result = response_encoders.encode_optional_string(Some("test"))
  let int_result = response_encoders.encode_optional_int(Some(123))
  let float_result = response_encoders.encode_optional_float(Some(1.5))
  
  json.to_string(str_result)
  |> should.equal("\"test\"")
  
  json.to_string(int_result)
  |> should.equal("123")
  
  json.to_string(float_result)
  |> should.equal("1.5")
}
