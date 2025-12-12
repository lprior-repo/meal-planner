import gleeunit
import gleeunit/should
import meal_planner/tandoor/client

// ============================================================================
// Test Configuration
// ============================================================================

pub fn test_default_config() {
  let config = client.default_config("http://localhost:8000", "test-token")

  config.base_url |> should.equal("http://localhost:8000")
  config.api_token |> should.equal("test-token")
  config.timeout_ms |> should.equal(10_000)
  config.retry_on_transient |> should.be_true()
  config.max_retries |> should.equal(3)
}

pub fn test_with_timeout() {
  let config =
    client.default_config("http://localhost:8000", "test-token")
    |> client.with_timeout(5_000)

  config.timeout_ms |> should.equal(5_000)
}

pub fn test_with_retry_config() {
  let config =
    client.default_config("http://localhost:8000", "test-token")
    |> client.with_retry_config(False, 5)

  config.retry_on_transient |> should.be_false()
  config.max_retries |> should.equal(5)
}

// ============================================================================
// Test Error Classification
// ============================================================================

pub fn test_is_transient_error_network() {
  let error = client.NetworkError("Connection refused")

  client.is_transient_error(error) |> should.be_true()
}

pub fn test_is_transient_error_timeout() {
  let error = client.TimeoutError

  client.is_transient_error(error) |> should.be_true()
}

pub fn test_is_transient_error_server_500() {
  let error = client.ServerError(500, "Internal server error")

  client.is_transient_error(error) |> should.be_true()
}

pub fn test_is_transient_error_server_502() {
  let error = client.ServerError(502, "Bad gateway")

  client.is_transient_error(error) |> should.be_true()
}

pub fn test_is_transient_error_server_503() {
  let error = client.ServerError(503, "Service unavailable")

  client.is_transient_error(error) |> should.be_true()
}

pub fn test_is_transient_error_server_504() {
  let error = client.ServerError(504, "Gateway timeout")

  client.is_transient_error(error) |> should.be_true()
}

pub fn test_is_not_transient_error_auth() {
  let error = client.AuthenticationError("Invalid token")

  client.is_transient_error(error) |> should.be_false()
}

pub fn test_is_not_transient_error_not_found() {
  let error = client.NotFoundError("Recipe not found")

  client.is_transient_error(error) |> should.be_false()
}

pub fn test_is_not_transient_error_bad_request() {
  let error = client.BadRequestError("Invalid JSON")

  client.is_transient_error(error) |> should.be_false()
}

pub fn test_is_not_transient_error_authorization() {
  let error = client.AuthorizationError("Forbidden")

  client.is_transient_error(error) |> should.be_false()
}

// ============================================================================
// Test Error Messages
// ============================================================================

pub fn test_error_to_string_authentication() {
  let error = client.AuthenticationError("Invalid credentials")
  let msg = client.error_to_string(error)

  msg |> should.contain("Authentication failed")
}

pub fn test_error_to_string_timeout() {
  let error = client.TimeoutError
  let msg = client.error_to_string(error)

  msg |> should.contain("timed out")
}

pub fn test_error_to_string_network() {
  let error = client.NetworkError("Connection refused")
  let msg = client.error_to_string(error)

  msg |> should.contain("Network error")
}

pub fn test_error_to_string_server_error() {
  let error = client.ServerError(503, "Service unavailable")
  let msg = client.error_to_string(error)

  msg |> should.contain("Server error")
}

pub fn test_error_to_string_parse_error() {
  let error = client.ParseError("Invalid JSON format")
  let msg = client.error_to_string(error)

  msg |> should.contain("Failed to parse response")
}

pub fn test_error_to_string_not_found() {
  let error = client.NotFoundError("Recipe not found")
  let msg = client.error_to_string(error)

  msg |> should.contain("Not found")
}

pub fn test_error_to_string_bad_request() {
  let error = client.BadRequestError("Missing required fields")
  let msg = client.error_to_string(error)

  msg |> should.contain("Bad request")
}

pub fn test_error_to_string_authorization() {
  let error = client.AuthorizationError("Insufficient permissions")
  let msg = client.error_to_string(error)

  msg |> should.contain("Not authorized")
}

// ============================================================================
// Test API Response Building
// ============================================================================

pub fn test_build_get_request() {
  let config = client.default_config("http://localhost:8000", "test-token")
  let result = client.build_get_request(config, "/api/recipe/", [])

  result |> should.be_ok()
}

pub fn test_build_post_request() {
  let config = client.default_config("http://localhost:8000", "test-token")
  let result = client.build_post_request(config, "/api/recipe/", "{}")

  result |> should.be_ok()
}

pub fn test_build_put_request() {
  let config = client.default_config("http://localhost:8000", "test-token")
  let result = client.build_put_request(config, "/api/recipe/123/", "{}")

  result |> should.be_ok()
}

pub fn test_build_patch_request() {
  let config = client.default_config("http://localhost:8000", "test-token")
  let result = client.build_patch_request(config, "/api/recipe/123/", "{}")

  result |> should.be_ok()
}

pub fn test_build_delete_request() {
  let config = client.default_config("http://localhost:8000", "test-token")
  let result = client.build_delete_request(config, "/api/recipe/123/")

  result |> should.be_ok()
}

pub fn test_build_get_request_with_query_params() {
  let config = client.default_config("http://localhost:8000", "test-token")
  let params = [#("limit", "10"), #("offset", "0")]
  let result = client.build_get_request(config, "/api/recipe/", params)

  result |> should.be_ok()
}
