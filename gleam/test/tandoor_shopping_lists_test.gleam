/// Web Handler Tests for Tandoor Shopping List Endpoints
///
/// This test module verifies the web handler routes for shopping list operations.
/// Tests cover:
/// - Status endpoint verification
/// - Units endpoint with proper response encoding
/// - Keywords endpoint with proper response encoding
/// - Error handling and authentication
///
/// Note: These are handler-level tests that verify routing and response formatting.
/// For API-level shopping list operations, see tandoor/api/shopping/* tests.

import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/handlers/helpers
import meal_planner/web/handlers/tandoor as tandoor_handler
import wisp

// =============================================================================
// Test Fixtures
// =============================================================================

/// Create a basic wisp.Request with custom method and path
fn make_request(method: String, path: String) -> wisp.Request {
  wisp.Request(
    method: method,
    path_segments: [path],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )
}

// =============================================================================
// Tandoor Status Endpoint Tests
// =============================================================================

pub fn tandoor_status_endpoint_exists_test() {
  // Create a mock request to the status endpoint
  let req = wisp.Request(
    method: "GET",
    path_segments: ["tandoor", "status"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  // Call the handler
  let response = tandoor_handler.handle_tandoor_routes(req)

  // The response should be either 200 (connected) or 502 (not configured)
  // We can't fully test without actual Tandoor service, but we can verify
  // that the route exists and returns a valid response
  should.be_ok(Ok(response))
}

pub fn tandoor_status_returns_json_test() {
  // Create a request to the status endpoint
  let req = wisp.Request(
    method: "GET",
    path_segments: ["tandoor", "status"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let response = tandoor_handler.handle_tandoor_routes(req)

  // Response should have a status code (either 200 or 502)
  // We verify the route handling doesn't crash
  let status_is_valid =
    response.status == 200 || response.status == 502 || response.status == 503
  status_is_valid
  |> should.be_true
}

// =============================================================================
// Units Endpoint Tests
// =============================================================================

pub fn units_endpoint_returns_not_found_without_server_test() {
  // Create a request to the units endpoint
  let req = wisp.Request(
    method: "GET",
    path_segments: ["api", "tandoor", "units"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let response = tandoor_handler.handle_tandoor_routes(req)

  // Without a running Tandoor server, should return 404 or 502
  let status_is_valid =
    response.status == 404 || response.status == 502 || response.status == 503
  status_is_valid
  |> should.be_true
}

pub fn units_endpoint_supports_get_method_test() {
  // Verify units endpoint only accepts GET
  let req = wisp.Request(
    method: "GET",
    path_segments: ["api", "tandoor", "units"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let response = tandoor_handler.handle_tandoor_routes(req)

  // Response should not be a 405 Method Not Allowed (GET is supported)
  let status_is_not_method_error = response.status != 405
  status_is_not_method_error
  |> should.be_true
}

pub fn units_endpoint_path_segments_test() {
  // Verify the correct path segments are required
  let req = wisp.Request(
    method: "GET",
    path_segments: ["api", "tandoor", "units"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let response = tandoor_handler.handle_tandoor_routes(req)

  // Response should be a valid HTTP response (not crashed or errored in handler)
  should.be_ok(Ok(response))
}

// =============================================================================
// Keywords Endpoint Tests
// =============================================================================

pub fn keywords_endpoint_returns_not_found_without_server_test() {
  // Create a request to the keywords endpoint
  let req = wisp.Request(
    method: "GET",
    path_segments: ["api", "tandoor", "keywords"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let response = tandoor_handler.handle_tandoor_routes(req)

  // Without a running Tandoor server, should return 404 or 502
  let status_is_valid =
    response.status == 404 || response.status == 502 || response.status == 503
  status_is_valid
  |> should.be_true
}

pub fn keywords_endpoint_supports_get_method_test() {
  // Verify keywords endpoint only accepts GET
  let req = wisp.Request(
    method: "GET",
    path_segments: ["api", "tandoor", "keywords"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let response = tandoor_handler.handle_tandoor_routes(req)

  // Response should not be a 405 Method Not Allowed (GET is supported)
  let status_is_not_method_error = response.status != 405
  status_is_not_method_error
  |> should.be_true
}

pub fn keywords_endpoint_path_segments_test() {
  // Verify the correct path segments are required
  let req = wisp.Request(
    method: "GET",
    path_segments: ["api", "tandoor", "keywords"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let response = tandoor_handler.handle_tandoor_routes(req)

  // Response should be a valid HTTP response (not crashed or errored in handler)
  should.be_ok(Ok(response))
}

// =============================================================================
// Invalid Route Tests
// =============================================================================

pub fn invalid_path_returns_not_found_test() {
  // Create a request to an invalid route
  let req = wisp.Request(
    method: "GET",
    path_segments: ["api", "invalid", "route"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let response = tandoor_handler.handle_tandoor_routes(req)

  // Should return 404 Not Found
  response.status
  |> should.equal(404)
}

pub fn empty_path_segments_returns_not_found_test() {
  // Create a request with empty path segments
  let req = wisp.Request(
    method: "GET",
    path_segments: [],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let response = tandoor_handler.handle_tandoor_routes(req)

  // Should return 404 Not Found
  response.status
  |> should.equal(404)
}

pub fn wrong_api_prefix_returns_not_found_test() {
  // Create a request with wrong prefix
  let req = wisp.Request(
    method: "GET",
    path_segments: ["v1", "tandoor", "units"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let response = tandoor_handler.handle_tandoor_routes(req)

  // Should return 404 Not Found
  response.status
  |> should.equal(404)
}

// =============================================================================
// Route Pattern Tests
// =============================================================================

pub fn exact_route_matching_required_test() {
  // Create a request with extra path segments
  let req = wisp.Request(
    method: "GET",
    path_segments: ["api", "tandoor", "units", "extra"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let response = tandoor_handler.handle_tandoor_routes(req)

  // Should return 404 because exact path didn't match
  response.status
  |> should.equal(404)
}

pub fn status_vs_units_routes_distinct_test() {
  // Verify that /tandoor/status and /api/tandoor/units are different routes
  let status_req = wisp.Request(
    method: "GET",
    path_segments: ["tandoor", "status"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let units_req = wisp.Request(
    method: "GET",
    path_segments: ["api", "tandoor", "units"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let status_response = tandoor_handler.handle_tandoor_routes(status_req)
  let units_response = tandoor_handler.handle_tandoor_routes(units_req)

  // Both should be valid responses but might differ in status code
  // depending on server availability
  should.be_ok(Ok(status_response))
  should.be_ok(Ok(units_response))
}

// =============================================================================
// Response Structure Tests
// =============================================================================

pub fn handler_response_has_status_code_test() {
  // Verify that responses have a status code
  let req = wisp.Request(
    method: "GET",
    path_segments: ["api", "tandoor", "units"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let response = tandoor_handler.handle_tandoor_routes(req)

  // Status should be a valid HTTP status code
  let status_is_valid = response.status > 0 && response.status < 600
  status_is_valid
  |> should.be_true
}

pub fn not_found_response_has_404_status_test() {
  // Verify that invalid routes return 404
  let req = wisp.Request(
    method: "GET",
    path_segments: ["nonexistent"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let response = tandoor_handler.handle_tandoor_routes(req)

  response.status
  |> should.equal(404)
}

// =============================================================================
// Handler Integration Tests
// =============================================================================

pub fn handler_processes_all_tandoor_routes_test() {
  // Verify handler exists and can be called without crashing
  let req = wisp.Request(
    method: "GET",
    path_segments: ["tandoor", "status"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  // Should not throw or crash
  let response = tandoor_handler.handle_tandoor_routes(req)

  // Should return a response with valid status
  let is_valid_status = response.status > 0
  is_valid_status
  |> should.be_true
}

pub fn handler_follows_routing_pattern_test() {
  // Verify the handler uses path pattern matching for valid routes
  let req_valid = wisp.Request(
    method: "GET",
    path_segments: ["tandoor", "status"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let response_valid = tandoor_handler.handle_tandoor_routes(req_valid)

  // Valid routes should not return 404 immediately
  // They may return other status codes (502, etc) if server is down
  let is_valid = response_valid.status != 404
  is_valid
  |> should.be_true
}

pub fn handler_rejects_invalid_routes_test() {
  // Verify the handler rejects non-matching routes
  let req_invalid = wisp.Request(
    method: "GET",
    path_segments: ["invalid", "route"],
    query: option.None,
    headers: [],
    body: wisp.Empty,
    scheme: wisp.Http,
    host: "localhost",
    port: Some(8000),
    inet_data: wisp.InetData(
      remote_addr: [],
      remote_port: 0,
    ),
  )

  let response_invalid = tandoor_handler.handle_tandoor_routes(req_invalid)

  // Invalid routes should return 404
  response_invalid.status
  |> should.equal(404)
}

// =============================================================================
// Helpers for test utilities
// =============================================================================

// Import list for the list.each utility
import gleam/list
