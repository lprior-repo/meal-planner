/// Tests for the Tandoor fallback module - graceful degradation strategies
import gleeunit
import gleeunit/should
import gleam/option.{None, Some}
import meal_planner/tandoor/fallback.{
  type CircuitBreakerConfig, type FallbackState, type FallbackStrategy,
  Closed, HalfOpen, Open, UseCachedData, ReturnEmpty, ReturnStaleData,
  FailFast, Healthy, Unhealthy, Degraded,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Circuit Breaker Tests
// ============================================================================

pub fn test_initial_state_is_closed() {
  let state = fallback.initial_fallback_state()
  state.circuit_state |> should.equal(Closed)
}

pub fn test_initial_failure_count_is_zero() {
  let state = fallback.initial_fallback_state()
  state.failure_count |> should.equal(0)
}

pub fn test_record_success_resets_failures() {
  let state =
    fallback.FallbackState(
      circuit_state: Closed,
      failure_count: 3,
      last_failure_time_ms: Some(1000),
      last_success_time_ms: None,
      current_strategy: UseCachedData,
    )

  let updated = fallback.record_success(state)
  updated.failure_count |> should.equal(0)
  updated.circuit_state |> should.equal(Closed)
}

pub fn test_record_failure_increments_count() {
  let state = fallback.initial_fallback_state()
  let config = fallback.default_circuit_breaker_config()

  let updated = fallback.record_failure(state, config, "Test failure")
  updated.failure_count |> should.equal(1)
}

pub fn test_should_allow_request_when_closed() {
  let state = fallback.initial_fallback_state()
  fallback.should_allow_request(state) |> should.be_true()
}

pub fn test_should_block_request_when_open() {
  let state =
    fallback.FallbackState(
      circuit_state: Open(since_ms: 1000, reason: "Service down"),
      failure_count: 5,
      last_failure_time_ms: Some(1000),
      last_success_time_ms: None,
      current_strategy: ReturnEmpty,
    )

  fallback.should_allow_request(state) |> should.be_false()
}

pub fn test_should_allow_request_when_half_open() {
  let state =
    fallback.FallbackState(
      circuit_state: HalfOpen(attempt_count: 1),
      failure_count: 5,
      last_failure_time_ms: Some(1000),
      last_success_time_ms: None,
      current_strategy: UseCachedData,
    )

  fallback.should_allow_request(state) |> should.be_true()
}

pub fn test_circuit_status_string_closed() {
  let state = fallback.initial_fallback_state()
  let status = fallback.circuit_status_string(state)
  status |> should.contain("CLOSED")
  status |> should.contain("0")
}

pub fn test_circuit_status_string_open() {
  let state =
    fallback.FallbackState(
      circuit_state: Open(since_ms: 1000, reason: "Timeout"),
      failure_count: 5,
      last_failure_time_ms: Some(1000),
      last_success_time_ms: None,
      current_strategy: ReturnEmpty,
    )

  let status = fallback.circuit_status_string(state)
  status |> should.contain("OPEN")
  status |> should.contain("Timeout")
}

pub fn test_circuit_status_string_half_open() {
  let state =
    fallback.FallbackState(
      circuit_state: HalfOpen(attempt_count: 2),
      failure_count: 5,
      last_failure_time_ms: Some(1000),
      last_success_time_ms: None,
      current_strategy: UseCachedData,
    )

  let status = fallback.circuit_status_string(state)
  status |> should.contain("HALF-OPEN")
  status |> should.contain("2")
}

// ============================================================================
// Degradation Strategy Tests
// ============================================================================

pub fn test_apply_strategy_cached_data_with_data() {
  let cached = Some([1, 2, 3])
  let stale = None
  let empty = []

  let result =
    fallback.apply_degradation_strategy(UseCachedData, cached, stale, empty)
  result |> should.equal(Ok([1, 2, 3]))
}

pub fn test_apply_strategy_cached_data_without_data() {
  let cached = None
  let stale = None
  let empty = []

  let result =
    fallback.apply_degradation_strategy(UseCachedData, cached, stale, empty)
  result |> should.equal(Ok([]))
}

pub fn test_apply_strategy_return_empty() {
  let cached = Some([1, 2, 3])
  let stale = Some([4, 5, 6])
  let empty = []

  let result =
    fallback.apply_degradation_strategy(ReturnEmpty, cached, stale, empty)
  result |> should.equal(Ok([]))
}

pub fn test_apply_strategy_stale_data_with_data() {
  let cached = None
  let stale = Some([7, 8, 9])
  let empty = []

  let result =
    fallback.apply_degradation_strategy(ReturnStaleData, cached, stale, empty)
  result |> should.equal(Ok([7, 8, 9]))
}

pub fn test_apply_strategy_stale_data_without_data() {
  let cached = None
  let stale = None
  let empty = []

  let result =
    fallback.apply_degradation_strategy(ReturnStaleData, cached, stale, empty)
  result |> should.equal(Ok([]))
}

pub fn test_apply_strategy_fail_fast() {
  let cached = Some([1, 2, 3])
  let stale = Some([4, 5, 6])
  let empty = []

  let result = fallback.apply_degradation_strategy(FailFast, cached, stale, empty)
  result |> should.be_error()
}

pub fn test_strategy_for_health_healthy() {
  let strategy = fallback.strategy_for_health(Healthy)
  strategy |> should.equal(UseCachedData)
}

pub fn test_strategy_for_health_degraded() {
  let strategy = fallback.strategy_for_health(Degraded("Slow response"))
  strategy |> should.equal(UseCachedData)
}

pub fn test_strategy_for_health_unhealthy() {
  let strategy = fallback.strategy_for_health(Unhealthy("Connection refused"))
  strategy |> should.equal(ReturnEmpty)
}

pub fn test_is_failed_healthy_returns_false() {
  fallback.is_failed(Healthy) |> should.be_false()
}

pub fn test_is_failed_degraded_returns_true() {
  fallback.is_failed(Degraded("Slow")) |> should.be_true()
}

pub fn test_is_failed_unhealthy_returns_true() {
  fallback.is_failed(Unhealthy("Down")) |> should.be_true()
}

// ============================================================================
// Retry Configuration Tests
// ============================================================================

pub fn test_default_retry_config() {
  let config = fallback.default_retry_config()
  config.max_attempts |> should.equal(3)
  config.initial_backoff_ms |> should.equal(100)
  config.max_backoff_ms |> should.equal(5_000)
}

pub fn test_calculate_backoff_first_attempt() {
  let config = fallback.default_retry_config()
  let backoff = fallback.calculate_backoff_ms(config, 1)
  backoff |> should.equal(0)
}

pub fn test_calculate_backoff_second_attempt() {
  let config = fallback.default_retry_config()
  let backoff = fallback.calculate_backoff_ms(config, 2)
  backoff |> should.be_greater_than(0)
  backoff |> should.be_less_than_or_equal(config.max_backoff_ms)
}

pub fn test_calculate_backoff_respects_max() {
  let config =
    fallback.RetryConfig(
      max_attempts: 5,
      initial_backoff_ms: 100,
      max_backoff_ms: 1000,
      backoff_multiplier: 10.0,
    )

  let backoff = fallback.calculate_backoff_ms(config, 5)
  backoff |> should.be_less_than_or_equal(1000)
}

pub fn test_should_retry_within_limit() {
  let config = fallback.default_retry_config()
  fallback.should_retry(config, 1) |> should.be_true()
  fallback.should_retry(config, 2) |> should.be_true()
}

pub fn test_should_not_retry_at_max() {
  let config = fallback.default_retry_config()
  fallback.should_retry(config, 3) |> should.be_false()
}

// ============================================================================
// Configuration Tests
// ============================================================================

pub fn test_default_circuit_breaker_config() {
  let config = fallback.default_circuit_breaker_config()
  config.failure_threshold |> should.equal(5)
  config.open_timeout_ms |> should.equal(30_000)
  config.half_open_max_attempts |> should.equal(3)
}

pub fn test_default_client_options() {
  let opts = fallback.default_client_options()
  opts.enable_caching |> should.be_true()
}

// ============================================================================
// Edge Cases & Complex Scenarios
// ============================================================================

pub fn test_multiple_consecutive_failures_open_circuit() {
  let config =
    fallback.CircuitBreakerConfig(
      failure_threshold: 2,
      open_timeout_ms: 30_000,
      half_open_max_attempts: 3,
    )

  let state = fallback.initial_fallback_state()
  let state1 = fallback.record_failure(state, config, "Error 1")
  let state2 = fallback.record_failure(state1, config, "Error 2")

  case state2.circuit_state {
    Open(_, _) -> should.be_true(True)
    _ -> should.fail("Circuit should be open after threshold reached")
  }
}

pub fn test_failure_then_success_closes_circuit() {
  let config = fallback.default_circuit_breaker_config()
  let state = fallback.initial_fallback_state()
  let state_failed = fallback.record_failure(state, config, "Error")
  let state_success = fallback.record_success(state_failed)

  state_success.failure_count |> should.equal(0)
  state_success.circuit_state |> should.equal(Closed)
}

pub fn test_state_tracks_last_times() {
  let state = fallback.initial_fallback_state()
  let config = fallback.default_circuit_breaker_config()

  let state_failed = fallback.record_failure(state, config, "Error")
  state_failed.last_failure_time_ms |> should.not_equal(None)

  let state_success = fallback.record_success(state_failed)
  state_success.last_success_time_ms |> should.not_equal(None)
}

pub fn test_circuit_breaker_prevents_cascading_failures() {
  let config =
    fallback.CircuitBreakerConfig(
      failure_threshold: 2,
      open_timeout_ms: 30_000,
      half_open_max_attempts: 3,
    )

  let state = fallback.initial_fallback_state()
  let state1 = fallback.record_failure(state, config, "Error 1")
  let state2 = fallback.record_failure(state1, config, "Error 2")

  fallback.should_allow_request(state2) |> should.be_false()
}

pub fn test_half_open_respects_max_attempts() {
  let config =
    fallback.CircuitBreakerConfig(
      failure_threshold: 1,
      open_timeout_ms: 0,
      half_open_max_attempts: 2,
    )

  let state =
    fallback.FallbackState(
      circuit_state: HalfOpen(attempt_count: 2),
      failure_count: 1,
      last_failure_time_ms: Some(1000),
      last_success_time_ms: None,
      current_strategy: UseCachedData,
    )

  let updated = fallback.record_failure(state, config, "Half-open failure")
  case updated.circuit_state {
    Open(_, _) -> should.be_true(True)
    _ -> should.fail("Circuit should reopen after exhausting half-open attempts")
  }
}
