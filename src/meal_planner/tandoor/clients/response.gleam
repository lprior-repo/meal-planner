/// Response parsing utilities for Tandoor API
///
/// This module provides functions for parsing HTTP responses from the Tandoor API
/// and converting them into typed Gleam data structures.
import gleam/dynamic
import gleam/dynamic/decode
import gleam/http/response
import gleam/int
import gleam/json
import meal_planner/tandoor/client.{
  type ApiResponse, type TandoorError, ApiResponse, AuthenticationError,
  AuthorizationError, BadRequestError, NotFoundError, ParseError, ServerError,
  UnknownError,
}

// ============================================================================
// Response Handling
// ============================================================================

/// Parse an HTTP response from Tandoor API
///
/// # Arguments
/// * `response` - HTTP response from the server
///
/// # Returns
/// Result with ApiResponse or TandoorError
pub fn parse_response(
  response: response.Response(String),
) -> Result(ApiResponse, TandoorError) {
  let status = response.status
  let body = response.body
  let headers = response.headers

  case status {
    200 | 201 | 204 -> {
      Ok(ApiResponse(status: status, headers: headers, body: body))
    }
    400 -> Error(BadRequestError(body))
    401 -> Error(AuthenticationError(body))
    403 -> Error(AuthorizationError(body))
    404 -> Error(NotFoundError(body))
    500 | 502 | 503 | 504 -> Error(ServerError(status, body))
    _ -> Error(UnknownError("HTTP " <> int.to_string(status) <> ": " <> body))
  }
}

/// Parse JSON body from an API response
///
/// # Arguments
/// * `response` - ApiResponse to parse
/// * `decoder` - JSON decoder function
///
/// # Returns
/// Result with decoded data or ParseError
pub fn parse_json_body(
  response: ApiResponse,
  decoder: fn(dynamic.Dynamic) -> Result(a, String),
) -> Result(a, TandoorError) {
  case json.parse(response.body, using: decode.dynamic) {
    Ok(parsed_json) -> {
      case decoder(parsed_json) {
        Ok(value) -> Ok(value)
        Error(error_msg) -> Error(ParseError(error_msg))
      }
    }
    Error(_) -> {
      let error_msg = "Failed to parse JSON"
      Error(ParseError(error_msg))
    }
  }
}
