//// Error Classification Functions
////
//// This module provides type checking and classification functions for AppError:
//// - is_validation_error: Check if error is a validation error
//// - is_client_error: Check if error is a client error (4xx)
//// - is_server_error: Check if error is a server error (5xx)
//// - is_authentication_error: Check if error is an authentication error
//// - is_recoverable: Check if error can be retried
//// - error_severity: Get error severity level
////
//// All classification functions recursively handle WrappedError to check
//// the underlying error cause.

import meal_planner/errors/types.{
  type AppError, type ErrorSeverity, AuthenticationError, AuthorizationError,
  BadRequestError, Critical, DatabaseError, Error, Info, InternalError,
  NetworkError, NotFoundError, RateLimitError, ServiceError, ValidationError,
  Warning, WrappedError,
}

// ============================================================================
// Error Type Classification
// ============================================================================

/// Check if error is a validation error
pub fn is_validation_error(error: AppError) -> Bool {
  case error {
    ValidationError(_, _) -> True
    WrappedError(err, _, _) -> is_validation_error(err)
    _ -> False
  }
}

/// Check if error is a client error (4xx)
pub fn is_client_error(error: AppError) -> Bool {
  case error {
    ValidationError(_, _)
    | NotFoundError(_, _)
    | AuthenticationError(_)
    | AuthorizationError(_)
    | RateLimitError(_)
    | BadRequestError(_) -> True
    WrappedError(err, _, _) -> is_client_error(err)
    _ -> False
  }
}

/// Check if error is a server error (5xx)
pub fn is_server_error(error: AppError) -> Bool {
  case error {
    DatabaseError(_, _)
    | NetworkError(_)
    | ServiceError(_, _)
    | InternalError(_) -> True
    WrappedError(err, _, _) -> is_server_error(err)
    _ -> False
  }
}

/// Check if error is an authentication error
pub fn is_authentication_error(error: AppError) -> Bool {
  case error {
    AuthenticationError(_) -> True
    WrappedError(err, _, _) -> is_authentication_error(err)
    _ -> False
  }
}

// ============================================================================
// Error Recovery Classification
// ============================================================================

/// Check if error is recoverable (can be retried)
pub fn is_recoverable(error: AppError) -> Bool {
  case error {
    // Recoverable network/transient errors
    NetworkError(_) | RateLimitError(_) -> True
    DatabaseError("select", _) -> True
    // Database connection errors may be transient
    ServiceError(_, _) -> True

    // Non-recoverable errors
    ValidationError(_, _)
    | NotFoundError(_, _)
    | AuthenticationError(_)
    | AuthorizationError(_)
    | BadRequestError(_)
    | InternalError(_) -> False

    // Most database writes are not safely retryable
    DatabaseError(_, _) -> False

    // Check wrapped error
    WrappedError(err, _, _) -> is_recoverable(err)
  }
}

// ============================================================================
// Error Severity Classification
// ============================================================================

/// Get error severity level
pub fn error_severity(error: AppError) -> ErrorSeverity {
  case error {
    // Info - expected errors
    NotFoundError(_, _) -> Info

    // Warning - recoverable errors
    ValidationError(_, _)
    | AuthenticationError(_)
    | AuthorizationError(_)
    | RateLimitError(_)
    | BadRequestError(_) -> Warning

    NetworkError(_) -> Warning

    // Error - non-critical failures
    ServiceError(_, _) -> Error

    // Critical - system failures
    DatabaseError(_, _) | InternalError(_) -> Critical

    // Inherit from wrapped error
    WrappedError(err, _, _) -> error_severity(err)
  }
}
