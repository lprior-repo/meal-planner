/// Response Builders for Testing
///
/// This module provides builder functions for creating HTTP responses in tests.
/// Builders support fluent API for easy response construction.
import gleam/list
import gleam/string
import meal_planner/tandoor/core/http.{type HttpResponse, HttpResponse}

// ============================================================================
// Basic Response Builders
// ============================================================================

/// Create a success response (200)
pub fn success() -> HttpResponse {
  HttpResponse(status: 200, headers: [], body: "")
}

/// Create a created response (201)
pub fn created() -> HttpResponse {
  HttpResponse(status: 201, headers: [], body: "")
}

/// Create a no content response (204)
pub fn no_content() -> HttpResponse {
  HttpResponse(status: 204, headers: [], body: "")
}

/// Create a bad request response (400)
pub fn bad_request() -> HttpResponse {
  HttpResponse(status: 400, headers: [], body: "")
}

/// Create an unauthorized response (401)
pub fn unauthorized() -> HttpResponse {
  HttpResponse(status: 401, headers: [], body: "")
}

/// Create a forbidden response (403)
pub fn forbidden() -> HttpResponse {
  HttpResponse(status: 403, headers: [], body: "")
}

/// Create a not found response (404)
pub fn not_found() -> HttpResponse {
  HttpResponse(status: 404, headers: [], body: "")
}

/// Create a server error response (500)
pub fn server_error() -> HttpResponse {
  HttpResponse(status: 500, headers: [], body: "")
}

/// Create a response with custom status code
pub fn with_status(status: Int) -> HttpResponse {
  HttpResponse(status: status, headers: [], body: "")
}

// ============================================================================
// Builder Methods (Fluent API)
// ============================================================================

/// Set response body
pub fn with_body(response: HttpResponse, body: String) -> HttpResponse {
  HttpResponse(..response, body: body)
}

/// Add a header to response
pub fn with_header(
  response: HttpResponse,
  name: String,
  value: String,
) -> HttpResponse {
  HttpResponse(
    ..response,
    headers: list.append(response.headers, [
      #(name, value),
    ]),
  )
}

// ============================================================================
// JSON Response Builders
// ============================================================================

/// Create a JSON response with automatic Content-Type header
pub fn json(status: Int, body: String) -> HttpResponse {
  HttpResponse(
    status: status,
    headers: [
      #("Content-Type", "application/json"),
    ],
    body: body,
  )
}

/// Create a paginated response
pub fn paginated(
  count count: Int,
  next next: String,
  previous previous: String,
  results results: String,
) -> HttpResponse {
  let next_value = case next {
    "" -> "null"
    url -> "\"" <> url <> "\""
  }

  let previous_value = case previous {
    "" -> "null"
    url -> "\"" <> url <> "\""
  }

  let body =
    "{"
    <> "\"count\": "
    <> string.inspect(count)
    <> ", "
    <> "\"next\": "
    <> next_value
    <> ", "
    <> "\"previous\": "
    <> previous_value
    <> ", "
    <> "\"results\": "
    <> results
    <> "}"

  json(200, body)
}

// ============================================================================
// Domain-Specific Builders
// ============================================================================

/// Create a recipe response
pub fn recipe_response(
  id id: Int,
  name name: String,
  servings servings: Int,
) -> HttpResponse {
  let body =
    "{"
    <> "\"id\": "
    <> string.inspect(id)
    <> ", "
    <> "\"name\": \""
    <> name
    <> "\", "
    <> "\"servings\": "
    <> string.inspect(servings)
    <> ", "
    <> "\"description\": \"Test recipe\", "
    <> "\"instructions\": \"Test instructions\""
    <> "}"

  json(200, body)
}

/// Create a food response
pub fn food_response(id id: Int, name name: String) -> HttpResponse {
  let body =
    "{"
    <> "\"id\": "
    <> string.inspect(id)
    <> ", "
    <> "\"name\": \""
    <> name
    <> "\""
    <> "}"

  json(200, body)
}

// ============================================================================
// Response Inspection Helpers
// ============================================================================

/// Check if response has a header
pub fn has_header(response: HttpResponse, header_name: String) -> Bool {
  let lowercase_name = string.lowercase(header_name)
  list.any(response.headers, fn(header) {
    let #(name, _value) = header
    string.lowercase(name) == lowercase_name
  })
}

/// Get header value from response
pub fn get_header(response: HttpResponse, header_name: String) -> String {
  let lowercase_name = string.lowercase(header_name)
  case
    list.find(response.headers, fn(header) {
      let #(name, _value) = header
      string.lowercase(name) == lowercase_name
    })
  {
    Ok(#(_name, value)) -> value
    Error(_) -> ""
  }
}

/// Check if response body contains substring
pub fn assert_body_contains(response: HttpResponse, substring: String) -> Bool {
  string.contains(response.body, substring)
}
