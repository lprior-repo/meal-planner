//// HTTP Response Serialization for Errors
////
//// This module provides HTTP response generation and JSON serialization for AppError:
//// - http_status_code: Map error to HTTP status code
//// - to_http_response: Convert error to HTTP Response
//// - to_json: Convert error to JSON
//// - error_code: Get string error code
//// - error_code_numeric: Get numeric error code
//// - user_friendly_message: Get user-facing error message
//// - developer_message: Get developer-facing error message with context
////
//// JSON response format:
//// {
////   "error": {
////     "code": "VALIDATION_ERROR",
////     "code_numeric": 4001,
////     "message": "User-friendly message",
////     "details": { ... },
////     "context": { ... }  // Only for WrappedError
////   }
//// }

import gleam/dict
import gleam/http/response.{type Response}
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/string
import meal_planner/errors/types.{
  type AppError, type ErrorContext, AuthenticationError, AuthorizationError,
  BadRequestError, DatabaseError, InternalError, NetworkError, NotFoundError,
  RateLimitError, ServiceError, ValidationError, WrappedError,
}

// ============================================================================
// HTTP Status Code Mapping
// ============================================================================

/// Get HTTP status code for error
///
/// Maps AppError variants to appropriate HTTP status codes:
/// - ValidationError, BadRequestError → 400
/// - AuthenticationError → 401
/// - AuthorizationError → 403
/// - NotFoundError → 404
/// - RateLimitError → 429
/// - DatabaseError, InternalError → 500
/// - NetworkError, ServiceError → 502
pub fn http_status_code(error: AppError) -> Int {
  case error {
    ValidationError(_, _) | BadRequestError(_) -> 400
    AuthenticationError(_) -> 401
    AuthorizationError(_) -> 403
    NotFoundError(_, _) -> 404
    RateLimitError(_) -> 429
    DatabaseError(_, _) | InternalError(_) -> 500
    NetworkError(_) | ServiceError(_, _) -> 502
    WrappedError(err, _, _) -> http_status_code(err)
  }
}

// ============================================================================
// Error Code Generation
// ============================================================================

/// Get string error code
pub fn error_code(error: AppError) -> String {
  case error {
    ValidationError(_, _) -> "VALIDATION_ERROR"
    NotFoundError(_, _) -> "NOT_FOUND"
    AuthenticationError(_) -> "AUTHENTICATION_ERROR"
    AuthorizationError(_) -> "AUTHORIZATION_ERROR"
    RateLimitError(_) -> "RATE_LIMIT_ERROR"
    BadRequestError(_) -> "BAD_REQUEST"
    DatabaseError(_, _) -> "DATABASE_ERROR"
    NetworkError(_) -> "NETWORK_ERROR"
    ServiceError(_, _) -> "SERVICE_ERROR"
    InternalError(_) -> "INTERNAL_ERROR"
    WrappedError(err, _, _) -> error_code(err)
  }
}

/// Get numeric error code
pub fn error_code_numeric(error: AppError) -> Int {
  case error {
    ValidationError(_, _) -> 4001
    NotFoundError(_, _) -> 4004
    AuthenticationError(_) -> 4011
    AuthorizationError(_) -> 4031
    RateLimitError(_) -> 4291
    BadRequestError(_) -> 4000
    DatabaseError(_, _) -> 5001
    NetworkError(_) -> 5002
    ServiceError(_, _) -> 5003
    InternalError(_) -> 5000
    WrappedError(err, _, _) -> error_code_numeric(err)
  }
}

// ============================================================================
// User-Friendly Messages
// ============================================================================

/// Get user-friendly error message
pub fn user_friendly_message(error: AppError) -> String {
  case error {
    ValidationError(field, reason) ->
      "The field '" <> field <> "' is invalid: " <> reason

    NotFoundError(resource, _) ->
      "The " <> resource <> " you're looking for was not found."

    AuthenticationError(_) ->
      "Authentication failed. Please check your credentials and try again."

    AuthorizationError(_) ->
      "You don't have permission to access this resource."

    RateLimitError(seconds) ->
      "Too many requests. Please try again in "
      <> int.to_string(seconds)
      <> " seconds."

    BadRequestError(msg) -> "Invalid request: " <> msg

    DatabaseError(_, _) -> "A database error occurred. Please try again later."

    NetworkError(_) ->
      "A network error occurred. Please check your connection and try again."

    ServiceError(service, _) ->
      "The "
      <> service
      <> " service is currently unavailable. Please try again later."

    InternalError(_) -> "An internal error occurred. Please try again later."

    WrappedError(err, _, _) -> user_friendly_message(err)
  }
}

/// Get developer-friendly error message
pub fn developer_message(error: AppError) -> String {
  case error {
    ValidationError(field, reason) ->
      "Validation failed for field '" <> field <> "': " <> reason

    NotFoundError(resource, id) ->
      "Resource '" <> resource <> "' with ID '" <> id <> "' not found"

    AuthenticationError(msg) -> "Authentication failed: " <> msg

    AuthorizationError(msg) -> "Authorization failed: " <> msg

    RateLimitError(seconds) ->
      "Rate limit exceeded. Retry after "
      <> int.to_string(seconds)
      <> " seconds"

    BadRequestError(msg) -> "Bad request: " <> msg

    DatabaseError(operation, msg) ->
      "Database operation '" <> operation <> "' failed: " <> msg

    NetworkError(msg) -> "Network error: " <> msg

    ServiceError(service, msg) -> "Service '" <> service <> "' error: " <> msg

    InternalError(msg) -> "Internal error: " <> msg

    WrappedError(err, cause, ctx) -> {
      let base = developer_message(err)
      let cause_msg = developer_message(cause)
      let ctx_str = format_context(ctx)
      base <> " | Caused by: " <> cause_msg <> ctx_str
    }
  }
}

fn format_context(ctx: ErrorContext) -> String {
  case dict.to_list(ctx) {
    [] -> ""
    pairs -> {
      let formatted =
        list.map(pairs, fn(pair) {
          let #(k, v) = pair
          k <> "=" <> v
        })
        |> string.join(", ")
      " | Context: " <> formatted
    }
  }
}

// ============================================================================
// HTTP Response Serialization
// ============================================================================

/// Convert error to HTTP response
pub fn to_http_response(error: AppError) -> Response(String) {
  let status = http_status_code(error)
  let body = to_json(error) |> json.to_string

  response.new(status)
  |> response.set_body(body)
  |> response.set_header("content-type", "application/json")
}

/// Convert error to HTTP response with request ID
pub fn to_http_response_with_request_id(
  error: AppError,
  request_id: String,
) -> Response(String) {
  to_http_response(error)
  |> response.set_header("x-request-id", request_id)
}

/// Convert error to JSON
pub fn to_json(error: AppError) -> Json {
  let code = error_code(error)
  let code_numeric = error_code_numeric(error)
  let message = user_friendly_message(error)
  let details = error_details_json(error)

  let error_obj = case error {
    WrappedError(_, _, ctx) ->
      json.object([
        #("code", json.string(code)),
        #("code_numeric", json.int(code_numeric)),
        #("message", json.string(message)),
        #("details", details),
        #("context", context_to_json(ctx)),
      ])

    _ ->
      json.object([
        #("code", json.string(code)),
        #("code_numeric", json.int(code_numeric)),
        #("message", json.string(message)),
        #("details", details),
      ])
  }

  json.object([#("error", error_obj)])
}

fn error_details_json(error: AppError) -> Json {
  case error {
    ValidationError(field, reason) ->
      json.object([
        #("field", json.string(field)),
        #("reason", json.string(reason)),
      ])

    NotFoundError(resource, id) ->
      json.object([
        #("resource", json.string(resource)),
        #("id", json.string(id)),
      ])

    DatabaseError(operation, msg) ->
      json.object([
        #("operation", json.string(operation)),
        #("message", json.string(msg)),
      ])

    ServiceError(service, msg) ->
      json.object([
        #("service", json.string(service)),
        #("message", json.string(msg)),
      ])

    _ -> json.object([])
  }
}

fn context_to_json(ctx: ErrorContext) -> Json {
  let pairs =
    dict.to_list(ctx)
    |> list.map(fn(pair) {
      let #(k, v) = pair
      #(k, json.string(v))
    })

  json.object(pairs)
}
