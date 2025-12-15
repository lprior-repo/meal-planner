/// Standardized HTTP response builders for Wisp endpoints
///
/// This module provides idiomatic Wisp response helpers for:
/// - Error responses (400, 401, 403, 404, 415, 500, 502)
/// - Success responses (200, 201, 204)
/// - JSON responses with proper Content-Type headers
/// - Empty responses with appropriate status codes
///
/// All responses use wisp.json_response for proper JSON handling
/// and include appropriate status codes and Content-Type headers.
import gleam/int
import gleam/json
import wisp

// ============================================================================
// Success Responses (2xx)
// ============================================================================

/// Create a 200 OK JSON response
///
/// Usage:
/// ```gleam
/// json_ok(json.object([#("status", json.string("ok"))]))
/// ```
pub fn json_ok(body: json.Json) -> wisp.Response {
  wisp.json_response(json.to_string(body), 200)
}

/// Create a 201 Created JSON response
///
/// Usage:
/// ```gleam
/// json_created(json.object([#("id", json.int(123))]))
/// ```
pub fn json_created(body: json.Json) -> wisp.Response {
  wisp.json_response(json.to_string(body), 201)
}

/// Create a 204 No Content response (empty body)
pub fn no_content() -> wisp.Response {
  wisp.response(204)
  |> wisp.set_body(wisp.Empty)
}

// ============================================================================
// Client Error Responses (4xx)
// ============================================================================

/// Create a 400 Bad Request response
///
/// Usage:
/// ```gleam
/// bad_request("Invalid input: expected integer")
/// ```
pub fn bad_request(message: String) -> wisp.Response {
  error_json(400, "Bad Request", message)
}

/// Create a 401 Unauthorized response
///
/// Usage:
/// ```gleam
/// unauthorized("Missing or invalid authentication token")
/// ```
pub fn unauthorized(message: String) -> wisp.Response {
  error_json(401, "Unauthorized", message)
}

/// Create a 403 Forbidden response
///
/// Usage:
/// ```gleam
/// forbidden("You do not have permission to access this resource")
/// ```
pub fn forbidden(message: String) -> wisp.Response {
  error_json(403, "Forbidden", message)
}

/// Create a 404 Not Found response
///
/// Usage:
/// ```gleam
/// not_found("Recipe with ID 123 not found")
/// ```
pub fn not_found(message: String) -> wisp.Response {
  error_json(404, "Not Found", message)
}

/// Create a 409 Conflict response
///
/// Usage:
/// ```gleam
/// conflict("Resource with this ID already exists")
/// ```
pub fn conflict(message: String) -> wisp.Response {
  error_json(409, "Conflict", message)
}

/// Create a 415 Unsupported Media Type response
///
/// Usage:
/// ```gleam
/// unsupported_media_type("Content-Type must be application/json")
/// ```
pub fn unsupported_media_type(message: String) -> wisp.Response {
  error_json(415, "Unsupported Media Type", message)
}

// ============================================================================
// Server Error Responses (5xx)
// ============================================================================

/// Create a 500 Internal Server Error response
///
/// Usage:
/// ```gleam
/// internal_error("Unexpected database error")
/// ```
pub fn internal_error(message: String) -> wisp.Response {
  error_json(500, "Internal Server Error", message)
}

/// Create a 501 Not Implemented response
///
/// Usage:
/// ```gleam
/// not_implemented("Feature coming soon")
/// ```
pub fn not_implemented(message: String) -> wisp.Response {
  error_json(501, "Not Implemented", message)
}

/// Create a 502 Bad Gateway response (external service failure)
///
/// Usage:
/// ```gleam
/// bad_gateway("FatSecret API returned HTTP 502: Service Unavailable")
/// ```
pub fn bad_gateway(message: String) -> wisp.Response {
  error_json(502, "Bad Gateway", message)
}

/// Create a 503 Service Unavailable response
///
/// Usage:
/// ```gleam
/// service_unavailable("Database connection pool exhausted")
/// ```
pub fn service_unavailable(message: String) -> wisp.Response {
  error_json(503, "Service Unavailable", message)
}

// ============================================================================
// Generic Error Response Builder
// ============================================================================

/// Build a JSON error response with status code, error type, and message
///
/// All error responses use this consistent format:
/// ```json
/// {
///   "error": "Bad Request",
///   "message": "Invalid input: expected integer"
/// }
/// ```
fn error_json(status: Int, error: String, message: String) -> wisp.Response {
  let body =
    json.object([
      #("error", json.string(error)),
      #("message", json.string(message)),
    ])
    |> json.to_string

  wisp.json_response(body, status)
}

// ============================================================================
// Special Response Builders
// ============================================================================

/// Create a paginated response wrapper
///
/// Usage:
/// ```gleam
/// let items = json.array([...])
/// paginated_response(items, 100, 0, 20)  // total, offset, limit
/// ```
pub fn paginated_response(
  items: json.Json,
  total: Int,
  offset: Int,
  limit: Int,
) -> wisp.Response {
  let body =
    json.object([
      #("count", json.int(total)),
      #("offset", json.int(offset)),
      #("limit", json.int(limit)),
      #("results", items),
    ])
    |> json.to_string

  wisp.json_response(body, 200)
}

/// Create a validation error response with field details
///
/// Usage:
/// ```gleam
/// validation_error([
///   #("email", "Invalid email format"),
///   #("password", "Must be at least 8 characters"),
/// ])
/// ```
pub fn validation_error(errors: List(#(String, String))) -> wisp.Response {
  let error_array =
    json.array(
      errors,
      fn(field_error) {
        json.object([
          #("field", json.string(field_error.0)),
          #("message", json.string(field_error.1)),
        ])
      },
    )

  let body =
    json.object([
      #("error", json.string("Validation Error")),
      #("errors", error_array),
    ])
    |> json.to_string

  wisp.json_response(body, 400)
}

/// Create a success response with optional metadata
///
/// Usage:
/// ```gleam
/// success_with_meta(
///   data: json.object([#("id", json.int(123))]),
///   meta: [#("created_at", json.string("2024-01-01T00:00:00Z"))],
/// )
/// ```
pub fn success_with_meta(
  data: json.Json,
  meta: List(#(String, json.Json)),
) -> wisp.Response {
  let body =
    json.object([#("data", data), #("meta", json.object(meta))])
    |> json.to_string

  wisp.json_response(body, 200)
}