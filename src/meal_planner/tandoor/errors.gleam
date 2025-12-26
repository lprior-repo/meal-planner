/// Tandoor Error Types Module
///
/// Centralized error types for Tandoor API operations.
/// This module exists to break circular dependencies by providing
/// error types independently of client implementation.
///
/// Error Types:
/// - TandoorError: Comprehensive error type for all Tandoor operations
///
/// Error Categories:
/// - Network: Connection/timeout/HTTP errors
/// - Parse: JSON decoding errors
/// - Auth: Authentication/authorization errors
/// - NotFound: Resource not found
/// - Validation: Invalid input data
import gleam/http/response

// ============================================================================
// HTTP Error
// ============================================================================

/// Error information from HTTP response
pub type HttpError {
  HttpError(
    /// HTTP status code
    status_code: Int,
    /// Response body (if available)
    body: String,
    /// Original response object for diagnostics
    response: response.Response(String),
  )
}

// ============================================================================
// Tandoor Error
// ============================================================================

/// Comprehensive error type for Tandoor API operations
///
/// Error variants:
/// - NetworkError: Connection failed, timeout, or HTTP error
/// - ParseError: JSON decoding failed
/// - NotFoundError: Requested resource doesn't exist
/// - BadRequest: Invalid request data (400)
/// - Unauthorized: Authentication/authorization failed (401)
/// - Forbidden: Insufficient permissions (403)
/// - InternalError: Server error (500)
pub type TandoorError {
  /// Resource not found (404)
  NotFoundError(resource: String)
  /// Network-related error (connection, timeout, HTTP error)
  NetworkError(message: String)
  /// JSON parsing/decoding error
  ParseError(message: String)
  /// Invalid request (400)
  BadRequest(String)
  /// Authentication/authorization failed (401)
  Unauthorized(String)
  /// Forbidden - insufficient permissions (403)
  Forbidden(String)
  /// Internal server error (500)
  InternalError(String)
}

// ============================================================================
// Error Conversions
// ============================================================================

/// Create HTTP error from response
///
/// Arguments:
/// - response: HTTP response with error status
///
/// Returns:
/// - HttpError with status code, body, and response object
pub fn http_error_from_response(
  response: response.Response(String),
) -> HttpError {
  let body =
    response.body
    |> string.from_utf8
    |> result.unwrap(or: "<no body>")

  HttpError(status_code: response.status, body: body, response: response)
}

/// Convert HTTP error to TandoorError
///
/// Arguments:
/// - error: HTTP error information
///
/// Returns:
/// - Appropriate TandoorError variant based on HTTP status code
pub fn tandoor_error_from_http(error: HttpError) -> TandoorError {
  case error.status_code {
    400 -> BadRequest(error.body)
    401 -> Unauthorized(error.body)
    403 -> Forbidden(error.body)
    404 -> NotFoundError(error.body)
    500 -> InternalError(error.body)
    _ ->
      NetworkError(
        "HTTP " <> int.to_string(error.status_code) <> ": " <> error.body,
      )
  }
}
