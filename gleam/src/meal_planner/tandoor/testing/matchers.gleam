/// Request Matchers for Testing
///
/// This module provides helper functions for asserting HTTP request properties
/// in tests. Matchers can be combined to create complex assertions.
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/regexp
import gleam/string
import meal_planner/tandoor/core/http as tandoor_http

/// Request predicate type
pub type RequestPredicate =
  fn(tandoor_http.HttpRequest) -> Bool

// ============================================================================
// Basic Matchers
// ============================================================================

/// Assert request method matches
pub fn assert_method(
  request: tandoor_http.HttpRequest,
  method: http.Method,
) -> Bool {
  request.method == method
}

/// Assert request URL matches exactly
pub fn assert_url(request: tandoor_http.HttpRequest, url: String) -> Bool {
  request.url == url
}

/// Assert request URL matches a pattern (wildcard support)
pub fn assert_url_matches(
  request: tandoor_http.HttpRequest,
  pattern: String,
) -> Bool {
  // Simple wildcard matching - convert * to .*
  let regex_pattern = string.replace(pattern, "*", ".*")
  case regexp.from_string(regex_pattern) {
    Ok(re) -> regexp.check(re, request.url)
    Error(_) -> False
  }
}

/// Assert request has a specific header with value
pub fn assert_header(
  request: tandoor_http.HttpRequest,
  header_name: String,
  header_value: String,
) -> Bool {
  let lowercase_name = string.lowercase(header_name)
  list.any(request.headers, fn(header) {
    let #(name, value) = header
    string.lowercase(name) == lowercase_name && value == header_value
  })
}

/// Assert request has a specific header (any value)
pub fn assert_has_header(
  request: tandoor_http.HttpRequest,
  header_name: String,
) -> Bool {
  let lowercase_name = string.lowercase(header_name)
  list.any(request.headers, fn(header) {
    let #(name, _value) = header
    string.lowercase(name) == lowercase_name
  })
}

/// Assert request body matches exactly
pub fn assert_body(request: tandoor_http.HttpRequest, body: String) -> Bool {
  request.body == body
}

/// Assert request body contains a substring
pub fn assert_body_contains(
  request: tandoor_http.HttpRequest,
  substring: String,
) -> Bool {
  string.contains(request.body, substring)
}

/// Assert JSON body has a specific field value
pub fn assert_json_field(
  request: tandoor_http.HttpRequest,
  field: String,
  expected_value: String,
) -> Result(Nil, String) {
  case json.parse(request.body, using: decode.dynamic) {
    Ok(_json) -> {
      // For now, use simple string matching
      case string.contains(request.body, "\"" <> field <> "\"") {
        True ->
          case string.contains(request.body, expected_value) {
            True -> Ok(Nil)
            False -> Error("Field value mismatch")
          }
        False -> Error("Field not found in JSON")
      }
    }
    Error(_) -> Error("Invalid JSON body")
  }
}

/// Assert request matches a custom predicate
pub fn assert_matches(
  request: tandoor_http.HttpRequest,
  predicate: RequestPredicate,
) -> Bool {
  predicate(request)
}

// ============================================================================
// Predicate Builders
// ============================================================================

/// Create a method matcher predicate
pub fn method_is(method: http.Method) -> RequestPredicate {
  fn(req) { assert_method(req, method) }
}

/// Create a URL matcher predicate
pub fn url_is(url: String) -> RequestPredicate {
  fn(req) { assert_url(req, url) }
}

/// Create a URL pattern matcher predicate
pub fn url_matches(pattern: String) -> RequestPredicate {
  fn(req) { assert_url_matches(req, pattern) }
}

/// Create a header matcher predicate
pub fn has_header(header_name: String) -> RequestPredicate {
  fn(req) { assert_has_header(req, header_name) }
}

/// Create a header value matcher predicate
pub fn header_equals(
  header_name: String,
  header_value: String,
) -> RequestPredicate {
  fn(req) { assert_header(req, header_name, header_value) }
}

/// Create a body matcher predicate
pub fn body_is(body: String) -> RequestPredicate {
  fn(req) { assert_body(req, body) }
}

/// Create a body contains matcher predicate
pub fn body_contains(substring: String) -> RequestPredicate {
  fn(req) { assert_body_contains(req, substring) }
}

// ============================================================================
// Combinator Matchers
// ============================================================================

/// Combine multiple predicates with AND logic
pub fn all(predicates: List(RequestPredicate)) -> RequestPredicate {
  fn(req) { list.all(predicates, fn(pred) { pred(req) }) }
}

/// Combine multiple predicates with OR logic
pub fn any(predicates: List(RequestPredicate)) -> RequestPredicate {
  fn(req) { list.any(predicates, fn(pred) { pred(req) }) }
}

/// Negate a predicate
pub fn not(predicate: RequestPredicate) -> RequestPredicate {
  fn(req) { !predicate(req) }
}
