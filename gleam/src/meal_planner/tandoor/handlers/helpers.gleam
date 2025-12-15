/// Common helpers for Tandoor HTTP handlers
///
/// Consolidates duplicate code across multiple handlers:
/// - JSON encoding for optional values
/// - Query parameter parsing
/// - Success/error response builders
/// - Tandoor entity JSON encoders

import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import wisp

// =============================================================================
// Optional Value JSON Encoders
// =============================================================================

/// Encode an optional String to JSON (null if None)
pub fn encode_optional_string(opt: Option(String)) -> json.Json {
  case opt {
    Some(s) -> json.string(s)
    None -> json.null()
  }
}

/// Encode an optional Int to JSON (null if None)
pub fn encode_optional_int(opt: Option(Int)) -> json.Json {
  case opt {
    Some(i) -> json.int(i)
    None -> json.null()
  }
}

/// Encode an optional Float to JSON (null if None)
pub fn encode_optional_float(opt: Option(Float)) -> json.Json {
  case opt {
    Some(f) -> json.float(f)
    None -> json.null()
  }
}

// =============================================================================
// Query Parameter Parsing
// =============================================================================

/// Get query parameter value by key, returning Option(String)
pub fn get_query_param(
  params: List(#(String, String)),
  key: String,
) -> Option(String) {
  list.find(params, fn(param) { param.0 == key })
  |> result.map(fn(param) { param.1 })
  |> option.from_result
}

/// Parse optional integer query parameter
pub fn parse_int_param(
  params: List(#(String, String)),
  key: String,
) -> Option(Int) {
  params
  |> list.key_find(key)
  |> result.try(fn(s) {
    case string.is_empty(s) {
      True -> Error(Nil)
      False -> int.parse(s)
    }
  })
  |> option.from_result
}

/// Parse optional float query parameter
pub fn parse_float_param(
  params: List(#(String, String)),
  key: String,
) -> Option(Float) {
  params
  |> list.key_find(key)
  |> result.try(fn(s) {
    case string.is_empty(s) {
      True -> Error(Nil)
      False ->
        string.replace(s, ",", ".")
        |> float.parse
    }
  })
  |> option.from_result
}

// =============================================================================
// Response Builders
// =============================================================================

/// Create a JSON error response
pub fn error_response(status: Int, message: String) -> wisp.Response {
  json.object([#("error", json.string(message))])
  |> json.to_string
  |> wisp.json_response(status)
}

/// Create a success response with custom data
pub fn success_response(data: json.Json) -> wisp.Response {
  wisp.json_response(json.to_string(data), 200)
}

/// Create a simple success message response
pub fn success_message(message: String) -> wisp.Response {
  json.object([
    #("success", json.bool(True)),
    #("message", json.string(message)),
  ])
  |> json.to_string
  |> wisp.json_response(200)
}

/// Create a created response (201) with resource data
pub fn created_response(data: json.Json) -> wisp.Response {
  wisp.json_response(json.to_string(data), 201)
}

// =============================================================================
// Validation Helpers
// =============================================================================

/// Clamp an integer to a range
pub fn clamp(value: Int, min: Int, max: Int) -> Int {
  case value {
    _ if value < min -> min
    _ if value > max -> max
    _ -> value
  }
}

/// Clamp pagination limit to valid range (1-100)
pub fn clamp_limit(limit: Int) -> Int {
  clamp(limit, 1, 100)
}

/// Validate that a required string parameter is not empty
pub fn validate_required_string(
  value: Option(String),
  param_name: String,
) -> Result(String, #(Int, String)) {
  case value {
    None -> Error(#(400, "Missing required parameter: " <> param_name))
    Some(s) -> {
      case string.is_empty(s) {
        True ->
          Error(#(400, "Parameter '" <> param_name <> "' cannot be empty"))
        False -> Ok(s)
      }
    }
  }
}

/// Validate that an optional string is not empty if provided
pub fn validate_optional_string(
  value: Option(String),
  param_name: String,
) -> Result(Option(String), #(Int, String)) {
  case value {
    None -> Ok(None)
    Some(s) -> {
      case string.is_empty(s) {
        True ->
          Error(#(400, "Parameter '" <> param_name <> "' cannot be empty"))
        False -> Ok(Some(s))
      }
    }
  }
}

// =============================================================================
// Pagination Response Builder
// =============================================================================

/// Build a paginated response with count and results
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
