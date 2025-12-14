import gleeunit
import gleeunit/should
import meal_planner/fatsecret/core/errors

pub fn main() {
  gleeunit.main()
}

// Test error code conversions

pub fn code_from_int_known_codes_test() {
  errors.code_from_int(2) |> should.equal(errors.MissingOAuthParameter)
  errors.code_from_int(3) |> should.equal(errors.UnsupportedOAuthParameter)
  errors.code_from_int(4) |> should.equal(errors.InvalidSignatureMethod)
  errors.code_from_int(5) |> should.equal(errors.InvalidConsumerCredentials)
  errors.code_from_int(6) |> should.equal(errors.InvalidOrExpiredToken)
  errors.code_from_int(7) |> should.equal(errors.InvalidSignature)
  errors.code_from_int(8) |> should.equal(errors.InvalidNonce)
  errors.code_from_int(9) |> should.equal(errors.InvalidAccessToken)
  errors.code_from_int(13) |> should.equal(errors.InvalidMethod)
  errors.code_from_int(14) |> should.equal(errors.ApiUnavailable)
  errors.code_from_int(101) |> should.equal(errors.MissingRequiredParameter)
  errors.code_from_int(106) |> should.equal(errors.InvalidId)
  errors.code_from_int(107) |> should.equal(errors.InvalidSearchValue)
  errors.code_from_int(108) |> should.equal(errors.InvalidDate)
  errors.code_from_int(205) |> should.equal(errors.WeightDateTooFar)
  errors.code_from_int(206) |> should.equal(errors.WeightDateEarlier)
}

pub fn code_from_int_unknown_code_test() {
  errors.code_from_int(999) |> should.equal(errors.UnknownError(999))
}

pub fn code_to_int_round_trip_test() {
  errors.code_from_int(2)
  |> errors.code_to_int
  |> should.equal(2)

  errors.code_from_int(101)
  |> errors.code_to_int
  |> should.equal(101)

  errors.code_from_int(999)
  |> errors.code_to_int
  |> should.equal(999)
}

pub fn code_to_string_oauth_errors_test() {
  errors.code_to_string(errors.MissingOAuthParameter)
  |> should.equal("Missing OAuth Parameter")

  errors.code_to_string(errors.InvalidSignature)
  |> should.equal("Invalid Signature")

  errors.code_to_string(errors.InvalidConsumerCredentials)
  |> should.equal("Invalid Consumer Credentials")
}

pub fn code_to_string_api_errors_test() {
  errors.code_to_string(errors.MissingRequiredParameter)
  |> should.equal("Missing Required Parameter")

  errors.code_to_string(errors.InvalidId)
  |> should.equal("Invalid ID")

  errors.code_to_string(errors.ApiUnavailable)
  |> should.equal("API Unavailable")
}

pub fn code_to_string_unknown_error_test() {
  errors.code_to_string(errors.UnknownError(999))
  |> should.equal("Unknown Error (999)")
}

// Test error message formatting

pub fn error_to_string_api_error_test() {
  let error =
    errors.ApiError(
      errors.MissingRequiredParameter,
      "The parameter 'id' is required",
    )
  errors.error_to_string(error)
  |> should.equal(
    "Missing Required Parameter (code 101): The parameter 'id' is required",
  )
}

pub fn error_to_string_request_failed_test() {
  let error = errors.RequestFailed(500, "Internal Server Error")
  errors.error_to_string(error)
  |> should.equal("Request failed with status 500: Internal Server Error")
}

pub fn error_to_string_config_missing_test() {
  errors.error_to_string(errors.ConfigMissing)
  |> should.equal(
    "FatSecret configuration is missing. Set FATSECRET_CONSUMER_KEY and FATSECRET_CONSUMER_SECRET environment variables.",
  )
}

pub fn error_to_string_oauth_error_test() {
  let error = errors.OAuthError("Invalid signature")
  errors.error_to_string(error)
  |> should.equal("OAuth error: Invalid signature")
}

// Test error response parsing

pub fn parse_error_response_valid_test() {
  let json =
    "{\"error\": {\"code\": 101, \"message\": \"Missing required parameter\"}}"

  case errors.parse_error_response(json) {
    Ok(errors.ApiError(code, message)) -> {
      code |> should.equal(errors.MissingRequiredParameter)
      message |> should.equal("Missing required parameter")
    }
    _ -> should.fail()
  }
}

pub fn parse_error_response_unknown_code_test() {
  let json = "{\"error\": {\"code\": 999, \"message\": \"Unknown error\"}}"

  case errors.parse_error_response(json) {
    Ok(errors.ApiError(errors.UnknownError(999), "Unknown error")) -> Nil
    _ -> should.fail()
  }
}

pub fn parse_error_response_invalid_json_test() {
  let json = "{invalid json}"

  errors.parse_error_response(json)
  |> should.be_error()
}

pub fn parse_error_response_missing_fields_test() {
  let json = "{\"error\": {}}"

  errors.parse_error_response(json)
  |> should.be_error()
}

// Test error classification

pub fn is_recoverable_network_error_test() {
  errors.NetworkError("Connection timeout")
  |> errors.is_recoverable
  |> should.be_true()
}

pub fn is_recoverable_api_unavailable_test() {
  errors.ApiError(errors.ApiUnavailable, "Service temporarily unavailable")
  |> errors.is_recoverable
  |> should.be_true()
}

pub fn is_recoverable_server_error_test() {
  errors.RequestFailed(500, "Internal Server Error")
  |> errors.is_recoverable
  |> should.be_true()

  errors.RequestFailed(503, "Service Unavailable")
  |> errors.is_recoverable
  |> should.be_true()
}

pub fn is_recoverable_client_error_test() {
  errors.RequestFailed(400, "Bad Request")
  |> errors.is_recoverable
  |> should.be_false()

  errors.RequestFailed(404, "Not Found")
  |> errors.is_recoverable
  |> should.be_false()
}

pub fn is_recoverable_auth_error_test() {
  errors.ApiError(errors.InvalidSignature, "Signature mismatch")
  |> errors.is_recoverable
  |> should.be_false()
}

pub fn is_auth_error_oauth_error_test() {
  errors.OAuthError("Invalid token")
  |> errors.is_auth_error
  |> should.be_true()
}

pub fn is_auth_error_config_missing_test() {
  errors.ConfigMissing
  |> errors.is_auth_error
  |> should.be_true()
}

pub fn is_auth_error_all_oauth_codes_test() {
  errors.ApiError(errors.MissingOAuthParameter, "")
  |> errors.is_auth_error
  |> should.be_true()

  errors.ApiError(errors.InvalidSignature, "")
  |> errors.is_auth_error
  |> should.be_true()

  errors.ApiError(errors.InvalidConsumerCredentials, "")
  |> errors.is_auth_error
  |> should.be_true()

  errors.ApiError(errors.InvalidAccessToken, "")
  |> errors.is_auth_error
  |> should.be_true()
}

pub fn is_auth_error_non_auth_error_test() {
  errors.ApiError(errors.MissingRequiredParameter, "")
  |> errors.is_auth_error
  |> should.be_false()

  errors.NetworkError("Connection failed")
  |> errors.is_auth_error
  |> should.be_false()

  errors.RequestFailed(404, "Not Found")
  |> errors.is_auth_error
  |> should.be_false()
}
