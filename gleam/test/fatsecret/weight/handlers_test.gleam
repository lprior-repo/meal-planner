/// HTTP handler tests for FatSecret Weight API
///
/// Tests for POST /api/fatsecret/weight and GET /api/fatsecret/weight/month/:year/:month
/// These tests validate handler behavior with JSON body parsing, auth validation, and error handling

import gleam/json
import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/fatsecret/weight/handlers
import wisp

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// POST /api/fatsecret/weight - Update Weight Handler Tests
// ============================================================================

/// Test: POST /api/fatsecret/weight with valid body returns 200/500
/// (Returns 500 because service isn't configured in test, but handler structure is correct)
pub fn handle_update_weight_post_allowed_test() {
  let req =
    wisp.test_request(wisp.Post, "/api/fatsecret/weight")

  let response = handlers.update_weight(req, wisp.test_connection())

  // Should not be 405 Method Not Allowed
  response.status
  |> should.not_equal(405)
}

/// Test: POST with missing weight_kg returns 400
pub fn handle_update_weight_missing_weight_returns_400_test() {
  let req =
    wisp.test_request(wisp.Post, "/api/fatsecret/weight")

  let response = handlers.update_weight(req, wisp.test_connection())

  // Should return 400 for invalid/missing JSON
  response.status
  |> should.equal(400)
}

/// Test: PUT method not allowed on /api/fatsecret/weight
pub fn handle_update_weight_put_not_allowed_test() {
  let req =
    wisp.test_request(wisp.Put, "/api/fatsecret/weight")

  let response = handlers.update_weight(req, wisp.test_connection())

  // Should return 405 Method Not Allowed
  response.status
  |> should.equal(405)
}

/// Test: GET method not allowed on /api/fatsecret/weight
pub fn handle_update_weight_get_not_allowed_test() {
  let req =
    wisp.test_request(wisp.Get, "/api/fatsecret/weight")

  let response = handlers.update_weight(req, wisp.test_connection())

  // Should return 405 Method Not Allowed
  response.status
  |> should.equal(405)
}

/// Test: Success response includes JSON content type
pub fn handle_update_weight_json_response_test() {
  let req =
    wisp.test_request(wisp.Post, "/api/fatsecret/weight")

  let response = handlers.update_weight(req, wisp.test_connection())

  // Check Content-Type header is set to JSON
  let content_type_header =
    list.find(response.headers, fn(h) { h.0 == "content-type" })

  case content_type_header {
    Ok(#(_, "application/json")) -> should.be_true(True)
    _ -> should.be_true(False)
  }
}

/// Test: Error response is valid JSON
pub fn handle_update_weight_error_json_test() {
  let req =
    wisp.test_request(wisp.Post, "/api/fatsecret/weight")

  let response = handlers.update_weight(req, wisp.test_connection())

  // Response should be valid JSON even for errors
  case wisp.as_text(response) {
    Ok(body) -> {
      case json.parse(body, json.object([])) {
        Ok(_) -> should.be_true(True)
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// GET /api/fatsecret/weight/month/:year/:month - Get Monthly Summary Tests
// ============================================================================

/// Test: GET month summary with valid year/month
pub fn handle_get_weight_month_valid_params_test() {
  let req =
    wisp.test_request(wisp.Get, "/api/fatsecret/weight/month/2024/12")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "2024", "12")

  // Should get past parameter validation
  response.status
  |> should.not_equal(400)
}

/// Test: GET month with invalid month (13) returns 400
pub fn handle_get_weight_month_invalid_month_13_test() {
  let req =
    wisp.test_request(wisp.Get, "/api/fatsecret/weight/month/2024/13")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "2024", "13")

  // Should return 400 for invalid month
  response.status
  |> should.equal(400)
}

/// Test: GET month with month 0 returns 400
pub fn handle_get_weight_month_invalid_month_0_test() {
  let req =
    wisp.test_request(wisp.Get, "/api/fatsecret/weight/month/2024/0")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "2024", "0")

  // Should return 400 for invalid month
  response.status
  |> should.equal(400)
}

/// Test: GET month with negative month returns 400
pub fn handle_get_weight_month_invalid_month_negative_test() {
  let req =
    wisp.test_request(wisp.Get, "/api/fatsecret/weight/month/2024/-1")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "2024", "-1")

  // Should return 400 for invalid month
  response.status
  |> should.equal(400)
}

/// Test: GET month with non-numeric year returns 400
pub fn handle_get_weight_month_non_numeric_year_test() {
  let req =
    wisp.test_request(wisp.Get, "/api/fatsecret/weight/month/abcd/12")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "abcd", "12")

  // Should return 400 for invalid year
  response.status
  |> should.equal(400)
}

/// Test: GET month with non-numeric month returns 400
pub fn handle_get_weight_month_non_numeric_month_test() {
  let req =
    wisp.test_request(wisp.Get, "/api/fatsecret/weight/month/2024/dec")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "2024", "dec")

  // Should return 400 for invalid month
  response.status
  |> should.equal(400)
}

/// Test: GET month with January
pub fn handle_get_weight_month_january_test() {
  let req =
    wisp.test_request(wisp.Get, "/api/fatsecret/weight/month/2024/1")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "2024", "1")

  // Should get past parameter validation (month 1 is valid)
  response.status
  |> should.not_equal(400)
}

/// Test: GET month with December
pub fn handle_get_weight_month_december_test() {
  let req =
    wisp.test_request(wisp.Get, "/api/fatsecret/weight/month/2024/12")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "2024", "12")

  // Should get past parameter validation (month 12 is valid)
  response.status
  |> should.not_equal(400)
}

/// Test: POST method not allowed on /api/fatsecret/weight/month
pub fn handle_get_weight_month_post_not_allowed_test() {
  let req =
    wisp.test_request(wisp.Post, "/api/fatsecret/weight/month/2024/12")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "2024", "12")

  // Should return 405 Method Not Allowed
  response.status
  |> should.equal(405)
}

/// Test: PUT method not allowed on /api/fatsecret/weight/month
pub fn handle_get_weight_month_put_not_allowed_test() {
  let req =
    wisp.test_request(wisp.Put, "/api/fatsecret/weight/month/2024/12")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "2024", "12")

  // Should return 405 Method Not Allowed
  response.status
  |> should.equal(405)
}

/// Test: DELETE method not allowed on /api/fatsecret/weight/month
pub fn handle_get_weight_month_delete_not_allowed_test() {
  let req =
    wisp.test_request(wisp.Delete, "/api/fatsecret/weight/month/2024/12")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "2024", "12")

  // Should return 405 Method Not Allowed
  response.status
  |> should.equal(405)
}

/// Test: Success response includes JSON content type
pub fn handle_get_weight_month_json_content_type_test() {
  let req =
    wisp.test_request(wisp.Get, "/api/fatsecret/weight/month/2024/12")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "2024", "12")

  // Check Content-Type header is set to JSON
  let content_type_header =
    list.find(response.headers, fn(h) { h.0 == "content-type" })

  case content_type_header {
    Ok(#(_, "application/json")) -> should.be_true(True)
    _ -> should.be_true(False)
  }
}

/// Test: Error response is valid JSON
pub fn handle_get_weight_month_error_json_test() {
  let req =
    wisp.test_request(wisp.Get, "/api/fatsecret/weight/month/2024/13")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "2024", "13")

  // Response should be valid JSON
  case wisp.as_text(response) {
    Ok(body) -> {
      case json.parse(body, json.object([])) {
        Ok(_) -> should.be_true(True)
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

/// Test: GET month summary with leading zeros in month
pub fn handle_get_weight_month_leading_zeros_test() {
  let req =
    wisp.test_request(wisp.Get, "/api/fatsecret/weight/month/2024/01")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "2024", "01")

  // Should parse correctly (01 as month 1)
  response.status
  |> should.not_equal(400)
}

/// Test: GET month summary with different year ranges
pub fn handle_get_weight_month_year_2020_test() {
  let req =
    wisp.test_request(wisp.Get, "/api/fatsecret/weight/month/2020/6")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "2020", "6")

  // Should get past parameter validation
  response.status
  |> should.not_equal(400)
}

/// Test: GET month with year 2030 (future)
pub fn handle_get_weight_month_year_2030_test() {
  let req =
    wisp.test_request(wisp.Get, "/api/fatsecret/weight/month/2030/6")

  let response =
    handlers.get_weight_month(req, wisp.test_connection(), "2030", "6")

  // Should accept future years in parameter validation (service layer handles date validation)
  response.status
  |> should.not_equal(400)
}
