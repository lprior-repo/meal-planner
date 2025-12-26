//// Comprehensive Error Handling Framework for Meal Planner
////
//// This module provides:
//// - Unified error type hierarchy across all domains
//// - Error context preservation with wrapping
//// - Structured error codes (string and numeric)
//// - User-friendly and developer error messages
//// - HTTP response serialization
//// - Error recovery strategies
//// - Railway-Oriented Programming utilities
//// - Conversion from domain-specific errors
//// - I18n message template hooks
//// - Logging and monitoring integration

import gleam/dict.{type Dict}
import gleam/http/response.{type Response}
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None}
import gleam/result
import gleam/string
import meal_planner/errors/classification
import meal_planner/errors/conversion
import meal_planner/errors/recovery
import meal_planner/errors/types.{
  type AppError, type ErrorContext, type ErrorSeverity, type RecoveryStrategy,
  AuthenticationError, AuthorizationError, BadRequestError, Critical,
  DatabaseError, Error, Info, InternalError, NetworkError, NoRetry,
  NotFoundError, RateLimitError, RetryAfter, RetryWithBackoff, ServiceError,
  ValidationError, Warning, WrappedError,
}
import meal_planner/fatsecret/core/errors as fatsecret_errors
import meal_planner/scheduler/errors as scheduler_errors
import meal_planner/tandoor/core/error as tandoor_error

// ============================================================================
// Error Classification (Re-exported from classification module)
// ============================================================================

/// Check if error is a validation error
pub fn is_validation_error(error: AppError) -> Bool {
  classification.is_validation_error(error)
}

/// Check if error is a client error (4xx)
pub fn is_client_error(error: AppError) -> Bool {
  classification.is_client_error(error)
}

/// Check if error is a server error (5xx)
pub fn is_server_error(error: AppError) -> Bool {
  classification.is_server_error(error)
}

/// Check if error is an authentication error
pub fn is_authentication_error(error: AppError) -> Bool {
  classification.is_authentication_error(error)
}

/// Check if error is recoverable (can be retried)
pub fn is_recoverable(error: AppError) -> Bool {
  classification.is_recoverable(error)
}

/// Get error severity level
pub fn error_severity(error: AppError) -> ErrorSeverity {
  classification.error_severity(error)
}

// ============================================================================
// HTTP Status Codes
// ============================================================================

/// Get HTTP status code for error
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
// Error Context Management
// ============================================================================

/// Add context to an error
pub fn add_context(error: AppError, key: String, value: String) -> AppError {
  case error {
    WrappedError(err, cause, ctx) -> {
      let new_ctx = dict.insert(ctx, key, value)
      WrappedError(err, cause, new_ctx)
    }
    _ -> {
      let ctx = dict.from_list([#(key, value)])
      WrappedError(error, error, ctx)
    }
  }
}

/// Get context value from error
pub fn get_context(error: AppError, key: String) -> Option(String) {
  case error {
    WrappedError(_, _, ctx) -> dict.get(ctx, key) |> option.from_result
    _ -> None
  }
}

/// Wrap an error with a cause
pub fn wrap_error(cause: AppError, error: AppError) -> AppError {
  WrappedError(error, cause, dict.new())
}

/// Get the root cause of an error chain
pub fn get_root_cause(error: AppError) -> AppError {
  case error {
    WrappedError(_, cause, _) -> get_root_cause(cause)
    _ -> error
  }
}

/// Get the length of the error chain
pub fn error_chain_length(error: AppError) -> Int {
  case error {
    WrappedError(_, cause, _) -> 1 + error_chain_length(cause)
    _ -> 1
  }
}

// ============================================================================
// Structured Error Codes
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

// ============================================================================
// Error Recovery Strategies
// ============================================================================

/// Get recovery strategy for error
pub fn recovery_strategy(error: AppError) -> RecoveryStrategy {
  recovery.recovery_strategy(error)
}

// ============================================================================
// Railway-Oriented Programming Utilities
// ============================================================================

/// Chain results (monadic bind)
pub fn and_then(
  result: Result(a, AppError),
  f: fn(a) -> Result(b, AppError),
) -> Result(b, AppError) {
  result.try(result, f)
}

/// Map errors to AppError
pub fn map_error(
  result: Result(a, e),
  f: fn(e) -> AppError,
) -> Result(a, AppError) {
  result.map_error(result, f)
}

// ============================================================================
// Error Conversion from Domain-Specific Errors
// ============================================================================

/// Convert Tandoor error to AppError
pub fn from_tandoor_error(error: tandoor_error.TandoorError) -> AppError {
  conversion.from_tandoor_error(error)
}

/// Convert FatSecret error to AppError
pub fn from_fatsecret_error(error: fatsecret_errors.FatSecretError) -> AppError {
  conversion.from_fatsecret_error(error)
}

/// Convert database error string to AppError
pub fn from_database_error(operation: String, message: String) -> AppError {
  conversion.from_database_error(operation, message)
}

/// Convert scheduler error to AppError
pub fn from_scheduler_error(error: scheduler_errors.AppError) -> AppError {
  conversion.from_scheduler_error(error)
}

// ============================================================================
// Internationalization Hooks
// ============================================================================

/// Get message template key for i18n
pub fn get_message_template(error: AppError) -> String {
  case error {
    ValidationError(_, _) -> "validation.field_invalid"
    NotFoundError(_, _) -> "errors.not_found"
    AuthenticationError(_) -> "errors.authentication"
    AuthorizationError(_) -> "errors.authorization"
    RateLimitError(_) -> "errors.rate_limit"
    BadRequestError(_) -> "errors.bad_request"
    DatabaseError(_, _) -> "errors.database"
    NetworkError(_) -> "errors.network"
    ServiceError(_, _) -> "errors.service"
    InternalError(_) -> "errors.internal"
    WrappedError(err, _, _) -> get_message_template(err)
  }
}

/// Get template parameters for i18n
pub fn get_template_params(error: AppError) -> List(#(String, String)) {
  case error {
    ValidationError(field, reason) -> [#("field", field), #("reason", reason)]
    NotFoundError(resource, id) -> [#("resource", resource), #("id", id)]
    RateLimitError(seconds) -> [#("seconds", int.to_string(seconds))]
    DatabaseError(operation, msg) -> [
      #("operation", operation),
      #("message", msg),
    ]
    ServiceError(service, msg) -> [#("service", service), #("message", msg)]
    _ -> []
  }
}

/// Get localized message (stub - would integrate with i18n system)
pub fn localized_message(error: AppError, locale locale: String) -> String {
  case locale {
    "en" -> user_friendly_message(error)
    "es" -> spanish_message(error)
    "fr" -> french_message(error)
    _ -> user_friendly_message(error)
  }
}

fn spanish_message(error: AppError) -> String {
  case error {
    NotFoundError("recipe", _) -> "La receta que buscas no fue encontrada."
    _ -> user_friendly_message(error)
  }
}

fn french_message(error: AppError) -> String {
  case error {
    NotFoundError("recipe", _) ->
      "La recette que vous recherchez n'a pas été trouvée."
    _ -> user_friendly_message(error)
  }
}

// ============================================================================
// Logging Integration
// ============================================================================

/// Log entry for structured logging
pub type LogEntry {
  LogEntry(
    level: ErrorSeverity,
    error_code: String,
    message: String,
    context: List(#(String, String)),
  )
}

/// Convert error to structured log entry
pub fn to_log_entry(error: AppError) -> LogEntry {
  let level = error_severity(error)
  let code = error_code(error)
  let message = developer_message(error)

  let context = case error {
    WrappedError(_, _, ctx) -> dict.to_list(ctx)
    DatabaseError(op, _) -> [#("operation", op)]
    ServiceError(svc, _) -> [#("service", svc)]
    _ -> []
  }

  LogEntry(level, code, message, context)
}

/// Check if error should trigger an alert
pub fn should_alert(error: AppError) -> Bool {
  case error_severity(error) {
    Critical -> True
    _ -> False
  }
}
