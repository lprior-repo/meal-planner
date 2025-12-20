/// Tests for Tandoor Error Types
///
/// Tests error_to_string conversions for all TandoorError variants.
/// Ensures human-readable error messages are generated correctly.
import gleeunit
import gleeunit/should
import meal_planner/tandoor/core/error

pub fn test_authentication_error_to_string() {
  error.AuthenticationError
  |> error.error_to_string
  |> should.equal("Authentication failed")
}

pub fn test_authorization_error_to_string() {
  error.AuthorizationError
  |> error.error_to_string
  |> should.equal("Authorization failed")
}

pub fn test_not_found_error_to_string() {
  error.NotFoundError("Recipe with ID 123 not found")
  |> error.error_to_string
  |> should.equal("Not found: Recipe with ID 123 not found")
}

pub fn test_bad_request_error_to_string() {
  error.BadRequestError("Invalid recipe data")
  |> error.error_to_string
  |> should.equal("Bad request: Invalid recipe data")
}

pub fn test_server_error_to_string() {
  error.ServerError(500, "Database connection failed")
  |> error.error_to_string
  |> should.equal("Server error (500): Database connection failed")
}

pub fn test_server_error_503_to_string() {
  error.ServerError(503, "Service unavailable")
  |> error.error_to_string
  |> should.equal("Server error (503): Service unavailable")
}

pub fn test_network_error_to_string() {
  error.NetworkError("Connection refused")
  |> error.error_to_string
  |> should.equal("Network error: Connection refused")
}

pub fn test_timeout_error_to_string() {
  error.TimeoutError
  |> error.error_to_string
  |> should.equal("Request timeout")
}

pub fn test_parse_error_to_string() {
  error.ParseError("Invalid JSON at line 5")
  |> error.error_to_string
  |> should.equal("Parse error: Invalid JSON at line 5")
}

pub fn test_unknown_error_to_string() {
  error.UnknownError("Something unexpected happened")
  |> error.error_to_string
  |> should.equal("Unknown error: Something unexpected happened")
}
