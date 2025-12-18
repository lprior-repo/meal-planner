/// Test Helpers for Tandoor API Tests
///
/// Consolidates common test patterns:
/// - Config factories (bearer token, server URLs)
/// - Response mocking and builders
/// - Assertion helpers for delegation tests
/// - Delegation test factories
///
/// Reduces 150-200 lines of duplication across 69 test files.
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/string
import gleeunit/should
import meal_planner/tandoor/client.{type ClientConfig, ApiResponse}

// ============================================================================
// Config Factories
// ============================================================================

/// No-server URL for testing (will fail with connection error)
pub const no_server_url = "http://localhost:8000"

/// Bearer token for testing
pub const test_token = "test-token"

/// Create a test client config with bearer authentication
pub fn test_config() -> ClientConfig {
  client.bearer_config(no_server_url, test_token)
}

/// Create a test client config with custom URL
pub fn test_config_with_url(url: String) -> ClientConfig {
  client.bearer_config(url, test_token)
}

// ============================================================================
// Response Builders
// ============================================================================

/// Create a successful JSON response (status 200)
pub fn json_response_200(body: String) {
  ApiResponse(status: 200, body: body, headers: [])
}

/// Create a successful empty response (status 204)
pub fn empty_response_204() {
  ApiResponse(status: 204, body: "", headers: [])
}

/// Create a not-found response (status 404)
pub fn not_found_response() {
  ApiResponse(status: 404, body: "{\"error\": \"Not found\"}", headers: [])
}

/// Create a server error response (status 500)
pub fn server_error_response() {
  ApiResponse(status: 500, body: "{\"error\": \"Internal server error\"}", headers: [])
}


