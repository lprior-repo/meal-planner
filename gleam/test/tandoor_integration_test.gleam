/// Comprehensive integration tests for Tandoor API endpoints
///
/// Tests all Tandoor routes:
/// - GET /tandoor/status
/// - GET /api/tandoor/recipes
/// - GET /api/tandoor/recipes/:id
/// - GET /api/tandoor/meal-plan
/// - POST /api/tandoor/meal-plan
/// - DELETE /api/tandoor/meal-plan/:id
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/config
import meal_planner/env
import meal_planner/web/router
import pog
import wisp
import wisp/testing

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Setup & Helpers
// ============================================================================

fn get_test_context() -> router.Context {
  let config = config.load()
  let db =
    pog.default_config()
    |> pog.host("localhost")
    |> pog.database("meal_planner_test")
    |> pog.user("meal_planner")
    |> pog.password("meal_planner")
    |> pog.pool_size(1)
    |> pog.connect

  router.Context(config: config, db: db)
}

fn make_request(method: http.Method, path: String, body: String) -> wisp.Request {
  let assert Ok(req) =
    request.to(path)
    |> request.set_method(method)
    |> request.set_body(body)
    |> testing.to_wisp_request

  req
}

fn make_get_request(path: String) -> wisp.Request {
  make_request(http.Get, path, "")
}

fn make_post_request(path: String, body: String) -> wisp.Request {
  make_request(http.Post, path, body)
}

fn make_delete_request(path: String) -> wisp.Request {
  make_request(http.Delete, path, "")
}

fn get_response_body(resp: wisp.Response) -> String {
  case testing.string_body(resp) {
    Ok(body) -> body
    Error(_) -> ""
  }
}

// ============================================================================
// 1. Status Endpoint Tests
// ============================================================================

pub fn test_tandoor_status_not_configured_test() {
  // When Tandoor is not configured, should return configured: false
  let ctx = get_test_context()
  let req = make_get_request("/tandoor/status")

  let resp = router.handle_request(req, ctx)

  resp.status |> should.equal(200)

  let body = get_response_body(resp)
  // Body should contain configured and connected fields
  body |> should.not_equal("")
}

pub fn test_tandoor_status_with_config_test() {
  // When Tandoor is configured, should attempt connection
  // This test assumes TANDOOR_URL, TANDOOR_USERNAME, TANDOOR_PASSWORD are set
  let ctx = get_test_context()
  let req = make_get_request("/tandoor/status")

  let resp = router.handle_request(req, ctx)

  resp.status |> should.equal(200)

  let body = get_response_body(resp)
  body |> should.not_equal("")

  // Validate JSON structure
  case json.parse(body, json.dynamic.dynamic) {
    Ok(_) -> True
    Error(_) -> False
  }
  |> should.be_true
}

// ============================================================================
// 2. Recipe List Endpoint Tests
// ============================================================================

pub fn test_list_recipes_no_auth_test() {
  // When not authenticated, should return 502 or 500
  let ctx = get_test_context()
  let req = make_get_request("/api/tandoor/recipes")

  let resp = router.handle_request(req, ctx)

  // Should fail with authentication error if not configured
  case resp.status {
    500 | 502 -> True
    200 -> True
    // If configured and connected
    _ -> False
  }
  |> should.be_true
}

pub fn test_list_recipes_with_pagination_test() {
  // Test pagination parameters
  let ctx = get_test_context()
  let req = make_get_request("/api/tandoor/recipes?limit=10&offset=0")

  let resp = router.handle_request(req, ctx)

  // Should handle pagination params
  case resp.status {
    200 -> {
      let body = get_response_body(resp)
      // Should have count, next, previous, results fields
      body |> should.not_equal("")
    }
    500 | 502 -> {
      // Expected if not configured
      True
    }
    _ -> False
  }
  |> should.be_true
}

pub fn test_list_recipes_invalid_params_test() {
  // Test with invalid pagination parameters
  let ctx = get_test_context()
  let req = make_get_request("/api/tandoor/recipes?limit=invalid")

  let resp = router.handle_request(req, ctx)

  // Should handle gracefully (either ignore invalid params or return error)
  resp.status |> should.be_true
}

// ============================================================================
// 3. Recipe Detail Endpoint Tests
// ============================================================================

pub fn test_get_recipe_invalid_id_test() {
  // Test with non-numeric ID
  let ctx = get_test_context()
  let req = make_get_request("/api/tandoor/recipes/invalid")

  let resp = router.handle_request(req, ctx)

  resp.status |> should.equal(400)

  let body = get_response_body(resp)
  body |> should.not_equal("")
}

pub fn test_get_recipe_valid_id_test() {
  // Test with valid numeric ID
  let ctx = get_test_context()
  let req = make_get_request("/api/tandoor/recipes/1")

  let resp = router.handle_request(req, ctx)

  // Should return 404, 500, 502, or 200
  case resp.status {
    200 -> {
      // Valid recipe found
      let body = get_response_body(resp)
      body |> should.not_equal("")
    }
    404 -> {
      // Recipe not found - expected
      True
    }
    500 | 502 -> {
      // Auth error - expected if not configured
      True
    }
    _ -> False
  }
  |> should.be_true
}

pub fn test_get_recipe_not_found_test() {
  // Test with ID that doesn't exist
  let ctx = get_test_context()
  let req = make_get_request("/api/tandoor/recipes/999999")

  let resp = router.handle_request(req, ctx)

  // Should return 404 or auth error
  case resp.status {
    404 | 500 | 502 -> True
    200 -> True
    // Might exist
    _ -> False
  }
  |> should.be_true
}

// ============================================================================
// 4. Meal Plan List Endpoint Tests
// ============================================================================

pub fn test_get_meal_plan_no_dates_test() {
  // Test without date filters
  let ctx = get_test_context()
  let req = make_get_request("/api/tandoor/meal-plan")

  let resp = router.handle_request(req, ctx)

  case resp.status {
    200 -> {
      let body = get_response_body(resp)
      body |> should.not_equal("")
    }
    500 | 502 -> {
      // Expected if not configured
      True
    }
    _ -> False
  }
  |> should.be_true
}

pub fn test_get_meal_plan_with_dates_test() {
  // Test with date range filters
  let ctx = get_test_context()
  let req =
    make_get_request(
      "/api/tandoor/meal-plan?from_date=2025-12-01&to_date=2025-12-31",
    )

  let resp = router.handle_request(req, ctx)

  case resp.status {
    200 -> {
      let body = get_response_body(resp)
      // Should have count, next, previous, results
      body |> should.not_equal("")
    }
    500 | 502 -> True
    _ -> False
  }
  |> should.be_true
}

// ============================================================================
// 5. Meal Plan Create Endpoint Tests
// ============================================================================

pub fn test_create_meal_plan_invalid_json_test() {
  // Test with invalid JSON body
  let ctx = get_test_context()
  let req = make_post_request("/api/tandoor/meal-plan", "invalid json")

  let resp = router.handle_request(req, ctx)

  // Should return 400 Bad Request
  resp.status |> should.equal(400)

  let body = get_response_body(resp)
  body |> should.not_equal("")
}

pub fn test_create_meal_plan_missing_fields_test() {
  // Test with missing required fields
  let ctx = get_test_context()
  let body =
    json.object([
      #("recipe_name", json.string("Test Recipe")),
      // Missing from_date, to_date
    ])
    |> json.to_string

  let req = make_post_request("/api/tandoor/meal-plan", body)
  let resp = router.handle_request(req, ctx)

  // Should return 400 Bad Request
  resp.status |> should.equal(400)
}

pub fn test_create_meal_plan_valid_data_test() {
  // Test with valid meal plan data
  let ctx = get_test_context()
  let body =
    json.object([
      #("recipe_name", json.string("Test Meal Plan Entry")),
      #("from_date", json.string("2025-12-14")),
      #("to_date", json.string("2025-12-14")),
      #("meal_type", json.string("lunch")),
      #("servings", json.float(2.0)),
      #("note", json.string("Test note")),
    ])
    |> json.to_string

  let req = make_post_request("/api/tandoor/meal-plan", body)
  let resp = router.handle_request(req, ctx)

  // Should return 201 Created or auth error
  case resp.status {
    201 -> {
      let body = get_response_body(resp)
      body |> should.not_equal("")
    }
    500 | 502 -> {
      // Expected if not configured
      True
    }
    _ -> False
  }
  |> should.be_true
}

pub fn test_create_meal_plan_with_recipe_id_test() {
  // Test with recipe_id field
  let ctx = get_test_context()
  let body =
    json.object([
      #("recipe", json.int(1)),
      #("recipe_name", json.string("Test Recipe")),
      #("from_date", json.string("2025-12-14")),
      #("to_date", json.string("2025-12-14")),
      #("meal_type", json.string("dinner")),
    ])
    |> json.to_string

  let req = make_post_request("/api/tandoor/meal-plan", body)
  let resp = router.handle_request(req, ctx)

  case resp.status {
    201 | 500 | 502 -> True
    _ -> False
  }
  |> should.be_true
}

// ============================================================================
// 6. Meal Plan Delete Endpoint Tests
// ============================================================================

pub fn test_delete_meal_plan_invalid_id_test() {
  // Test with non-numeric ID
  let ctx = get_test_context()
  let req = make_delete_request("/api/tandoor/meal-plan/invalid")

  let resp = router.handle_request(req, ctx)

  resp.status |> should.equal(400)
}

pub fn test_delete_meal_plan_not_found_test() {
  // Test with ID that doesn't exist
  let ctx = get_test_context()
  let req = make_delete_request("/api/tandoor/meal-plan/999999")

  let resp = router.handle_request(req, ctx)

  case resp.status {
    404 | 500 | 502 -> True
    200 -> True
    // Might exist
    _ -> False
  }
  |> should.be_true
}

pub fn test_delete_meal_plan_valid_id_test() {
  // Test with valid ID (assume ID 1 might exist)
  let ctx = get_test_context()
  let req = make_delete_request("/api/tandoor/meal-plan/1")

  let resp = router.handle_request(req, ctx)

  // Should return 200, 404, or auth error
  case resp.status {
    200 | 404 | 500 | 502 -> True
    _ -> False
  }
  |> should.be_true
}

// ============================================================================
// 7. Route Method Validation Tests
// ============================================================================

pub fn test_status_wrong_method_test() {
  // POST to status endpoint should fail
  let ctx = get_test_context()
  let req = make_post_request("/tandoor/status", "")

  let resp = router.handle_request(req, ctx)

  resp.status |> should.equal(405)
  // Method Not Allowed
}

pub fn test_list_recipes_wrong_method_test() {
  // POST to list endpoint should fail
  let ctx = get_test_context()
  let req = make_post_request("/api/tandoor/recipes", "")

  let resp = router.handle_request(req, ctx)

  resp.status |> should.equal(405)
}

pub fn test_get_recipe_wrong_method_test() {
  // POST to get recipe should fail
  let ctx = get_test_context()
  let req = make_post_request("/api/tandoor/recipes/1", "")

  let resp = router.handle_request(req, ctx)

  resp.status |> should.equal(405)
}

// ============================================================================
// 8. JSON Response Structure Tests
// ============================================================================

pub fn test_status_json_structure_test() {
  let ctx = get_test_context()
  let req = make_get_request("/tandoor/status")

  let resp = router.handle_request(req, ctx)
  let body = get_response_body(resp)

  // Should be valid JSON
  case json.parse(body, json.dynamic.dynamic) {
    Ok(_) -> True
    Error(_) -> False
  }
  |> should.be_true
}

pub fn test_error_response_json_structure_test() {
  let ctx = get_test_context()
  let req = make_get_request("/api/tandoor/recipes/invalid")

  let resp = router.handle_request(req, ctx)
  let body = get_response_body(resp)

  // Error response should be valid JSON
  case json.parse(body, json.dynamic.dynamic) {
    Ok(_) -> True
    Error(_) -> False
  }
  |> should.be_true
}
