/// Retry logic for meal logging operations
///
/// Provides exponential backoff retry mechanism for transient failures.
/// Used for FatSecret API calls that may fail due to network issues or rate limiting.
import meal_planner/fatsecret/meal_logger/errors.{type MealLogError}

// ============================================================================
// Retry Configuration
// ============================================================================

/// Retry configuration
pub type RetryConfig {
  RetryConfig(
    /// Maximum number of retry attempts (default: 3)
    max_attempts: Int,
    /// Initial backoff delay in milliseconds (default: 1000)
    initial_delay_ms: Int,
    /// Backoff multiplier for exponential backoff (default: 2.0)
    backoff_multiplier: Float,
    /// Maximum delay between retries in milliseconds (default: 30000)
    max_delay_ms: Int,
  )
}

/// Default retry configuration
///
/// - 3 attempts total (1 initial + 2 retries)
/// - 1 second initial delay
/// - 2x exponential backoff
/// - 30 second max delay
pub fn default_config() -> RetryConfig {
  RetryConfig(
    max_attempts: 3,
    initial_delay_ms: 1000,
    backoff_multiplier: 2.0,
    max_delay_ms: 30_000,
  )
}

/// Aggressive retry configuration (for critical operations)
///
/// - 5 attempts total
/// - 500ms initial delay
/// - 2x exponential backoff
/// - 60 second max delay
pub fn aggressive_config() -> RetryConfig {
  RetryConfig(
    max_attempts: 5,
    initial_delay_ms: 500,
    backoff_multiplier: 2.0,
    max_delay_ms: 60_000,
  )
}

/// Conservative retry configuration (for non-critical operations)
///
/// - 2 attempts total
/// - 2 second initial delay
/// - 3x exponential backoff
/// - 10 second max delay
pub fn conservative_config() -> RetryConfig {
  RetryConfig(
    max_attempts: 2,
    initial_delay_ms: 2000,
    backoff_multiplier: 3.0,
    max_delay_ms: 10_000,
  )
}

// ============================================================================
// Retry Execution
// ============================================================================

/// Retry a function with exponential backoff
///
/// Executes the given function. If it fails with a retryable error,
/// waits with exponential backoff and retries up to max_attempts.
///
/// ## Parameters
/// - config: Retry configuration
/// - operation: Function to execute (returns Result)
///
/// ## Returns
/// - Ok(result) if operation succeeds
/// - Error(last_error) if all retries exhausted
///
/// ## Example
/// ```gleam
/// let config = default_config()
/// let result = with_retry(config, fn() {
///   // API call that might fail
///   fatsecret.log_meal(meal)
/// })
/// ```
pub fn with_retry(
  config config: RetryConfig,
  operation operation: fn() -> Result(a, MealLogError),
) -> Result(a, MealLogError) {
  retry_loop(config, operation, attempt: 1, delay_ms: config.initial_delay_ms)
}

fn retry_loop(
  config: RetryConfig,
  operation: fn() -> Result(a, MealLogError),
  attempt attempt: Int,
  delay_ms delay_ms: Int,
) -> Result(a, MealLogError) {
  case operation() {
    // Success - return immediately
    Ok(value) -> Ok(value)

    // Failure - check if retryable
    Error(error) -> {
      case should_retry(error, attempt, config.max_attempts) {
        False -> Error(error)
        True -> {
          // Sleep for delay_ms (simulated here, implement with actual sleep)
          let _sleep = sleep_ms(delay_ms)

          // Calculate next delay with exponential backoff
          let next_delay = calculate_next_delay(delay_ms, config)

          // Retry
          retry_loop(config, operation, attempt + 1, next_delay)
        }
      }
    }
  }
}

// ============================================================================
// Retry Decision Logic
// ============================================================================

fn should_retry(error: MealLogError, attempt: Int, max_attempts: Int) -> Bool {
  case attempt >= max_attempts {
    // Exhausted all attempts
    True -> False
    // Still have attempts left - check if error is retryable
    False -> errors.is_retryable(error)
  }
}

fn calculate_next_delay(current_delay_ms: Int, config: RetryConfig) -> Int {
  let next_delay_float =
    int_to_float(current_delay_ms) *. config.backoff_multiplier
  let next_delay = float_to_int(next_delay_float)

  // Cap at max delay
  case next_delay > config.max_delay_ms {
    True -> config.max_delay_ms
    False -> next_delay
  }
}

// ============================================================================
// Batch Retry
// ============================================================================

/// Retry a batch operation with partial failure handling
///
/// Attempts to execute operation. If it fails with BatchPartialFailure,
/// optionally retries only the failed items.
///
/// ## Parameters
/// - config: Retry configuration
/// - operation: Batch operation to execute
/// - retry_failed_only: If True, extract and retry only failed items
///
/// ## Returns
/// - Ok(results) if operation succeeds
/// - Error(last_error) if all retries exhausted
pub fn with_batch_retry(
  config config: RetryConfig,
  operation operation: fn() -> Result(a, MealLogError),
  retry_failed_only retry_failed_only: Bool,
) -> Result(a, MealLogError) {
  // For now, simple retry (TODO: implement partial retry extraction)
  case retry_failed_only {
    True -> with_retry(config, operation)
    False -> with_retry(config, operation)
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Sleep for specified milliseconds
///
/// NOTE: This is a placeholder. In production, use:
/// - `gleam_erlang/process.sleep()` for Erlang target
/// - JavaScript setTimeout for JS target
fn sleep_ms(ms: Int) -> Nil {
  // Placeholder - implement with actual sleep
  case ms {
    _ -> Nil
  }
}

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float

@external(erlang, "erlang", "round")
fn float_to_int(f: Float) -> Int
