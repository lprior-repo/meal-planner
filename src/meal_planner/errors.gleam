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
import meal_planner/errors/http
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
// HTTP Status Codes (Re-exported from http module)
// ============================================================================

/// Get HTTP status code for error
pub fn http_status_code(error: AppError) -> Int {
  http.http_status_code(error)
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
// Structured Error Codes (Re-exported from http module)
// ============================================================================

/// Get string error code
pub fn error_code(error: AppError) -> String {
  http.error_code(error)
}

/// Get numeric error code
pub fn error_code_numeric(error: AppError) -> Int {
  http.error_code_numeric(error)
}

// ============================================================================
// User-Friendly Messages (Re-exported from http module)
// ============================================================================

/// Get user-friendly error message
pub fn user_friendly_message(error: AppError) -> String {
  http.user_friendly_message(error)
}

/// Get developer-friendly error message
pub fn developer_message(error: AppError) -> String {
  http.developer_message(error)
}

// ============================================================================
// HTTP Response Serialization (Re-exported from http module)
// ============================================================================

/// Convert error to HTTP response
pub fn to_http_response(error: AppError) -> Response(String) {
  http.to_http_response(error)
}

/// Convert error to HTTP response with request ID
pub fn to_http_response_with_request_id(
  error: AppError,
  request_id: String,
) -> Response(String) {
  http.to_http_response_with_request_id(error, request_id)
}

/// Convert error to JSON
pub fn to_json(error: AppError) -> Json {
  http.to_json(error)
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
