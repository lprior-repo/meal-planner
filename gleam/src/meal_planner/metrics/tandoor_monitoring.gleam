/// Tandoor API performance monitoring integration
/// Tracks API call latency, error rates, and endpoint metrics
///
/// Integration points:
/// - tandoor/client.gleam: Wrap HTTP requests with timing
/// - tandoor/connectivity.gleam: Track connection state changes
/// - tandoor/retry.gleam: Monitor retry attempts
///
/// Metrics collected:
/// - api_call_duration_ms: Time to complete API call (histogram)
/// - api_call_errors_total: Count of failed API calls (counter)
/// - api_endpoint_calls: Count of calls per endpoint (counter)
/// - tandoor_connection_health: Current connection state (gauge)
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/metrics/collector.{type MetricCollector}
import meal_planner/metrics/types.{
  type MetricCategory, type OperationContext, type TimingMeasurement,
  TandoorApiMetrics, TimingMeasurement,
}
import meal_planner/tandoor/client.{type TandoorError}

// ============================================================================
// API Call Monitoring
// ============================================================================

/// Start monitoring a Tandoor API call
/// Records the start time and initializes context
pub fn start_api_call(endpoint: String, method: String) -> OperationContext {
  let operation_name = method <> " " <> endpoint
  let start_time_ms = get_timestamp_ms()

  types.OperationContext(
    operation_name: operation_name,
    category: TandoorApiMetrics,
    start_time_ms: start_time_ms,
    metadata: [#("endpoint", endpoint), #("method", method)],
  )
}

/// Record a successful API call completion
pub fn record_api_success(
  collector: MetricCollector,
  context: OperationContext,
) -> MetricCollector {
  let end_time_ms = get_timestamp_ms()
  let duration_ms = int.to_float(end_time_ms - context.start_time_ms)

  let measurement =
    TimingMeasurement(
      operation_name: context.operation_name,
      duration_ms: duration_ms,
      timestamp_ms: end_time_ms,
      success: True,
      error_message: "",
    )

  // Record the timing
  let collector = collector.record_timing(collector, measurement)

  // Increment endpoint call counter
  let endpoint = get_metadata_value(context.metadata, "endpoint", "unknown")
  collector.record_counter(collector, "tandoor_api_endpoint_calls", 1, [
    #("endpoint", endpoint),
  ])
}

/// Record a failed API call
pub fn record_api_failure(
  collector: MetricCollector,
  context: OperationContext,
  error: TandoorError,
) -> MetricCollector {
  let end_time_ms = get_timestamp_ms()
  let duration_ms = int.to_float(end_time_ms - context.start_time_ms)

  let error_message = client.error_to_string(error)
  let error_type = classify_error(error)

  let measurement =
    TimingMeasurement(
      operation_name: context.operation_name,
      duration_ms: duration_ms,
      timestamp_ms: end_time_ms,
      success: False,
      error_message: error_message,
    )

  // Record the timing
  let collector = collector.record_timing(collector, measurement)

  // Increment error counter
  let endpoint = get_metadata_value(context.metadata, "endpoint", "unknown")
  let collector =
    collector.record_counter(collector, "tandoor_api_errors", 1, [
      #("endpoint", endpoint),
      #("error_type", error_type),
    ])

  collector
}

// ============================================================================
// Connection Health Monitoring
// ============================================================================

/// Record Tandoor connection health status
pub fn record_connection_health(
  collector: MetricCollector,
  is_healthy: Bool,
) -> MetricCollector {
  let health_value = case is_healthy {
    True -> 1.0
    False -> 0.0
  }

  collector.record_gauge(
    collector,
    "tandoor_connection_health",
    health_value,
    "status",
    [],
  )
}

/// Record API availability percentage
pub fn record_api_availability(
  collector: MetricCollector,
  availability_percent: Float,
) -> MetricCollector {
  collector.record_gauge(
    collector,
    "tandoor_api_availability",
    availability_percent,
    "percent",
    [],
  )
}

// ============================================================================
// Retry Attempt Monitoring
// ============================================================================

/// Record a retry attempt for Tandoor API
pub fn record_retry_attempt(
  collector: MetricCollector,
  endpoint: String,
  attempt_number: Int,
  reason: String,
) -> MetricCollector {
  collector.record_counter(collector, "tandoor_api_retry_attempts", 1, [
    #("endpoint", endpoint),
    #("reason", reason),
    #("attempt", int.to_string(attempt_number)),
  ])
}

/// Record final success after retries
pub fn record_success_after_retries(
  collector: MetricCollector,
  endpoint: String,
  total_attempts: Int,
) -> MetricCollector {
  collector.record_counter(collector, "tandoor_api_success_after_retries", 1, [
    #("endpoint", endpoint),
    #("attempts", int.to_string(total_attempts)),
  ])
}

/// Record final failure after exhausting retries
pub fn record_failure_after_retries(
  collector: MetricCollector,
  endpoint: String,
  total_attempts: Int,
  final_error: String,
) -> MetricCollector {
  let collector =
    collector.record_counter(collector, "tandoor_api_exhausted_retries", 1, [
      #("endpoint", endpoint),
      #("attempts", int.to_string(total_attempts)),
    ])

  collector.record_counter(collector, "tandoor_api_final_errors", 1, [
    #("endpoint", endpoint),
    #("error", final_error),
  ])
}

// ============================================================================
// Batch Operation Monitoring
// ============================================================================

/// Monitor recipe sync batch performance
pub fn record_recipe_sync_batch(
  collector: MetricCollector,
  total_recipes: Int,
  synced_recipes: Int,
  failed_recipes: Int,
  duration_ms: Float,
) -> MetricCollector {
  let collector =
    collector.record_counter(
      collector,
      "tandoor_recipe_sync_total",
      total_recipes,
      [],
    )

  let collector =
    collector.record_counter(
      collector,
      "tandoor_recipe_sync_success",
      synced_recipes,
      [],
    )

  let collector =
    collector.record_counter(
      collector,
      "tandoor_recipe_sync_failed",
      failed_recipes,
      [],
    )

  // Record batch duration
  collector.record_gauge(
    collector,
    "tandoor_recipe_sync_duration",
    duration_ms,
    "ms",
    [],
  )
}

// ============================================================================
// Request/Response Size Monitoring
// ============================================================================

/// Monitor API request/response sizes
pub fn record_api_payload_size(
  collector: MetricCollector,
  endpoint: String,
  request_size_bytes: Int,
  response_size_bytes: Int,
) -> MetricCollector {
  let collector =
    collector.record_gauge(
      collector,
      "tandoor_api_request_size",
      int.to_float(request_size_bytes),
      "bytes",
      [#("endpoint", endpoint)],
    )

  collector.record_gauge(
    collector,
    "tandoor_api_response_size",
    int.to_float(response_size_bytes),
    "bytes",
    [#("endpoint", endpoint)],
  )
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Classify TandoorError for metrics
fn classify_error(error: TandoorError) -> String {
  case error {
    client.AuthenticationError(_) -> "authentication_error"
    client.AuthorizationError(_) -> "authorization_error"
    client.NotFoundError(_) -> "not_found_error"
    client.BadRequestError(_) -> "bad_request_error"
    client.ServerError(_, _) -> "server_error"
    client.NetworkError(_) -> "network_error"
    client.TimeoutError -> "timeout_error"
    client.ParseError(_) -> "parse_error"
    client.UnknownError(_) -> "unknown_error"
  }
}

/// Get metadata value from context
fn get_metadata_value(
  metadata: List(#(String, String)),
  key: String,
  default: String,
) -> String {
  list.find(metadata, fn(item) {
    let #(k, _v) = item
    k == key
  })
  |> result.map(fn(item) {
    let #(_k, v) = item
    v
  })
  |> result.unwrap(default)
}

/// Get current timestamp in milliseconds
@external(erlang, "erlang", "system_time")
fn get_timestamp() -> Int

fn get_timestamp_ms() -> Int {
  get_timestamp() / 1_000_000
}

// ============================================================================
// Re-exports for convenience
// ============================================================================

/// Re-export types for monitoring context
pub type MetricCollector =
  MetricCollector

pub type OperationContext =
  OperationContext

// Compatibility shim for result operations
pub type Result(a, b) {
  Ok(a)
  Error(b)
}

pub fn result_map(r: Result(a, b), f: fn(a) -> c) -> Result(c, b) {
  case r {
    Ok(a) -> Ok(f(a))
    Error(b) -> Error(b)
  }
}

pub fn result_unwrap(r: Result(a, b), default: a) -> a {
  case r {
    Ok(a) -> a
    Error(_) -> default
  }
}
