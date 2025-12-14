/// Tests for Response Builders
///
/// This test suite validates response builder helpers for creating
/// mock HTTP responses in tests.
import gleeunit/should
import meal_planner/tandoor/testing/builders

/// Test: Build basic success response
pub fn build_success_response_test() {
  let response =
    builders.success()
    |> builders.with_body("{\"id\": 1, \"name\": \"Test\"}")

  response.status |> should.equal(200)
  response.body |> should.equal("{\"id\": 1, \"name\": \"Test\"}")
}

/// Test: Build created response (201)
pub fn build_created_response_test() {
  let response =
    builders.created()
    |> builders.with_body("{\"id\": 42}")

  response.status |> should.equal(201)
  response.body |> should.equal("{\"id\": 42}")
}

/// Test: Build no content response (204)
pub fn build_no_content_response_test() {
  let response = builders.no_content()

  response.status |> should.equal(204)
  response.body |> should.equal("")
}

/// Test: Build not found response (404)
pub fn build_not_found_response_test() {
  let response =
    builders.not_found()
    |> builders.with_body("{\"detail\": \"Recipe not found\"}")

  response.status |> should.equal(404)
  response.body |> should.equal("{\"detail\": \"Recipe not found\"}")
}

/// Test: Build bad request response (400)
pub fn build_bad_request_response_test() {
  let response =
    builders.bad_request()
    |> builders.with_body("{\"errors\": [\"name is required\"]}")

  response.status |> should.equal(400)
}

/// Test: Build unauthorized response (401)
pub fn build_unauthorized_response_test() {
  let response =
    builders.unauthorized()
    |> builders.with_body("{\"detail\": \"Invalid credentials\"}")

  response.status |> should.equal(401)
}

/// Test: Build forbidden response (403)
pub fn build_forbidden_response_test() {
  let response =
    builders.forbidden()
    |> builders.with_body("{\"detail\": \"Access denied\"}")

  response.status |> should.equal(403)
}

/// Test: Build server error response (500)
pub fn build_server_error_response_test() {
  let response =
    builders.server_error()
    |> builders.with_body("{\"detail\": \"Internal server error\"}")

  response.status |> should.equal(500)
}

/// Test: Build response with custom status
pub fn build_custom_status_response_test() {
  let response =
    builders.with_status(418)
    |> builders.with_body("I'm a teapot")

  response.status |> should.equal(418)
}

/// Test: Build response with headers
pub fn build_response_with_headers_test() {
  let response =
    builders.success()
    |> builders.with_header("Content-Type", "application/json")
    |> builders.with_header("X-Request-ID", "abc123")
    |> builders.with_body("{}")

  // Verify headers are set
  builders.has_header(response, "Content-Type") |> should.be_true()
  builders.has_header(response, "X-Request-ID") |> should.be_true()
  builders.get_header(response, "Content-Type")
  |> should.equal("application/json")
}

/// Test: Build JSON response with automatic headers
pub fn build_json_response_test() {
  let response =
    builders.json(200, "{\"name\": \"Test\"}")

  response.status |> should.equal(200)
  response.body |> should.equal("{\"name\": \"Test\"}")
  builders.has_header(response, "Content-Type") |> should.be_true()
  builders.get_header(response, "Content-Type")
  |> should.equal("application/json")
}

/// Test: Build paginated response
pub fn build_paginated_response_test() {
  let response =
    builders.paginated(
      count: 100,
      next: "http://api/recipes?page=2",
      previous: "",
      results: "[{\"id\": 1}, {\"id\": 2}]",
    )

  response.status |> should.equal(200)
  builders.assert_body_contains(response, "\"count\": 100") |> should.be_true()
  builders.assert_body_contains(response, "\"next\"") |> should.be_true()
}

/// Test: Build recipe response from fixture
pub fn build_recipe_from_fixture_test() {
  let response =
    builders.recipe_response(
      id: 1,
      name: "Chocolate Cake",
      servings: 8,
    )

  response.status |> should.equal(200)
  builders.assert_body_contains(response, "Chocolate Cake") |> should.be_true()
  builders.assert_body_contains(response, "\"servings\": 8") |> should.be_true()
}

/// Test: Build food response from fixture
pub fn build_food_from_fixture_test() {
  let response =
    builders.food_response(
      id: 42,
      name: "Tomato",
    )

  response.status |> should.equal(200)
  builders.assert_body_contains(response, "Tomato") |> should.be_true()
  builders.assert_body_contains(response, "\"id\": 42") |> should.be_true()
}

/// Test: Chain multiple builder operations
pub fn chain_builder_operations_test() {
  let response =
    builders.success()
    |> builders.with_header("Content-Type", "application/json")
    |> builders.with_header("Cache-Control", "no-cache")
    |> builders.with_body("{\"status\": \"ok\"}")

  response.status |> should.equal(200)
  builders.has_header(response, "Content-Type") |> should.be_true()
  builders.has_header(response, "Cache-Control") |> should.be_true()
  response.body |> should.equal("{\"status\": \"ok\"}")
}
