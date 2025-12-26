//// Core Error Type Hierarchy
////
//// This module defines the foundational error types used throughout the meal planner:
//// - AppError: Unified error type with comprehensive error variants
//// - ErrorSeverity: Error severity levels for logging and alerting
//// - RecoveryStrategy: Error recovery and retry strategies
//// - ErrorContext: Context map for error enrichment

import gleam/dict.{type Dict}

// ============================================================================
// Core Error Type Hierarchy
// ============================================================================

/// Context map for error enrichment
pub type ErrorContext =
  Dict(String, String)

/// Unified application error type with Railway-Oriented Programming support
pub type AppError {
  // ========== Client Errors (4xx) ==========
  /// Validation error - invalid input data
  ValidationError(field: String, reason: String)

  /// Resource not found error
  NotFoundError(resource: String, id: String)

  /// Authentication error - invalid or missing credentials
  AuthenticationError(message: String)

  /// Authorization error - insufficient permissions
  AuthorizationError(message: String)

  /// Rate limit exceeded error
  RateLimitError(retry_after_seconds: Int)

  /// Bad request error - malformed request
  BadRequestError(message: String)

  // ========== Server Errors (5xx) ==========
  /// Database error
  DatabaseError(operation: String, message: String)

  /// Network error - connection issues
  NetworkError(message: String)

  /// External service error
  ServiceError(service: String, message: String)

  /// Internal server error
  InternalError(message: String)

  // ========== Error Wrapping for Context ==========
  /// Wrapped error with cause chain
  WrappedError(error: AppError, cause: AppError, context: ErrorContext)
}

// ============================================================================
// Error Severity Levels
// ============================================================================

/// Error severity for logging and alerting
pub type ErrorSeverity {
  Info
  Warning
  Error
  Critical
}

// ============================================================================
// Recovery Strategies
// ============================================================================

/// Error recovery strategy
pub type RecoveryStrategy {
  /// Do not retry - permanent failure
  NoRetry
  /// Retry with exponential backoff
  RetryWithBackoff(max_attempts: Int, backoff_ms: Int)
  /// Retry after specific delay
  RetryAfter(seconds: Int)
}
