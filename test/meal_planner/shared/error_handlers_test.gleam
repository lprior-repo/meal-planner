/// Tests for consolidated error-to-response handlers
///
/// Verifies that error types correctly map to HTTP status codes
/// and JSON response structures.
import gleeunit
import gleeunit/should
import meal_planner/errors
import meal_planner/shared/error_handlers

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// AppError Conversion Tests
// ============================================================================

pub fn validation_error_returns_400_test() {
  let error = errors.ValidationError("email", "Invalid email format")
  let response = error_handlers.app_error_to_response(error)

  response.status
  |> should.equal(400)
}

pub fn not_found_error_returns_404_test() {
  let error = errors.NotFoundError("recipe", "123")
  let response = error_handlers.app_error_to_response(error)

  response.status
  |> should.equal(404)
}

pub fn authentication_error_returns_401_test() {
  let error = errors.AuthenticationError("Invalid token")
  let response = error_handlers.app_error_to_response(error)

  response.status
  |> should.equal(401)
}

pub fn authorization_error_returns_403_test() {
  let error = errors.AuthorizationError("Insufficient permissions")
  let response = error_handlers.app_error_to_response(error)

  response.status
  |> should.equal(403)
}

pub fn database_error_returns_500_test() {
  let error = errors.DatabaseError("insert", "Connection failed")
  let response = error_handlers.app_error_to_response(error)

  response.status
  |> should.equal(500)
}

pub fn internal_error_returns_500_test() {
  let error = errors.InternalError("Unexpected condition")
  let response = error_handlers.app_error_to_response(error)

  response.status
  |> should.equal(500)
}

pub fn rate_limit_error_returns_429_test() {
  let error = errors.RateLimitError(60)
  let response = error_handlers.app_error_to_response(error)

  response.status
  |> should.equal(429)
}

pub fn bad_request_error_returns_400_test() {
  let error = errors.BadRequestError("Malformed JSON")
  let response = error_handlers.app_error_to_response(error)

  response.status
  |> should.equal(400)
}

pub fn service_error_returns_502_test() {
  let error = errors.ServiceError("fatsecret", "API unavailable")
  let response = error_handlers.app_error_to_response(error)

  response.status
  |> should.equal(502)
}

pub fn network_error_returns_502_test() {
  let error = errors.NetworkError("Connection timeout")
  let response = error_handlers.app_error_to_response(error)

  response.status
  |> should.equal(502)
}

// ============================================================================
// Specific Handler Tests
// ============================================================================

pub fn validation_error_to_response_test() {
  let response =
    error_handlers.validation_error_to_response("username", "Too short")

  response.status
  |> should.equal(400)
}

pub fn not_found_error_to_response_test() {
  let response = error_handlers.not_found_error_to_response("meal_plan", "456")

  response.status
  |> should.equal(404)
}

pub fn json_error_response_test() {
  let response =
    error_handlers.json_error_response(400, "INVALID_INPUT", "Bad data")

  response.status
  |> should.equal(400)
}

pub fn database_error_to_response_test() {
  let response =
    error_handlers.database_error_to_response("select", "Table not found")

  response.status
  |> should.equal(500)
}

// ============================================================================
// Multiple Validation Errors Test
// ============================================================================

pub fn multiple_validation_errors_to_response_test() {
  let errors_list = [
    #("email", "Invalid format"),
    #("password", "Too short"),
    #("name", "Required field"),
  ]

  let response = error_handlers.validation_errors_to_response(errors_list)

  response.status
  |> should.equal(400)
}

// ============================================================================
// HTTP Response Conversion Test
// ============================================================================

pub fn app_error_to_http_response_test() {
  let error = errors.ValidationError("age", "Must be positive")
  let response = error_handlers.app_error_to_http_response(error)

  response.status
  |> should.equal(400)
}
