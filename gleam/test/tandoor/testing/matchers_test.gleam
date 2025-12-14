/// Tests for Request Matchers
///
/// This test suite validates request matching helpers for asserting
/// HTTP request structure in tests.
import gleam/http
import gleeunit/should
import meal_planner/tandoor/core/http.{HttpRequest}
import meal_planner/tandoor/testing/matchers

/// Test: Match request method
pub fn match_method_test() {
  let request = HttpRequest(method: http.Get, url: "/api/recipe", headers: [], body: "")

  matchers.assert_method(request, http.Get) |> should.be_true()
  matchers.assert_method(request, http.Post) |> should.be_false()
}

/// Test: Match request URL
pub fn match_url_test() {
  let request = HttpRequest(method: http.Get, url: "/api/recipe/42", headers: [], body: "")

  matchers.assert_url(request, "/api/recipe/42") |> should.be_true()
  matchers.assert_url(request, "/api/recipe/1") |> should.be_false()
}

/// Test: Match URL with pattern
pub fn match_url_pattern_test() {
  let request = HttpRequest(method: http.Get, url: "/api/recipe/42", headers: [], body: "")

  matchers.assert_url_matches(request, "/api/recipe/*") |> should.be_true()
  matchers.assert_url_matches(request, "/api/food/*") |> should.be_false()
}

/// Test: Match request header
pub fn match_header_test() {
  let request =
    HttpRequest(
      method: http.Get,
      url: "/api/recipe",
      headers: [
        #("Authorization", "Bearer token123"),
        #("Content-Type", "application/json"),
      ],
      body: "",
    )

  matchers.assert_header(request, "Authorization", "Bearer token123")
  |> should.be_true()

  matchers.assert_header(request, "Content-Type", "application/json")
  |> should.be_true()

  matchers.assert_header(request, "Authorization", "Bearer wrong")
  |> should.be_false()
}

/// Test: Match request has header
pub fn match_has_header_test() {
  let request =
    HttpRequest(
      method: http.Get,
      url: "/api/recipe",
      headers: [#("Authorization", "Bearer token123")],
      body: "",
    )

  matchers.assert_has_header(request, "Authorization") |> should.be_true()
  matchers.assert_has_header(request, "X-Custom-Header") |> should.be_false()
}

/// Test: Match request body
pub fn match_body_test() {
  let request =
    HttpRequest(
      method: http.Post,
      url: "/api/recipe",
      headers: [],
      body: "{\"name\": \"Test\"}",
    )

  matchers.assert_body(request, "{\"name\": \"Test\"}") |> should.be_true()
  matchers.assert_body(request, "{\"name\": \"Other\"}") |> should.be_false()
}

/// Test: Match body contains string
pub fn match_body_contains_test() {
  let request =
    HttpRequest(
      method: http.Post,
      url: "/api/recipe",
      headers: [],
      body: "{\"name\": \"Chocolate Cake\", \"servings\": 8}",
    )

  matchers.assert_body_contains(request, "Chocolate Cake") |> should.be_true()
  matchers.assert_body_contains(request, "servings") |> should.be_true()
  matchers.assert_body_contains(request, "Vanilla") |> should.be_false()
}

/// Test: Match JSON body field
pub fn match_json_field_test() {
  let request =
    HttpRequest(
      method: http.Post,
      url: "/api/recipe",
      headers: [],
      body: "{\"name\": \"Test Recipe\", \"servings\": 4}",
    )

  matchers.assert_json_field(request, "name", "Test Recipe") |> should.be_ok()
  matchers.assert_json_field(request, "servings", "4") |> should.be_ok()
  matchers.assert_json_field(request, "missing", "value") |> should.be_error()
}

/// Test: Match request with custom predicate
pub fn match_custom_predicate_test() {
  let request =
    HttpRequest(
      method: http.Post,
      url: "/api/recipe",
      headers: [#("Content-Length", "42")],
      body: "{\"test\": true}",
    )

  // Custom matcher: POST requests with JSON content type
  let is_json_post = fn(req: HttpRequest) {
    req.method == http.Post
    && matchers.assert_has_header(req, "Content-Type")
  }

  matchers.assert_matches(request, is_json_post) |> should.be_true()
}

/// Test: Combine multiple matchers (AND)
pub fn combine_matchers_and_test() {
  let request =
    HttpRequest(
      method: http.Post,
      url: "/api/recipe",
      headers: [#("Authorization", "Bearer token")],
      body: "{\"name\": \"Test\"}",
    )

  matchers.all([
    matchers.method_is(http.Post),
    matchers.url_is("/api/recipe"),
    matchers.has_header("Authorization"),
  ])
  |> matchers.assert_matches(request, _)
  |> should.be_true()
}

/// Test: Combine multiple matchers (OR)
pub fn combine_matchers_or_test() {
  let request =
    HttpRequest(method: http.Get, url: "/api/recipe/1", headers: [], body: "")

  matchers.any([
    matchers.method_is(http.Get),
    matchers.method_is(http.Post),
  ])
  |> matchers.assert_matches(request, _)
  |> should.be_true()
}
