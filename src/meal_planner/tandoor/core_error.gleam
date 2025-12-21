// Tandoor SDK - Core Error Types
//
// This module defines the comprehensive error type for the Tandoor SDK,
// covering authentication, authorization, HTTP errors, network issues,
// parsing failures, and unknown errors.

import gleam/int

/// Represents all possible errors that can occur when interacting with Tandoor API
pub type TandoorError {
  /// Authentication failed - invalid or missing credentials
  AuthenticationError

  /// Authorization failed - valid credentials but insufficient permissions
  AuthorizationError

  /// Resource not found (404)
  NotFoundError(message: String)

  /// Bad request - invalid input or malformed data (400)
  BadRequestError(message: String)

  /// Server error with HTTP status code and message (5xx)
  ServerError(status_code: Int, message: String)

  /// Network-level error (connection refused, DNS failure, etc.)
  NetworkError(message: String)

  /// Request timeout
  TimeoutError

  /// JSON parsing or data decoding error
  ParseError(message: String)

  /// Unknown or unexpected error
  UnknownError(message: String)
}

/// Converts a TandoorError to a human-readable string representation
///
/// ## Examples
///
/// ```gleam
/// error_to_string(AuthenticationError)
/// // -> "Authentication failed"
///
/// error_to_string(NotFoundError("Recipe with ID 123 not found"))
/// // -> "Not found: Recipe with ID 123 not found"
///
/// error_to_string(ServerError(500, "Database error"))
/// // -> "Server error (500): Database error"
/// ```
pub fn error_to_string(error: TandoorError) -> String {
  case error {
    AuthenticationError -> "Authentication failed"

    AuthorizationError -> "Authorization failed"

    NotFoundError(msg) -> "Not found: " <> msg

    BadRequestError(msg) -> "Bad request: " <> msg

    ServerError(code, msg) -> {
      let code_str = int.to_string(code)
      "Server error (" <> code_str <> "): " <> msg
    }

    NetworkError(msg) -> "Network error: " <> msg

    TimeoutError -> "Request timeout"

    ParseError(msg) -> "Parse error: " <> msg

    UnknownError(msg) -> "Unknown error: " <> msg
  }
}
