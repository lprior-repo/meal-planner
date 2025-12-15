/// HTTP handler tests for FatSecret Exercise API
///
/// Tests for GET /api/fatsecret/exercises/:id and related endpoints
/// These tests validate handler behavior with mock requests and responses

import gleam/json
import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/exercise/handlers
import meal_planner/fatsecret/exercise/types
import wisp

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// GET /api/fatsecret/exercises/:id - Handler Tests
// ============================================================================

/// Test: GET /api/fatsecret/exercises/:id returns 200 with exercise data
pub fn handle_get_exercise_returns_200_test() {
  let exercise_id = "1"
  
  // Create a mock request
  let req = wisp.test_request(wisp.Get, "/api/fatsecret/exercises/" <> exercise_id)
  
  // Handler should return a successful response
  let response = handlers.handle_get_exercise(req, exercise_id)
  
  response.status
  |> should.equal(200)
}

/// Test: GET /api/fatsecret/exercises/:id response has valid JSON
pub fn handle_get_exercise_json_format_test() {
  let exercise_id = "1"
  let req = wisp.test_request(wisp.Get, "/api/fatsecret/exercises/" <> exercise_id)
  
  let response = handlers.handle_get_exercise(req, exercise_id)
  
  // Status should be 200
  response.status |> should.equal(200)
  
  // Body should contain JSON
  case wisp.as_text(response) {
    Ok(body) -> {
      // Body should be parseable JSON
      case json.parse(body, json.object([])) {
        Ok(_) -> should.be_true(True)
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Authorization Header Tests
// ============================================================================

/// Test: Request without Authorization header returns 401
pub fn handle_exercise_entries_without_auth_returns_401_test() {
  let req = wisp.test_request(wisp.Get, "/api/fatsecret/exercise-entries")
  
  // Should return 401 Unauthorized
  let response = handlers.handle_get_exercise_entries(req, wisp.test_connection())
  
  response.status
  |> should.equal(401)
}

/// Test: Authorization header extraction and validation
pub fn handle_exercise_entries_with_bearer_token_test() {
  let req = 
    wisp.test_request(wisp.Get, "/api/fatsecret/exercise-entries")
    |> wisp.set_body_header(req.headers, "Authorization", "Bearer test_token_12345")
  
  // Note: This will fail with auth since we don't have a real token
  // but we're testing the handler accepts the header
  let response = handlers.handle_get_exercise_entries(req, wisp.test_connection())
  
  // Should get past auth check (status won't be 401 for missing auth header)
  response.status
  |> should.not_equal(401)
}

// ============================================================================
// Query Parameter Tests
// ============================================================================

/// Test: Missing required query parameter returns 400
pub fn handle_exercise_entries_missing_date_param_test() {
  let req = wisp.test_request(wisp.Get, "/api/fatsecret/exercise-entries")
    |> wisp.set_body_header(req.headers, "Authorization", "Bearer test_token")
  
  let response = handlers.handle_get_exercise_entries(req, wisp.test_connection())
  
  // Should return 400 for missing query parameter
  response.status
  |> should.equal(400)
}

// ============================================================================
// Method Validation Tests
// ============================================================================

/// Test: POST to /api/fatsecret/exercise-entries is allowed
pub fn handle_create_exercise_entry_post_allowed_test() {
  let req = wisp.test_request(wisp.Post, "/api/fatsecret/exercise-entries")
    |> wisp.set_body_header(req.headers, "Authorization", "Bearer test_token")
  
  let response = handlers.handle_create_exercise_entry(req, wisp.test_connection())
  
  // Should not be 405 Method Not Allowed
  response.status
  |> should.not_equal(405)
}

/// Test: PUT to exercise-entries/:id is allowed
pub fn handle_edit_exercise_entry_put_allowed_test() {
  let req = wisp.test_request(wisp.Put, "/api/fatsecret/exercise-entries/123456")
    |> wisp.set_body_header(req.headers, "Authorization", "Bearer test_token")
  
  let response = handlers.handle_edit_exercise_entry(req, wisp.test_connection(), "123456")
  
  // Should not be 405 Method Not Allowed
  response.status
  |> should.not_equal(405)
}

/// Test: DELETE to exercise-entries/:id is allowed
pub fn handle_delete_exercise_entry_delete_allowed_test() {
  let req = wisp.test_request(wisp.Delete, "/api/fatsecret/exercise-entries/123456")
    |> wisp.set_body_header(req.headers, "Authorization", "Bearer test_token")
  
  let response = handlers.handle_delete_exercise_entry(req, wisp.test_connection(), "123456")
  
  // Should not be 405 Method Not Allowed
  response.status
  |> should.not_equal(405)
}

// ============================================================================
// Month Summary Tests
// ============================================================================

/// Test: GET month summary with valid year/month
pub fn handle_get_exercise_month_valid_params_test() {
  let req = wisp.test_request(wisp.Get, "/api/fatsecret/exercise-entries/month/2024/12")
    |> wisp.set_body_header(req.headers, "Authorization", "Bearer test_token")
  
  let response = handlers.handle_get_exercise_month(req, wisp.test_connection(), "2024", "12")
  
  // Should get past parameter validation
  response.status
  |> should.not_equal(400)
}

/// Test: GET month summary with invalid month returns 400
pub fn handle_get_exercise_month_invalid_month_test() {
  let req = wisp.test_request(wisp.Get, "/api/fatsecret/exercise-entries/month/2024/13")
  
  let response = handlers.handle_get_exercise_month(req, wisp.test_connection(), "2024", "13")
  
  // Should return 400 for invalid month
  response.status
  |> should.equal(400)
}

/// Test: GET month summary with month 0 returns 400
pub fn handle_get_exercise_month_zero_month_test() {
  let req = wisp.test_request(wisp.Get, "/api/fatsecret/exercise-entries/month/2024/0")
  
  let response = handlers.handle_get_exercise_month(req, wisp.test_connection(), "2024", "0")
  
  // Should return 400 for invalid month
  response.status
  |> should.equal(400)
}

/// Test: GET month summary with non-numeric year returns 400
pub fn handle_get_exercise_month_non_numeric_year_test() {
  let req = wisp.test_request(wisp.Get, "/api/fatsecret/exercise-entries/month/abc/12")
  
  let response = handlers.handle_get_exercise_month(req, wisp.test_connection(), "abc", "12")
  
  // Should return 400 for invalid year
  response.status
  |> should.equal(400)
}

// ============================================================================
// Response Content Type Tests
// ============================================================================

/// Test: Successful response includes JSON content type
pub fn handle_get_exercise_json_content_type_test() {
  let req = wisp.test_request(wisp.Get, "/api/fatsecret/exercises/1")
  
  let response = handlers.handle_get_exercise(req, "1")
  
  // Check Content-Type header is set to JSON
  let content_type_header =
    list.find(response.headers, fn(h) { h.0 == "content-type" })
  
  case content_type_header {
    Ok(#(_, "application/json")) -> should.be_true(True)
    _ -> should.be_true(False)
  }
}

/// Test: Error response includes JSON content type
pub fn handle_exercise_error_json_content_type_test() {
  let req = wisp.test_request(wisp.Get, "/api/fatsecret/exercise-entries")
  
  let response = handlers.handle_get_exercise_entries(req, wisp.test_connection())
  
  // Check that response is JSON even for error
  case wisp.as_text(response) {
    Ok(body) -> {
      // Body should be valid JSON
      case json.parse(body, json.object([])) {
        Ok(_) -> should.be_true(True)
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}
