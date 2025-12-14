/// FatSecret Weight API Tests
///
/// Tests for weight management functionality, including specific tests
/// for API errors 205 (date too far) and 206 (date earlier than existing).
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/core/errors

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Error Code Tests - Specific to Weight API
// ============================================================================

/// Test that error code 205 maps to WeightDateTooFar
pub fn error_205_weight_date_too_far_test() {
  errors.code_from_int(205)
  |> should.equal(errors.WeightDateTooFar)
}

/// Test that error code 206 maps to WeightDateEarlier
pub fn error_206_weight_date_earlier_test() {
  errors.code_from_int(206)
  |> should.equal(errors.WeightDateEarlier)
}

/// Test error 205 to int conversion
pub fn error_205_to_int_test() {
  errors.code_to_int(errors.WeightDateTooFar)
  |> should.equal(205)
}

/// Test error 206 to int conversion
pub fn error_206_to_int_test() {
  errors.code_to_int(errors.WeightDateEarlier)
  |> should.equal(206)
}

/// Test error 205 string representation
pub fn error_205_to_string_test() {
  errors.code_to_string(errors.WeightDateTooFar)
  |> should.equal("Weight Date Too Far in Future")
}

/// Test error 206 string representation
pub fn error_206_to_string_test() {
  errors.code_to_string(errors.WeightDateEarlier)
  |> should.equal("Weight Date Earlier Than Expected")
}

// ============================================================================
// Error Response Parsing Tests
// ============================================================================

/// Test parsing API error 205 from JSON response
pub fn parse_error_205_json_test() {
  let json =
    "{\"error\": {\"code\": 205, \"message\": \"Date is more than 2 days from today\"}}"

  case errors.parse_error_response(json) {
    Ok(errors.ApiError(code, message)) -> {
      code |> should.equal(errors.WeightDateTooFar)
      message |> should.equal("Date is more than 2 days from today")
    }
    _ -> should.fail()
  }
}

/// Test parsing API error 206 from JSON response
pub fn parse_error_206_json_test() {
  let json =
    "{\"error\": {\"code\": 206, \"message\": \"Cannot update earlier date\"}}"

  case errors.parse_error_response(json) {
    Ok(errors.ApiError(code, message)) -> {
      code |> should.equal(errors.WeightDateEarlier)
      message |> should.equal("Cannot update earlier date")
    }
    _ -> should.fail()
  }
}

// ============================================================================
// Error Message Formatting Tests
// ============================================================================

/// Test full error message for error 205
pub fn error_205_full_message_test() {
  let error =
    errors.ApiError(
      errors.WeightDateTooFar,
      "Date is more than 2 days from today",
    )

  errors.error_to_string(error)
  |> should.equal(
    "Weight Date Too Far in Future (code 205): Date is more than 2 days from today",
  )
}

/// Test full error message for error 206
pub fn error_206_full_message_test() {
  let error =
    errors.ApiError(
      errors.WeightDateEarlier,
      "Cannot update a date earlier than an existing weight entry",
    )

  errors.error_to_string(error)
  |> should.equal(
    "Weight Date Earlier Than Expected (code 206): Cannot update a date earlier than an existing weight entry",
  )
}

// ============================================================================
// Round-trip Tests
// ============================================================================

/// Test that error 205 survives round-trip conversion
pub fn error_205_round_trip_test() {
  errors.code_from_int(205)
  |> errors.code_to_int
  |> should.equal(205)
}

/// Test that error 206 survives round-trip conversion
pub fn error_206_round_trip_test() {
  errors.code_from_int(206)
  |> errors.code_to_int
  |> should.equal(206)
}
