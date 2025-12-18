/// Integration tests for the FatSecret HTTP client
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/core/config
import meal_planner/fatsecret/core/errors
import meal_planner/fatsecret/core/http
import meal_planner/fatsecret/core/oauth

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Configuration Tests
// ============================================================================

pub fn config_creation_test() {
  let cfg = config.new("test_key", "test_secret")
  should.equal(cfg.consumer_key, "test_key")
  should.equal(cfg.consumer_secret, "test_secret")
}

pub fn config_api_host_test() {
  let cfg = config.new("key", "secret")
  config.get_api_host(cfg)
  |> should.equal("platform.fatsecret.com")
}

// ============================================================================
// OAuth Tests
// ============================================================================

pub fn oauth_nonce_generation_test() {
  let nonce = oauth.generate_nonce()
  // Nonce should be 32 hex characters (16 bytes = 32 hex chars)
  should.be_true(string.length(nonce) == 32)
}

pub fn oauth_encode_unreserved_test() {
  oauth.oauth_encode("AZaz09-._~")
  |> should.equal("AZaz09-._~")
}

pub fn oauth_encode_space_test() {
  oauth.oauth_encode("hello world")
  |> should.equal("hello%20world")
}

// ============================================================================
// Error Tests
// ============================================================================

pub fn error_code_conversion_test() {
  let code = errors.code_from_int(101)
  code |> should.equal(errors.MissingRequiredParameter)

  errors.code_to_int(code)
  |> should.equal(101)
}

pub fn error_to_string_test() {
  let error = errors.ApiError(errors.InvalidSignature, "Bad signature")
  errors.error_to_string(error)
  |> should.equal("Invalid Signature (code 7): Bad signature")
}

pub fn error_parse_response_test() {
  let json = "{\"error\":{\"code\":101,\"message\":\"Missing parameter\"}}"

  case errors.parse_error_response(json) {
    Ok(errors.ApiError(code, message)) -> {
      should.equal(code, errors.MissingRequiredParameter)
      should.equal(message, "Missing parameter")
    }
    _ -> should.fail()
  }
}

pub fn error_recoverable_test() {
  should.be_true(errors.is_recoverable(errors.NetworkError("timeout")))
  should.be_false(errors.is_recoverable(errors.ParseError("bad json")))
}

// ============================================================================
// HTTP Client Tests (without actual network calls)
// ============================================================================

pub fn check_api_error_with_error_response_test() {
  let json = "{\"error\":{\"code\":106,\"message\":\"Invalid ID\"}}"

  case http.check_api_error(json) {
    Error(errors.ApiError(code, message)) -> {
      should.equal(code, errors.InvalidId)
      should.equal(message, "Invalid ID")
    }
    _ -> should.fail()
  }
}

pub fn check_api_error_with_success_response_test() {
  let json = "{\"foods\":{\"food\":[]}}"

  case http.check_api_error(json) {
    Ok(body) -> should.equal(body, json)
    Error(_) -> should.fail()
  }
}
