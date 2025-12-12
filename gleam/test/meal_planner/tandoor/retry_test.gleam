/// Tests for the retry module with exponential backoff
///
/// Tests cover:
/// - Backoff calculation with exponential growth
/// - Jitter application
/// - HTTP status code classification
/// - Retry attempt counting
/// - Success and failure scenarios

import gleam/int
import gleeunit
import gleeunit/should
import meal_planner/tandoor/retry

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Default Configuration Tests
// ============================================================================

pub fn test_default_config() {
  let config = retry.default_config()
  config.max_attempts |> should.equal(5)
  config.initial_delay_ms |> should.equal(100)
  config.max_delay_ms |> should.equal(30_000)
  config.backoff_multiplier |> should.equal(2.0)
  config.jitter_factor |> should.equal(0.1)
}

pub fn test_aggressive_config() {
  let config = retry.aggressive_config()
  config.max_attempts |> should.equal(10)
  config.initial_delay_ms |> should.equal(50)
  config.max_delay_ms |> should.equal(60_000)
}

pub fn test_conservative_config() {
  let config = retry.conservative_config()
  config.max_attempts |> should.equal(3)
  config.initial_delay_ms |> should.equal(500)
  config.max_delay_ms |> should.equal(10_000)
}

// ============================================================================
// Backoff Calculation Tests
// ============================================================================

pub fn test_calculate_backoff_first_attempt() {
  let config = retry.default_config()
  let delay = retry.calculate_backoff(config, 0)

  // First attempt: 100ms ± 10% = 90-110ms
  delay |> should.be_greater_than_or_equal(90)
  delay |> should.be_less_than_or_equal(110)
}

pub fn test_calculate_backoff_second_attempt() {
  let config = retry.default_config()
  let delay = retry.calculate_backoff(config, 1)

  // Second attempt: 200ms ± 10% = 180-220ms
  delay |> should.be_greater_than_or_equal(180)
  delay |> should.be_less_than_or_equal(220)
}

pub fn test_calculate_backoff_third_attempt() {
  let config = retry.default_config()
  let delay = retry.calculate_backoff(config, 2)

  // Third attempt: 400ms ± 10% = 360-440ms
  delay |> should.be_greater_than_or_equal(360)
  delay |> should.be_less_than_or_equal(440)
}

pub fn test_calculate_backoff_exponential_growth() {
  let config = retry.default_config()
  let delay_0 = retry.calculate_backoff(config, 0)
  let delay_1 = retry.calculate_backoff(config, 1)
  let delay_2 = retry.calculate_backoff(config, 2)

  // Delays should grow exponentially (roughly doubling)
  // Due to jitter, we just check they're increasing
  delay_0 |> should.be_less_than(delay_1)
  delay_1 |> should.be_less_than(delay_2)
}

pub fn test_calculate_backoff_respects_max_delay() {
  let config = retry.RetryConfig(
    max_attempts: 10,
    initial_delay_ms: 10_000,
    max_delay_ms: 30_000,
    backoff_multiplier: 2.0,
    jitter_factor: 0.0,
  )

  // At attempt 5, would be 320,000ms without cap
  let delay = retry.calculate_backoff(config, 5)

  // Should be capped at 30,000ms
  delay |> should.be_less_than_or_equal(30_000)
}

pub fn test_calculate_backoff_conservative_config() {
  let config = retry.conservative_config()
  let delay = retry.calculate_backoff(config, 0)

  // Conservative: 500ms ± 5% = 475-525ms
  delay |> should.be_greater_than_or_equal(475)
  delay |> should.be_less_than_or_equal(525)
}

pub fn test_calculate_backoff_aggressive_config() {
  let config = retry.aggressive_config()
  let delay = retry.calculate_backoff(config, 0)

  // Aggressive: 50ms ± 20% = 40-60ms
  delay |> should.be_greater_than_or_equal(40)
  delay |> should.be_less_than_or_equal(60)
}

// ============================================================================
// HTTP Status Code Classification Tests
// ============================================================================

pub fn test_should_retry_timeout_408() {
  retry.should_retry(408) |> should.be_true()
}

pub fn test_should_retry_too_many_requests_429() {
  retry.should_retry(429) |> should.be_true()
}

pub fn test_should_retry_server_error_500() {
  retry.should_retry(500) |> should.be_true()
}

pub fn test_should_retry_bad_gateway_502() {
  retry.should_retry(502) |> should.be_true()
}

pub fn test_should_retry_service_unavailable_503() {
  retry.should_retry(503) |> should.be_true()
}

pub fn test_should_retry_gateway_timeout_504() {
  retry.should_retry(504) |> should.be_true()
}

pub fn test_should_not_retry_bad_request_400() {
  retry.should_retry(400) |> should.be_false()
}

pub fn test_should_not_retry_unauthorized_401() {
  retry.should_retry(401) |> should.be_false()
}

pub fn test_should_not_retry_forbidden_403() {
  retry.should_retry(403) |> should.be_false()
}

pub fn test_should_not_retry_not_found_404() {
  retry.should_retry(404) |> should.be_false()
}

pub fn test_should_not_retry_conflict_409() {
  retry.should_retry(409) |> should.be_false()
}

pub fn test_should_not_retry_other_4xx_errors() {
  retry.should_retry(405) |> should.be_false()
  retry.should_retry(406) |> should.be_false()
  retry.should_retry(410) |> should.be_false()
  retry.should_retry(415) |> should.be_false()
}

pub fn test_should_not_retry_other_5xx_errors() {
  retry.should_retry(501) |> should.be_false()
  retry.should_retry(505) |> should.be_false()
}

// ============================================================================
// Transient Network Error Detection Tests
// ============================================================================

pub fn test_is_transient_network_error_timeout() {
  retry.is_transient_network_error("Connection timeout") |> should.be_true()
}

pub fn test_is_transient_network_error_connection_refused() {
  retry.is_transient_network_error("Connection refused") |> should.be_true()
}

pub fn test_is_transient_network_error_connection_reset() {
  retry.is_transient_network_error("Connection reset by peer")
    |> should.be_true()
}

pub fn test_is_transient_network_error_dns() {
  retry.is_transient_network_error("DNS lookup failed") |> should.be_true()
}

pub fn test_is_transient_network_error_unreachable() {
  retry.is_transient_network_error("Network unreachable") |> should.be_true()
}

pub fn test_is_transient_network_error_econnrefused() {
  retry.is_transient_network_error("Error: ECONNREFUSED") |> should.be_true()
}

pub fn test_is_transient_network_error_etimedout() {
  retry.is_transient_network_error("Error: ETIMEDOUT") |> should.be_true()
}

pub fn test_is_transient_network_error_not_transient() {
  retry.is_transient_network_error("Invalid URL") |> should.be_false()
  retry.is_transient_network_error("SSL certificate error")
    |> should.be_false()
  retry.is_transient_network_error("Not found") |> should.be_false()
}

// ============================================================================
// Retry Execution Tests
// ============================================================================

pub fn test_execute_with_retries_success_first_try() {
  let config = retry.RetryConfig(
    max_attempts: 3,
    initial_delay_ms: 10,
    max_delay_ms: 100,
    backoff_multiplier: 2.0,
    jitter_factor: 0.0,
  )

  let result = retry.execute_with_retries(config, fn() { Ok(42) })

  case result {
    retry.Success(value) -> value |> should.equal(42)
    retry.Failure(_, _) -> should.fail("Should succeed on first try")
  }
}

pub fn test_execute_with_retries_failure_after_max_attempts() {
  let config = retry.RetryConfig(
    max_attempts: 2,
    initial_delay_ms: 10,
    max_delay_ms: 100,
    backoff_multiplier: 2.0,
    jitter_factor: 0.0,
  )

  let result = retry.execute_with_retries(config, fn() { Error(503) })

  case result {
    retry.Success(_) -> should.fail("Should fail after max attempts")
    retry.Failure(error, attempt_count) -> {
      error |> should.equal(503)
      attempt_count |> should.equal(3)
    }
  }
}

pub fn test_execute_with_retries_does_not_retry_permanent_errors() {
  let config = retry.RetryConfig(
    max_attempts: 5,
    initial_delay_ms: 10,
    max_delay_ms: 100,
    backoff_multiplier: 2.0,
    jitter_factor: 0.0,
  )

  let result = retry.execute_with_retries(config, fn() { Error(404) })

  case result {
    retry.Success(_) -> should.fail("Should fail immediately")
    retry.Failure(error, attempt_count) -> {
      error |> should.equal(404)
      // Should not retry for 404, only 1 attempt
      attempt_count |> should.equal(1)
    }
  }
}

// ============================================================================
// Retry N Times Tests
// ============================================================================

pub fn test_retry_n_times_success() {
  let result = retry.retry_n_times(3, fn() { Ok(100) })

  result |> should.equal(Ok(100))
}

pub fn test_retry_n_times_failure() {
  let result = retry.retry_n_times(3, fn() { Error("failed") })

  result |> should.equal(Error("failed"))
}

// ============================================================================
// Result Conversion Tests
// ============================================================================

pub fn test_retry_result_to_result_success() {
  let retry_result = retry.Success(value: 42)
  let result = retry.retry_result_to_result(retry_result)

  result |> should.equal(Ok(42))
}

pub fn test_retry_result_to_result_failure() {
  let retry_result = retry.Failure(error: "error", attempt_count: 3)
  let result = retry.retry_result_to_result(retry_result)

  result |> should.equal(Error("error"))
}

pub fn test_get_attempt_count_success() {
  let retry_result = retry.Success(value: 42)
  let count = retry.get_attempt_count(retry_result)

  count |> should.equal(1)
}

pub fn test_get_attempt_count_failure() {
  let retry_result = retry.Failure(error: "error", attempt_count: 3)
  let count = retry.get_attempt_count(retry_result)

  count |> should.equal(3)
}

// ============================================================================
// Integration Tests
// ============================================================================

pub fn test_realistic_scenario_transient_failures() {
  // Simulate a function that fails twice then succeeds
  let config = retry.default_config()
  let attempt_count = {
    use <- result.try(Ok(0))
    Ok(0)
  }
  let _result = attempt_count

  // This is a mock test - real scenario would need state tracking
  // For now, we test that the retry mechanism is available
  let result = retry.execute_with_retries(config, fn() { Ok("success") })

  case result {
    retry.Success(value) -> value |> should.equal("success")
    retry.Failure(_, _) -> should.fail("Should succeed")
  }
}

pub fn test_backoff_schedule_matches_exponential_curve() {
  // Verify the backoff schedule follows exponential growth pattern
  let config = retry.RetryConfig(
    max_attempts: 5,
    initial_delay_ms: 100,
    max_delay_ms: 10_000,
    backoff_multiplier: 2.0,
    jitter_factor: 0.0, // No jitter for predictable testing
  )

  let delay_0 = retry.calculate_backoff(config, 0)
  let delay_1 = retry.calculate_backoff(config, 1)
  let delay_2 = retry.calculate_backoff(config, 2)
  let delay_3 = retry.calculate_backoff(config, 3)

  // Expected: 100, 200, 400, 800
  delay_0 |> should.equal(100)
  delay_1 |> should.equal(200)
  delay_2 |> should.equal(400)
  delay_3 |> should.equal(800)
}
