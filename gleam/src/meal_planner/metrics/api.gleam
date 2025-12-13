/// API call timing and metrics instrumentation
///
/// This module provides utilities for timing and monitoring API calls
/// to external services (Tandoor, etc).
import gleam/option.{type Option}
import meal_planner/metrics/mod.{
  type MetricsRegistry, type QueryMetric, ApiCall, end_timing, record_metric,
  start_timing,
}

// ============================================================================
// API Timing Context
// ============================================================================

/// Timing context for an API call
pub type ApiTimingContext {
  ApiTimingContext(
    api_name: String,
    endpoint: String,
    method: String,
    start_time: Int,
  )
}

/// Start timing an API call
pub fn start_api_timing(
  api_name: String,
  endpoint: String,
  method: String,
) -> ApiTimingContext {
  ApiTimingContext(
    api_name: api_name,
    endpoint: endpoint,
    method: method,
    start_time: get_timestamp_ms(),
  )
}

/// Create a formatted operation name for the metric
fn format_operation_name(context: ApiTimingContext) -> String {
  context.api_name <> " " <> context.method <> " " <> context.endpoint
}

/// Complete timing and create metric
pub fn end_api_timing(context: ApiTimingContext, success: Bool) -> QueryMetric {
  let end_time = get_timestamp_ms()
  let duration = int.to_float(end_time - context.start_time)
  let operation_name = format_operation_name(context)

  QueryMetric(
    query_name: operation_name,
    duration_ms: duration,
    timestamp: end_time,
    success: success,
  )
}

/// Record an API call metric in the registry
pub fn record_api_call(
  registry: MetricsRegistry,
  metric: QueryMetric,
) -> MetricsRegistry {
  record_metric(registry, metric, ApiCall)
}

/// Time an API call operation with automatic success/error tracking
pub fn time_api_operation(
  registry: MetricsRegistry,
  api_name: String,
  endpoint: String,
  method: String,
  operation: fn() -> Result(a, e),
) -> #(Result(a, e), MetricsRegistry) {
  let context = start_api_timing(api_name, endpoint, method)
  let result = operation()
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_api_timing(context, success)
  let updated_registry = record_api_call(registry, metric)

  #(result, updated_registry)
}

// ============================================================================
// Timestamp Utilities
// ============================================================================

/// Get current timestamp in milliseconds
@external(erlang, "erlang", "system_time")
fn get_timestamp() -> Int

fn get_timestamp_ms() -> Int {
  get_timestamp() / 1_000_000
}
