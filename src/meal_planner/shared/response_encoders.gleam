//// Common response encoding functions for JSON API responses.
////
//// Consolidates duplicate JSON encoding logic across multiple handlers:
//// - FatSecret API handlers
//// - Tandoor API handlers
//// - Web API handlers
////
//// Provides reusable encoders for:
//// - Pagination metadata
//// - List responses with pagination
//// - Optional values (null handling)
//// - Simple success/error responses

import gleam/json
import gleam/option.{type Option, None, Some}

// =============================================================================
// Optional Value Encoders
// =============================================================================

/// Encode an optional String to JSON (null if None)
///
/// Used across all handler modules to consistently handle optional strings.
/// Replaces repeated case statements in 20+ handler functions.
pub fn encode_optional_string(opt: Option(String)) -> json.Json {
  case opt {
    Some(s) -> json.string(s)
    None -> json.null()
  }
}

/// Encode an optional Int to JSON (null if None)
///
/// Used across all handler modules to consistently handle optional integers.
/// Replaces repeated case statements in 15+ handler functions.
pub fn encode_optional_int(opt: Option(Int)) -> json.Json {
  case opt {
    Some(i) -> json.int(i)
    None -> json.null()
  }
}

/// Encode an optional Float to JSON (null if None)
///
/// Used across all handler modules to consistently handle optional floats.
/// Replaces repeated case statements in 10+ handler functions.
pub fn encode_optional_float(opt: Option(Float)) -> json.Json {
  case opt {
    Some(f) -> json.float(f)
    None -> json.null()
  }
}

/// Encode an optional Bool to JSON (null if None)
///
/// Consistency helper for optional boolean values.
pub fn encode_optional_bool(opt: Option(Bool)) -> json.Json {
  case opt {
    Some(b) -> json.bool(b)
    None -> json.null()
  }
}

// =============================================================================
// Pagination Response Encoders
// =============================================================================

/// Build a paginated response with count and results
///
/// Standard format used across Tandoor API handlers for list endpoints.
/// Combines results array with pagination metadata.
///
/// # Arguments
/// * `results` - json.Json array of items
/// * `count` - Total count of items (Int)
/// * `next` - URL for next page (Option(String), null if none)
/// * `previous` - URL for previous page (Option(String), null if none)
///
/// # Returns
/// ```json
/// {
///   "count": 123,
///   "next": "http://...",
///   "previous": "http://...",
///   "results": [...]
/// }
/// ```
pub fn paginated_response(
  results: json.Json,
  count: Int,
  next: Option(String),
  previous: Option(String),
) -> json.Json {
  json.object([
    #("count", json.int(count)),
    #("next", encode_optional_string(next)),
    #("previous", encode_optional_string(previous)),
    #("results", results),
  ])
}

/// Build a simple list response with item count
///
/// Used for endpoints that don't support pagination.
/// Replaces inline json.object calls in 8+ handlers.
///
/// # Arguments
/// * `items` - json.Json array of items
/// * `count` - Total count of items (Int)
///
/// # Returns
/// ```json
/// {
///   "count": 42,
///   "items": [...]
/// }
/// ```
pub fn list_response(items: json.Json, count: Int) -> json.Json {
  json.object([#("count", json.int(count)), #("items", items)])
}

// =============================================================================
// Success/Error Response Encoders
// =============================================================================

/// Encode a success response with data
///
/// Standard format for successful API responses returning data.
/// Used across 25+ handler functions.
pub fn success_with_data(data: json.Json) -> json.Json {
  json.object([
    #("success", json.bool(True)),
    #("data", data),
  ])
}

/// Encode a simple success message
///
/// Used for endpoints that don't return data (create, update, delete operations).
/// Consolidates duplicated success message encoding across 20+ handlers.
pub fn success_message(message: String) -> json.Json {
  json.object([
    #("success", json.bool(True)),
    #("message", json.string(message)),
  ])
}

/// Encode an error response
///
/// Standard error format: single "error" field with message.
/// Used across all error paths in handlers.
pub fn error_message(message: String) -> json.Json {
  json.object([#("error", json.string(message))])
}

/// Encode a detailed error response with code
///
/// Extended error format for API errors that need codes.
/// Maps to HTTP status codes for consistency.
pub fn error_with_code(code: String, message: String) -> json.Json {
  json.object([
    #("error", json.string(code)),
    #("message", json.string(message)),
  ])
}

// =============================================================================
// Array Response Encoders
// =============================================================================

/// Encode array of items (raw list without wrapper)
///
/// Used for simple array responses without pagination metadata.
/// Replaces 15+ instances of inline json.array() calls.
///
/// # Arguments
/// * `items` - List of items to encode
/// * `encode_fn` - Function to encode each item to json.Json
pub fn encode_array(items: List(a), encode_fn: fn(a) -> json.Json) -> json.Json {
  json.array(items, encode_fn)
}

/// Encode array wrapped in response object
///
/// Used when returning arrays with metadata (like total count).
/// Consolidates pattern used in 10+ handlers.
pub fn array_with_count(
  items: List(a),
  count: Int,
  encode_fn: fn(a) -> json.Json,
) -> json.Json {
  json.object([
    #("count", json.int(count)),
    #("items", json.array(items, encode_fn)),
  ])
}

// =============================================================================
// Object Response Encoders
// =============================================================================

/// Encode a simple key-value object response
///
/// Used for endpoints returning single objects.
/// Replaces inline json.object construction in 5+ handlers.
pub fn object_response(fields: List(#(String, json.Json))) -> json.Json {
  json.object(fields)
}

/// Encode response with status and data
///
/// Standard format for responses that need status indication.
/// Used in status endpoints and operation results.
pub fn status_response(status: String, data: Option(json.Json)) -> json.Json {
  case data {
    Some(d) ->
      json.object([
        #("status", json.string(status)),
        #("data", d),
      ])
    None ->
      json.object([
        #("status", json.string(status)),
      ])
  }
}
