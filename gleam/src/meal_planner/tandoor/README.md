# Tandoor Integration Module

This module provides resilient integration with the Tandoor recipe management system with graceful degradation capabilities.

## Modules

### `fallback.gleam` - Graceful Degradation & Resilience

Implements resilience patterns for handling Tandoor API failures:

#### Features

- **Circuit Breaker Pattern**: Prevents cascading failures by stopping requests when the service is repeatedly failing
  - Closed: Normal operation
  - Open: Service is unavailable, blocking requests for a timeout period
  - Half-Open: Attempting to recover, limited request attempts allowed

- **Health Status Tracking**: Monitors service health with three states
  - Healthy: Service is responding normally
  - Degraded: Service is slow or partially unavailable
  - Unhealthy: Service is unavailable

- **Graceful Degradation Strategies**:
  - `UseCachedData`: Return cached data from last successful request (recommended)
  - `ReturnEmpty`: Return empty results when service is unavailable
  - `ReturnStaleData`: Return older cached data as fallback
  - `FailFast`: Fail immediately without retry (for critical operations)

- **Retry Logic**: Exponential backoff retry configuration
  - Configurable max attempts (default: 3)
  - Exponential backoff delays (default: 100ms → 5s max)
  - Prevents retry storms and thundering herd

- **State Tracking**: Comprehensive failure tracking
  - Failure count and timestamps
  - Last success/failure times for monitoring
  - Current degradation strategy

#### Types

```gleam
// Service health status
pub type ServiceHealth {
  Healthy
  Degraded(reason: String)
  Unhealthy(reason: String)
}

// Circuit breaker states
pub type CircuitState {
  Closed                              // Normal operation
  Open(since_ms: Int, reason: String) // Service unavailable
  HalfOpen(attempt_count: Int)        // Recovering, limited attempts
}

// Fallback strategies
pub type FallbackStrategy {
  UseCachedData    // Use cached data
  ReturnEmpty      // Return empty results
  ReturnStaleData  // Use old cached data
  FailFast         // Fail immediately
}

// Complete fallback state
pub type FallbackState {
  FallbackState(
    circuit_state: CircuitState,
    failure_count: Int,
    last_failure_time_ms: Option(Int),
    last_success_time_ms: Option(Int),
    current_strategy: FallbackStrategy,
  )
}
```

#### Key Functions

**Initialization**:
- `initial_fallback_state()` - Create starting state (Closed, 0 failures)
- `default_circuit_breaker_config()` - Default config (5 failures → 30s timeout)
- `default_retry_config()` - Default retry policy (3 attempts, exp backoff)
- `default_client_options()` - Complete client configuration

**Circuit Breaker**:
- `record_success(state) -> state` - Mark successful operation
- `record_failure(state, config, reason) -> state` - Record failure, may open circuit
- `should_allow_request(state) -> bool` - Check if request can proceed
- `attempt_circuit_recovery(state, config) -> state` - Try to close open circuit

**Degradation**:
- `apply_degradation_strategy(strategy, cached, stale, empty) -> Result` - Apply strategy
- `strategy_for_health(health) -> strategy` - Get strategy for health status

**Monitoring**:
- `circuit_status_string(state) -> string` - Human-readable circuit status
- `state_summary(state) -> json` - JSON summary for monitoring/metrics

#### Usage Example

```gleam
import meal_planner/tandoor/fallback

// Initialize state and configuration
let state = fallback.initial_fallback_state()
let circuit_config = fallback.default_circuit_breaker_config()
let retry_config = fallback.default_retry_config()

// Check if we should attempt the request
case fallback.should_allow_request(state) {
  False -> {
    // Circuit is open, use degradation strategy
    let strategy = state.current_strategy
    fallback.apply_degradation_strategy(
      strategy,
      cached_data,
      stale_data,
      default_result
    )
  }
  True -> {
    // Attempt the API call
    case call_tandoor_api() {
      Ok(data) -> {
        let new_state = fallback.record_success(state)
        Ok(data)
      }
      Error(reason) -> {
        let new_state = fallback.record_failure(state, circuit_config, reason)
        // Use degradation strategy
        fallback.apply_degradation_strategy(...)
      }
    }
  }
}
```

### `connectivity.gleam` (Optional)

HTTP connectivity checking and timeout detection for service health monitoring.

### `retry.gleam` (Optional)

Advanced retry logic with jitter and custom backoff strategies.

## Architecture

The fallback module follows Gleam's functional programming principles:

1. **Immutable State**: `FallbackState` is immutable, functions return new state
2. **Type-Driven Design**: All behaviors encoded in types (Healthy, Degraded, etc.)
3. **Explicit Error Handling**: Uses `Result` type for all operations
4. **Logging Integration**: Respects project's logger configuration
5. **No Side Effects**: Pure functions allow testing without mocks

## Testing

Run tests with:
```bash
cd gleam
gleam test test/meal_planner/tandoor/fallback_test.gleam
```

Tests cover:
- Circuit breaker state transitions
- Failure threshold detection
- Degradation strategy selection
- Retry backoff calculation
- State tracking and monitoring

## Integration Points

- **Web Handlers**: Check circuit before API calls
- **Storage Layer**: Cache successful responses for degradation
- **Monitoring**: Export state via `state_summary()` for metrics
- **Configuration**: Use `ClientOptions` for client setup

## Performance Characteristics

- **Memory**: O(1) - constant size state
- **Time**: O(1) - all operations are simple lookups and arithmetic
- **Failures**: Circuit opens in < 1ms after threshold
- **Recovery**: Automatic retry after timeout (default: 30s)

## Future Enhancements

- Adaptive timeout based on historical latency
- Per-endpoint circuit breakers
- Bulkhead pattern for resource isolation
- Metrics export to Prometheus format
- Graceful degradation scoring
