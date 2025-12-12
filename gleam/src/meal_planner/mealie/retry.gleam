//// Retry logic with exponential backoff for Mealie API client
////
//// This module provides retry functionality for network operations with:
//// - Maximum 3 retries (4 total attempts)
//// - Exponential backoff: 1s, 2s, 4s
//// - Selective retrying based on error type

import gleam/erlang/process
import gleam/int
import gleam/string
import meal_planner/mealie/client.{type ClientError}

/// Check if an error is retryable
///
/// Retries on:
/// - NetworkTimeout
/// - ConnectionRefused
/// - HTTP 5xx errors
///
/// Does NOT retry on:
/// - 404 / RecipeNotFound
/// - 4xx client errors
/// - ConfigError
/// - DecodeError
pub fn is_retryable(error: ClientError) -> Bool {
  case error {
    // Retry on network timeouts
    client.NetworkTimeout(_, _) -> True
    // Retry on connection refused
    client.ConnectionRefused(_) -> True
    // Retry on HTTP 5xx errors (server errors)
    client.ApiError(api_err) -> {
      string.contains(api_err.message, "HTTP 5")
    }
    // Don't retry on:
    // - ConfigError (configuration issues)
    // - DecodeError (data format issues)
    // - HttpError with 4xx (client errors like 404)
    // - RecipeNotFound (specific 404)
    _ -> False
  }
}

/// Execute a function with exponential backoff retry logic
///
/// Retries up to 3 times with exponential backoff:
/// - Attempt 1: immediate
/// - Attempt 2: wait 1 second
/// - Attempt 3: wait 2 seconds
/// - Attempt 4: wait 4 seconds (last attempt)
///
/// Only retries on NetworkTimeout, ConnectionRefused, and HTTP 5xx errors.
/// Does not retry on 404, 4xx, ConfigError, or DecodeError.
///
/// ## Example
///
/// ```gleam
/// import meal_planner/mealie/retry
///
/// let result = retry.with_backoff(fn() {
///   // Your operation that might fail
///   get_recipe(config, "some-recipe")
/// })
/// ```
pub fn with_backoff(
  operation: fn() -> Result(a, ClientError),
) -> Result(a, ClientError) {
  retry_helper(operation, 0)
}

/// Helper for retry logic with attempt counter
fn retry_helper(
  operation: fn() -> Result(a, ClientError),
  attempt: Int,
) -> Result(a, ClientError) {
  case operation() {
    Ok(result) -> Ok(result)
    Error(error) -> {
      // Maximum 3 retries (4 total attempts: 0, 1, 2, 3)
      case attempt >= 3 {
        True -> Error(error)
        False -> {
          case is_retryable(error) {
            True -> {
              // Exponential backoff: 1s, 2s, 4s
              let delay_ms = int.bitwise_shift_left(1000, attempt)
              process.sleep(delay_ms)
              retry_helper(operation, attempt + 1)
            }
            False -> Error(error)
          }
        }
      }
    }
  }
}
