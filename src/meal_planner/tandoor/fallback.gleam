/// Fallback mechanisms for graceful degradation when Tandoor service is unavailable.
///
/// This module provides resilience patterns for handling Tandoor API failures:
/// - Health checking with timeout detection
/// - Circuit breaker pattern to prevent cascading failures
/// - Graceful degradation strategies (cached data, empty results, stale data)
/// - Retry logic with exponential backoff
/// - Recovery and state tracking
import birl
import gleam/float
import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import meal_planner/logger

// ============================================================================
// Types
// ============================================================================

/// Health status of the Tandoor service
pub type ServiceHealth {
  Healthy
  Degraded(reason: String)
  Unhealthy(reason: String)
}

/// Circuit breaker state
pub type CircuitState {
  Closed
  Open(since_ms: Int, reason: String)
  HalfOpen(attempt_count: Int)
}

/// Fallback strategy when service is unavailable
pub type FallbackStrategy {
  /// Return cached data from last successful request
  UseCachedData
  /// Return empty/default results
  ReturnEmpty
  /// Return stale data (older cached data)
  ReturnStaleData
  /// Fail immediately without retry
  FailFast
}

/// Circuit breaker configuration
pub type CircuitBreakerConfig {
  CircuitBreakerConfig(
    /// Number of failures before opening the circuit
    failure_threshold: Int,
    /// Duration to keep circuit open (milliseconds)
    open_timeout_ms: Int,
    /// Number of attempts allowed in half-open state
    half_open_max_attempts: Int,
  )
}

/// Fallback service state tracking
pub type FallbackState {
  FallbackState(
    circuit_state: CircuitState,
    failure_count: Int,
    last_failure_time_ms: Option(Int),
    last_success_time_ms: Option(Int),
    current_strategy: FallbackStrategy,
  )
}

/// Result of a service health check
pub type HealthCheckResult {
  ServiceHealthy
  ServiceUnreachable(latency_ms: Int)
  ServiceError(error: String, latency_ms: Int)
}

// ============================================================================
// Initialization & Configuration
// ============================================================================

/// Create a default circuit breaker configuration
///
/// Default values:
/// - failure_threshold: 5 consecutive failures
/// - open_timeout_ms: 30 seconds
/// - half_open_max_attempts: 3
pub fn default_circuit_breaker_config() -> CircuitBreakerConfig {
  CircuitBreakerConfig(
    failure_threshold: 5,
    open_timeout_ms: 30_000,
    half_open_max_attempts: 3,
  )
}

/// Create initial fallback state
pub fn initial_fallback_state() -> FallbackState {
  FallbackState(
    circuit_state: Closed,
    failure_count: 0,
    last_failure_time_ms: None,
    last_success_time_ms: None,
    current_strategy: UseCachedData,
  )
}

// ============================================================================
// Health Checking
// ============================================================================

/// Determine the appropriate fallback strategy based on health status
///
/// Strategy selection:
/// - Healthy service → use normal API
/// - Degraded → use cached data with warning
/// - Unhealthy → return empty or fail based on configuration
pub fn strategy_for_health(health: ServiceHealth) -> FallbackStrategy {
  case health {
    Healthy -> UseCachedData
    Degraded(_) -> UseCachedData
    Unhealthy(_) -> ReturnEmpty
  }
}

/// Check if service is in a failed state
pub fn is_failed(health: ServiceHealth) -> Bool {
  case health {
    Healthy -> False
    Degraded(_) -> True
    Unhealthy(_) -> True
  }
}

// ============================================================================
// Circuit Breaker Pattern
// ============================================================================

/// Record a successful operation and potentially close the circuit
pub fn record_success(state: FallbackState) -> FallbackState {
  let now_ms = get_current_time_ms()

  FallbackState(
    circuit_state: Closed,
    failure_count: 0,
    last_failure_time_ms: state.last_failure_time_ms,
    last_success_time_ms: Some(now_ms),
    current_strategy: UseCachedData,
  )
}

/// Record a failed operation and potentially open the circuit
pub fn record_failure(
  state: FallbackState,
  config: CircuitBreakerConfig,
  reason: String,
) -> FallbackState {
  let now_ms = get_current_time_ms()
  let new_failure_count = state.failure_count + 1

  let new_circuit_state = case state.circuit_state {
    Closed -> {
      case new_failure_count >= config.failure_threshold {
        True -> {
          logger.warning(
            "Circuit breaker opened after "
            <> int.to_string(new_failure_count)
            <> " failures: "
            <> reason,
          )
          Open(since_ms: now_ms, reason: reason)
        }
        False -> Closed
      }
    }
    Open(_, _) -> state.circuit_state
    HalfOpen(attempts) -> {
      case attempts >= config.half_open_max_attempts {
        True -> {
          logger.warning(
            "Half-open attempts exhausted, reopening circuit: " <> reason,
          )
          Open(since_ms: now_ms, reason: reason)
        }
        False -> HalfOpen(attempt_count: attempts + 1)
      }
    }
  }

  FallbackState(
    circuit_state: new_circuit_state,
    failure_count: new_failure_count,
    last_failure_time_ms: Some(now_ms),
    last_success_time_ms: state.last_success_time_ms,
    current_strategy: ReturnEmpty,
  )
}

/// Attempt to close the circuit and move to normal operation
pub fn attempt_circuit_recovery(
  state: FallbackState,
  config: CircuitBreakerConfig,
) -> FallbackState {
  let now_ms = get_current_time_ms()

  case state.circuit_state {
    Open(since_ms, _reason) -> {
      let elapsed_ms = now_ms - since_ms
      case elapsed_ms >= config.open_timeout_ms {
        True -> {
          logger.info("Circuit breaker transitioning to half-open state")
          FallbackState(
            circuit_state: HalfOpen(attempt_count: 0),
            failure_count: state.failure_count,
            last_failure_time_ms: state.last_failure_time_ms,
            last_success_time_ms: state.last_success_time_ms,
            current_strategy: UseCachedData,
          )
        }
        False -> state
      }
    }
    _ -> state
  }
}

/// Check if we should allow a request through the circuit
pub fn should_allow_request(state: FallbackState) -> Bool {
  case state.circuit_state {
    Closed -> True
    Open(_, _) -> False
    HalfOpen(_) -> True
  }
}

/// Get the current circuit breaker status as a string
pub fn circuit_status_string(state: FallbackState) -> String {
  case state.circuit_state {
    Closed -> "Circuit CLOSED, failures: " <> int.to_string(state.failure_count)
    Open(_, reason) -> "Circuit OPEN (" <> reason <> "), will retry in 30s"
    HalfOpen(attempts) ->
      "Circuit HALF-OPEN, attempt: " <> int.to_string(attempts) <> "/3"
  }
}

// ============================================================================
// Graceful Degradation Strategies
// ============================================================================

/// Apply a degradation strategy with optional fallback data
///
/// Returns:
/// - UseCachedData: the provided cached data
/// - ReturnEmpty: an empty list
/// - ReturnStaleData: the provided stale data or empty list
/// - FailFast: Error with reason
pub fn apply_degradation_strategy(
  strategy: FallbackStrategy,
  cached_data: Option(a),
  stale_data: Option(a),
  empty_value: a,
) -> Result(a, String) {
  case strategy {
    UseCachedData -> {
      case cached_data {
        Some(data) -> {
          logger.info("Using cached data due to service degradation")
          Ok(data)
        }
        None -> {
          logger.warning("No cached data available, returning empty")
          Ok(empty_value)
        }
      }
    }
    ReturnEmpty -> {
      logger.warning("Service unavailable, returning empty results")
      Ok(empty_value)
    }
    ReturnStaleData -> {
      case stale_data {
        Some(data) -> {
          logger.warning("Using stale data due to service unavailability")
          Ok(data)
        }
        None -> {
          logger.warning("No stale data available, returning empty")
          Ok(empty_value)
        }
      }
    }
    FailFast -> {
      logger.error("Circuit breaker preventing request")
      Error("Service unavailable")
    }
  }
}

// ============================================================================
// Retry Logic
// ============================================================================

/// Retry configuration
pub type RetryConfig {
  RetryConfig(
    max_attempts: Int,
    initial_backoff_ms: Int,
    max_backoff_ms: Int,
    backoff_multiplier: Float,
  )
}

/// Create default retry configuration
///
/// Default values:
/// - max_attempts: 3
/// - initial_backoff_ms: 100
/// - max_backoff_ms: 5000
/// - backoff_multiplier: 2.0
pub fn default_retry_config() -> RetryConfig {
  RetryConfig(
    max_attempts: 3,
    initial_backoff_ms: 100,
    max_backoff_ms: 5000,
    backoff_multiplier: 2.0,
  )
}

/// Calculate backoff delay in milliseconds for attempt N (starting at 1)
pub fn calculate_backoff_ms(config: RetryConfig, attempt: Int) -> Int {
  case attempt {
    1 -> 0
    n -> {
      let base = config.initial_backoff_ms
      let multiplier = config.backoff_multiplier
      let exponent = int.to_float(n - 2)
      int.min(
        base * float.round(multiplier |> pow(exponent)),
        config.max_backoff_ms,
      )
    }
  }
}

/// Check if we should retry based on attempt count
pub fn should_retry(config: RetryConfig, attempt: Int) -> Bool {
  attempt < config.max_attempts
}

// ============================================================================
// Monitoring & Metrics
// ============================================================================

/// Get a summary of fallback state for monitoring
pub fn state_summary(state: FallbackState) -> json.Json {
  let circuit_status = case state.circuit_state {
    Closed -> "closed"
    Open(_, _) -> "open"
    HalfOpen(_) -> "half-open"
  }

  let strategy_name = case state.current_strategy {
    UseCachedData -> "cached"
    ReturnEmpty -> "empty"
    ReturnStaleData -> "stale"
    FailFast -> "fail-fast"
  }

  json.object([
    #("circuit_state", json.string(circuit_status)),
    #("failure_count", json.int(state.failure_count)),
    #("current_strategy", json.string(strategy_name)),
    #("last_failure_time_ms", case state.last_failure_time_ms {
      Some(t) -> json.int(t)
      None -> json.null()
    }),
    #("last_success_time_ms", case state.last_success_time_ms {
      Some(t) -> json.int(t)
      None -> json.null()
    }),
  ])
}

// ============================================================================
// Internal Utilities
// ============================================================================

/// Get current time in milliseconds
fn get_current_time_ms() -> Int {
  birl.now() |> birl.to_unix_milli
}

/// Raise a number to a power (helper for exponential backoff)
fn pow(base: Float, exponent: Float) -> Float {
  case exponent {
    0.0 -> 1.0
    1.0 -> base
    _ -> {
      // Use iterative approach for better performance
      pow_iterative(base, exponent, 1.0, 0)
    }
  }
}

fn pow_iterative(
  base: Float,
  target_exponent: Float,
  result: Float,
  current_exponent: Int,
) -> Float {
  case int.to_float(current_exponent) >=. target_exponent {
    True -> result
    False ->
      pow_iterative(base, target_exponent, result *. base, current_exponent + 1)
  }
}

// ============================================================================
// Public Type Exports
// ============================================================================

/// Export all types for external use
pub type ClientOptions {
  ClientOptions(
    circuit_breaker_config: CircuitBreakerConfig,
    retry_config: RetryConfig,
    fallback_strategy: FallbackStrategy,
    enable_caching: Bool,
  )
}

/// Create default client options with all resilience features enabled
pub fn default_client_options() -> ClientOptions {
  ClientOptions(
    circuit_breaker_config: default_circuit_breaker_config(),
    retry_config: default_retry_config(),
    fallback_strategy: UseCachedData,
    enable_caching: True,
  )
}
