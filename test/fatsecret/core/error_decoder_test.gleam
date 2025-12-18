import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/core/errors.{
  ApiError, NoEntries, parse_error_response,
}

pub fn main() {
  gleeunit.main()
}

// Test all 17 error codes round-trip correctly through int conversion

pub fn error_code_2_round_trip_test() {
  let code = errors.MissingOAuthParameter
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_3_round_trip_test() {
  let code = errors.UnsupportedOAuthParameter
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_4_round_trip_test() {
  let code = errors.InvalidSignatureMethod
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_5_round_trip_test() {
  let code = errors.InvalidConsumerCredentials
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_6_round_trip_test() {
  let code = errors.InvalidOrExpiredToken
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_7_round_trip_test() {
  let code = errors.InvalidSignature
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_8_round_trip_test() {
  let code = errors.InvalidNonce
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_9_round_trip_test() {
  let code = errors.InvalidAccessToken
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_13_round_trip_test() {
  let code = errors.InvalidMethod
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_14_round_trip_test() {
  let code = errors.ApiUnavailable
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_101_round_trip_test() {
  let code = errors.MissingRequiredParameter
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_106_round_trip_test() {
  let code = errors.InvalidId
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_107_round_trip_test() {
  let code = errors.InvalidSearchValue
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_108_round_trip_test() {
  let code = errors.InvalidDate
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_205_round_trip_test() {
  let code = errors.WeightDateTooFar
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_206_round_trip_test() {
  let code = errors.WeightDateEarlier
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

pub fn error_code_207_round_trip_test() {
  let code = NoEntries
  code |> errors.code_to_int |> errors.code_from_int |> should.equal(code)
}

// Test parsing error code 207 from JSON
pub fn parse_error_207_no_entries_test() {
  let json = "{\"error\": {\"code\": 207, \"message\": \"No entries found\"}}"
  let result = parse_error_response(json)

  result
  |> should.be_ok
  |> should.equal(ApiError(NoEntries, "No entries found"))
}

// Test all error codes can be converted to string without panicking
pub fn error_code_207_to_string_test() {
  NoEntries
  |> errors.code_to_string
  |> should.equal("No Entries Found")
}

// Test error_to_string includes the error code
pub fn error_to_string_includes_code_207_test() {
  let error = ApiError(NoEntries, "Test message")
  let result = errors.error_to_string(error)

  result
  |> string.contains("207")
  |> should.be_true
  result
  |> string.contains("No Entries Found")
  |> should.be_true
  result
  |> string.contains("Test message")
  |> should.be_true
}
