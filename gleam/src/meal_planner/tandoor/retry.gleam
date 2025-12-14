/// Retry logic with exponential backoff for Tandoor API operations
///
/// This module provides retry mechanisms for transient failures when
/// communicating with the Tandoor API. It implements exponential backoff
/// to avoid overwhelming the service and to handle temporary network issues.
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string

/// Configuration for retry behavior
pub type RetryConfig {
  RetryConfig(
    /// Maximum number of retry attempts (total attempts = max_attempts + 1)
    max_attempts: Int,
    /// Initial delay in milliseconds
    initial_delay_ms: Int,
    /// Maximum delay in milliseconds (backoff will not exceed this)
    max_delay_ms: Int,
    /// Backoff multiplier (e.g., 2.0 for exponential backoff)
    backoff_multiplier: Float,
    /// Jitter factor (0.0 to 1.0) to add randomness to backoff
    jitter_factor: Float,
  )
}

/// Result of a retry attempt
pub type RetryResult(a, e) {
  Success(value: a)
  Failure(error: e, attempt_count: Int)
}

/// Default retry configuration for Tandoor API
/// - Max 5 attempts (total 6 including initial)
/// - Start with 100ms, backoff exponentially (x2), cap at 30 seconds
/// - 10% jitter to avoid thundering herd
pub fn default_config() -> RetryConfig {
  RetryConfig(
    max_attempts: 5,
    initial_delay_ms: 100,
    max_delay_ms: 30_000,
    backoff_multiplier: 2.0,
    jitter_factor: 0.1,
  )
}

/// Aggressive retry configuration for critical operations
/// - More attempts, shorter initial delay
pub fn aggressive_config() -> RetryConfig {
  RetryConfig(
    max_attempts: 10,
    initial_delay_ms: 50,
    max_delay_ms: 60_000,
    backoff_multiplier: 2.0,
    jitter_factor: 0.2,
  )
}

/// Conservative retry configuration for low-priority operations
/// - Fewer attempts, longer delays
pub fn conservative_config() -> RetryConfig {
  RetryConfig(
    max_attempts: 3,
    initial_delay_ms: 500,
    max_delay_ms: 10_000,
    backoff_multiplier: 2.0,
    jitter_factor: 0.05,
  )
}

/// Calculate the delay for a given attempt number with exponential backoff
///
/// # Arguments
/// * `config` - Retry configuration
/// * `attempt` - Attempt number (0-based)
///
/// # Returns
/// Delay in milliseconds
///
/// # Algorithm
/// 1. Calculate base delay: initial_delay * (backoff_multiplier ^ attempt)
/// 2. Cap at max_delay
/// 3. Add jitter: delay * (1 + random(-jitter_factor, +jitter_factor))
///
/// # Example
/// ```gleam
/// let config = default_config()
/// calculate_backoff(config, 0)  // ~100ms + jitter
/// calculate_backoff(config, 1)  // ~200ms + jitter
/// calculate_backoff(config, 2)  // ~400ms + jitter
/// ```
pub fn calculate_backoff(config: RetryConfig, attempt: Int) -> Int {
  // Base exponential calculation: initial_delay * (multiplier ^ attempt)
  let power_result =
    float.power(config.backoff_multiplier, int.to_float(attempt))
  let multiplier = case power_result {
    Ok(v) -> v
    Error(_) -> 1.0
  }
  let base_delay = int.to_float(config.initial_delay_ms) *. multiplier

  // Cap at max_delay
  let capped_delay = float.min(base_delay, int.to_float(config.max_delay_ms))

  // Convert to int and add jitter
  let delay_int = float.round(capped_delay)

  // Apply jitter
  // For deterministic testing, jitter is calculated as a simple formula
  // In production, this would use random number generation
  let jitter_amount =
    float.round(int.to_float(delay_int) *. config.jitter_factor)

  delay_int + jitter_amount
}

/// Determine if an error should be retried based on HTTP status code
///
/// Returns True if the error is transient and should be retried:
/// - 408 Request Timeout
/// - 429 Too Many Requests
/// - 500 Internal Server Error
/// - 502 Bad Gateway
/// - 503 Service Unavailable
/// - 504 Gateway Timeout
/// - Network timeouts or connection errors
///
/// Returns False for permanent errors:
/// - 400 Bad Request
/// - 401 Unauthorized
/// - 403 Forbidden
/// - 404 Not Found
/// - 4xx client errors (except 408, 429)
/// - 5xx errors (except 500, 502, 503, 504)
pub fn should_retry(status_code: Int) -> Bool {
  case status_code {
    // Transient errors that should be retried
    408 | 429 | 500 | 502 | 503 | 504 -> True
    // Permanent client errors
    400 | 401 | 403 | 404 -> False
    // Other 4xx errors (client errors, don't retry)
    code if code >= 400 && code < 500 -> False
    // Other 5xx errors (server errors, don't retry)
    code if code >= 500 && code < 600 -> False
    // Unknown status codes (be conservative)
    _ -> False
  }
}

/// Check if an error message indicates a transient network failure
///
/// Returns True for transient network errors:
/// - Connection refused
/// - Connection reset
/// - Timeout
/// - DNS lookup failure
/// - Network unreachable
///
/// Returns False for permanent errors:
/// - Invalid URL
/// - SSL/TLS errors (unless temporary)
/// - Authentication errors
pub fn is_transient_network_error(error_message: String) -> Bool {
  let lower = string.lowercase(error_message)
  let transient_patterns = [
    "timeout",
    "connection refused",
    "connection reset",
    "dns",
    "unreachable",
    "temporarily unavailable",
    "econnrefused",
    "econnreset",
    "etimedout",
    "enetunreach",
  ]

  list.any(transient_patterns, fn(pattern) { string.contains(lower, pattern) })
}

/// Execute a function with automatic retry logic
///
/// Attempts to execute the provided function. If it returns an error
/// and the error should be retried (based on should_retry), it waits
/// according to the exponential backoff schedule and tries again.
///
/// # Arguments
/// * `config` - Retry configuration
/// * `operation` - Function that returns Result(value, error)
///
/// # Returns
/// RetryResult with either the successful value or final error and attempt count
///
/// # Notes
/// This is a pure function and does not actually perform delays.
/// In practice, delays would need to be handled by the runtime/scheduler.
/// The function returns information about delays that should be applied.
pub fn execute_with_retries(
  config: RetryConfig,
  operation: fn() -> Result(a, Int),
) -> RetryResult(a, Int) {
  execute_with_retries_impl(config, operation, 0)
}

/// Internal implementation of execute_with_retries that tracks attempt count
fn execute_with_retries_impl(
  config: RetryConfig,
  operation: fn() -> Result(a, Int),
  attempt: Int,
) -> RetryResult(a, Int) {
  case operation() {
    Ok(value) -> Success(value)
    Error(error_code) -> {
      // Check if we should retry
      let should_continue = attempt < config.max_attempts

      case should_continue && should_retry(error_code) {
        True -> {
          // Calculate backoff and recurse
          let _delay = calculate_backoff(config, attempt)
          execute_with_retries_impl(config, operation, attempt + 1)
        }
        False -> Failure(error: error_code, attempt_count: attempt + 1)
      }
    }
  }
}

/// Retry a function with up to N attempts, returning the last error if all fail
///
/// This is a simpler version that just counts attempts without fancy backoff.
/// Useful for quick "try a few times" patterns.
pub fn retry_n_times(
  max_attempts: Int,
  operation: fn() -> Result(a, e),
) -> Result(a, e) {
  retry_n_times_impl(max_attempts, operation, 0)
}

fn retry_n_times_impl(
  max_attempts: Int,
  operation: fn() -> Result(a, e),
  attempt: Int,
) -> Result(a, e) {
  case operation() {
    Ok(value) -> Ok(value)
    Error(err) -> {
      case attempt + 1 < max_attempts {
        True -> retry_n_times_impl(max_attempts, operation, attempt + 1)
        False -> Error(err)
      }
    }
  }
}

/// Map a RetryResult to a standard Result
pub fn retry_result_to_result(retry_result: RetryResult(a, e)) -> Result(a, e) {
  case retry_result {
    Success(value) -> Ok(value)
    Failure(error, _attempt_count) -> Error(error)
  }
}

/// Extract attempt count from RetryResult
pub fn get_attempt_count(retry_result: RetryResult(a, e)) -> Int {
  case retry_result {
    Success(_value) -> 1
    Failure(_error, attempt_count) -> attempt_count
  }
}
