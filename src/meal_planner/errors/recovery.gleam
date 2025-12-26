//// Error Recovery Strategy Functions
////
//// This module provides error recovery decision logic:
//// - recovery_strategy: Determine the appropriate recovery strategy for an error
//// - RecoveryStrategy type (re-exported from types):
////   - NoRetry: Permanent failure, no retry
////   - RetryWithBackoff: Retry with exponential backoff
////   - RetryAfter: Retry after specified delay
////
//// Recovery strategies are based on error type and recoverability:
//// - Client errors (validation, auth, not found): NoRetry
//// - Rate limits: RetryAfter with specified seconds
//// - Network/Service errors: RetryWithBackoff with reasonable attempts
//// - Database errors: RetryWithBackoff with more attempts
//// - Internal errors: NoRetry

import meal_planner/errors/types.{
  type AppError, type RecoveryStrategy, AuthenticationError, AuthorizationError,
  BadRequestError, DatabaseError, InternalError, NetworkError, NoRetry,
  NotFoundError, RateLimitError, RetryAfter, RetryWithBackoff, ServiceError,
  ValidationError, WrappedError,
}

// ============================================================================
// Recovery Strategy Decision
// ============================================================================

/// Determine the appropriate recovery strategy for an error
///
/// Returns a RecoveryStrategy indicating whether and how to retry the operation:
/// - NoRetry for permanent failures (validation, auth, not found)
/// - RetryAfter for rate limit errors with specified delay
/// - RetryWithBackoff for transient failures (network, database, service)
///
/// Recursively checks WrappedError to get strategy from underlying cause.
pub fn recovery_strategy(error: AppError) -> RecoveryStrategy {
  case error {
    // Validation errors - no retry
    ValidationError(_, _)
    | BadRequestError(_)
    | AuthenticationError(_)
    | AuthorizationError(_) -> NoRetry

    // Not found - no retry
    NotFoundError(_, _) -> NoRetry

    // Rate limit - retry after specified time
    RateLimitError(seconds) -> RetryAfter(seconds)

    // Network errors - retry with backoff
    NetworkError(_) -> RetryWithBackoff(max_attempts: 3, backoff_ms: 1000)

    // Database errors - retry with backoff
    DatabaseError(_, _) -> RetryWithBackoff(max_attempts: 5, backoff_ms: 2000)

    // Service errors - retry with backoff
    ServiceError(_, _) -> RetryWithBackoff(max_attempts: 3, backoff_ms: 1000)

    // Internal errors - no retry
    InternalError(_) -> NoRetry

    // Inherit from wrapped error
    WrappedError(err, _, _) -> recovery_strategy(err)
  }
}

// ============================================================================
// Recovery Strategy Helpers
// ============================================================================

/// Check if a recovery strategy allows retry
pub fn should_retry(strategy: RecoveryStrategy) -> Bool {
  case strategy {
    NoRetry -> False
    RetryWithBackoff(_, _) | RetryAfter(_) -> True
  }
}

/// Get the maximum retry attempts from a strategy
/// Returns 0 for NoRetry and RetryAfter strategies
pub fn max_attempts(strategy: RecoveryStrategy) -> Int {
  case strategy {
    NoRetry -> 0
    RetryWithBackoff(max_attempts, _) -> max_attempts
    RetryAfter(_) -> 1
  }
}

/// Get the initial backoff delay in milliseconds
/// Returns 0 for NoRetry, delay in ms for others
pub fn initial_backoff_ms(strategy: RecoveryStrategy) -> Int {
  case strategy {
    NoRetry -> 0
    RetryWithBackoff(_, backoff_ms) -> backoff_ms
    RetryAfter(seconds) -> seconds * 1000
  }
}

/// Calculate backoff delay for a given attempt number using exponential backoff
/// attempt_number starts at 0 for the first retry
pub fn calculate_backoff(strategy: RecoveryStrategy, attempt_number: Int) -> Int {
  case strategy {
    NoRetry -> 0
    RetryAfter(seconds) -> seconds * 1000
    RetryWithBackoff(_, base_ms) -> {
      // Exponential backoff: base * 2^attempt
      // For attempt 0: base_ms, attempt 1: base_ms * 2, attempt 2: base_ms * 4, etc.
      let multiplier = case attempt_number {
        0 -> 1
        1 -> 2
        2 -> 4
        3 -> 8
        4 -> 16
        _ -> 32
        // Cap at 32x for very high attempts
      }
      base_ms * multiplier
    }
  }
}
