//// Domain-Specific Error Conversion Functions
////
//// This module provides converters from domain-specific error types to AppError:
//// - from_tandoor_error: Convert Tandoor API errors to AppError
//// - from_fatsecret_error: Convert FatSecret API errors to AppError
//// - from_scheduler_error: Convert scheduler errors to AppError
//// - from_database_error: Convert database errors to AppError
////
//// Each converter maps domain-specific error variants to the appropriate
//// AppError type while preserving context and error details.

import gleam/int
import meal_planner/errors/types.{
  type AppError, AuthenticationError, AuthorizationError, BadRequestError,
  DatabaseError, InternalError, NetworkError, NotFoundError, ServiceError,
  ValidationError,
}
import meal_planner/fatsecret/core/errors as fatsecret_errors
import meal_planner/scheduler/errors as scheduler_errors
import meal_planner/tandoor/core/error as tandoor_error

// ============================================================================
// Tandoor Error Conversion
// ============================================================================

/// Convert Tandoor error to AppError
///
/// Maps Tandoor-specific errors to appropriate AppError variants:
/// - Auth errors → AuthenticationError/AuthorizationError
/// - Not found → NotFoundError
/// - Server errors → ServiceError with status code
/// - Network/timeout → NetworkError
/// - Parse errors → InternalError
pub fn from_tandoor_error(error: tandoor_error.TandoorError) -> AppError {
  case error {
    tandoor_error.AuthenticationError ->
      AuthenticationError("Tandoor authentication failed")

    tandoor_error.AuthorizationError ->
      AuthorizationError("Tandoor authorization failed")

    tandoor_error.NotFoundError(msg) -> NotFoundError("tandoor_resource", msg)

    tandoor_error.BadRequestError(msg) -> BadRequestError(msg)

    tandoor_error.ServerError(code, msg) ->
      ServiceError(
        "tandoor",
        "Server error (" <> int.to_string(code) <> "): " <> msg,
      )

    tandoor_error.NetworkError(msg) -> NetworkError(msg)

    tandoor_error.TimeoutError -> NetworkError("Request timeout")

    tandoor_error.ParseError(msg) -> InternalError("Parse error: " <> msg)

    tandoor_error.UnknownError(msg) -> InternalError(msg)
  }
}

// ============================================================================
// FatSecret Error Conversion
// ============================================================================

/// Convert FatSecret error to AppError
///
/// Maps FatSecret-specific errors to appropriate AppError variants:
/// - OAuth/token errors → AuthenticationError
/// - Invalid parameters → ValidationError
/// - API unavailable → ServiceError
/// - Network errors → NetworkError
/// - Parse errors → InternalError
pub fn from_fatsecret_error(error: fatsecret_errors.FatSecretError) -> AppError {
  case error {
    fatsecret_errors.ApiError(code, msg) ->
      case code {
        fatsecret_errors.InvalidAccessToken
        | fatsecret_errors.InvalidOrExpiredToken ->
          AuthenticationError("Your session has expired. Please log in again.")

        fatsecret_errors.MissingRequiredParameter ->
          ValidationError("required_parameter", msg)

        fatsecret_errors.InvalidDate -> ValidationError("date", msg)

        fatsecret_errors.ApiUnavailable -> ServiceError("fatsecret", msg)

        _ -> ServiceError("fatsecret", msg)
      }

    fatsecret_errors.RequestFailed(status, body) ->
      ServiceError(
        "fatsecret",
        "Request failed (" <> int.to_string(status) <> "): " <> body,
      )

    fatsecret_errors.ParseError(msg) ->
      InternalError("FatSecret parse error: " <> msg)

    fatsecret_errors.OAuthError(msg) -> AuthenticationError(msg)

    fatsecret_errors.NetworkError(msg) -> NetworkError(msg)

    fatsecret_errors.ConfigMissing ->
      InternalError("FatSecret configuration is missing")

    fatsecret_errors.InvalidResponse(msg) -> ServiceError("fatsecret", msg)
  }
}

// ============================================================================
// Database Error Conversion
// ============================================================================

/// Convert database error string to AppError
///
/// Creates a DatabaseError with the specified operation and message.
/// Use this for direct database errors where operation context is known.
///
/// # Arguments
/// * operation - The database operation that failed (e.g., "select", "insert")
/// * message - Error message from the database
pub fn from_database_error(operation: String, message: String) -> AppError {
  DatabaseError(operation, message)
}

// ============================================================================
// Scheduler Error Conversion
// ============================================================================

/// Convert scheduler error to AppError
///
/// Maps scheduler-specific errors to appropriate AppError variants:
/// - Job not found → NotFoundError
/// - Invalid config/params → ValidationError/BadRequestError
/// - Database errors → DatabaseError
/// - Timeouts → NetworkError
/// - Execution failures → InternalError
pub fn from_scheduler_error(error: scheduler_errors.AppError) -> AppError {
  case error {
    scheduler_errors.ApiError(code, msg) ->
      ServiceError("api", "Error " <> int.to_string(code) <> ": " <> msg)

    scheduler_errors.TimeoutError(ms) ->
      NetworkError("Operation timed out after " <> int.to_string(ms) <> "ms")

    scheduler_errors.DatabaseError(msg) -> DatabaseError("scheduler", msg)

    scheduler_errors.TransactionError(msg) -> DatabaseError("transaction", msg)

    scheduler_errors.JobNotFound(_) -> NotFoundError("job", "Job not found")

    scheduler_errors.JobAlreadyRunning(_) ->
      BadRequestError("Job is already running")

    scheduler_errors.ExecutionFailed(_, reason) -> InternalError(reason)

    scheduler_errors.MaxRetriesExceeded(_) ->
      InternalError("Maximum retry attempts exceeded")

    scheduler_errors.InvalidConfiguration(reason) -> BadRequestError(reason)

    scheduler_errors.InvalidJobType(job_type) ->
      ValidationError("job_type", "Invalid job type: " <> job_type)

    scheduler_errors.SchedulerDisabled ->
      ServiceError("scheduler", "Scheduler is disabled")

    scheduler_errors.DependencyNotMet(_, _) ->
      BadRequestError("Job dependency not met")
  }
}
