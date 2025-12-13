/// Storage query timing and metrics instrumentation
///
/// This module provides utilities for easily adding timing instrumentation
/// to storage queries without cluttering the business logic.
import gleam/option.{type Option}
import meal_planner/metrics/mod.{
  type MetricsRegistry, type QueryMetric, type TimingContext, StorageQuery,
  end_timing, record_metric, start_timing,
}

// ============================================================================
// Query Timing Context
// ============================================================================

/// Timing context for a storage operation
pub type StorageTimingContext {
  StorageTimingContext(query_name: String, start_time: Int)
}

/// Start timing a storage query
pub fn start_query_timing(query_name: String) -> StorageTimingContext {
  StorageTimingContext(query_name: query_name, start_time: get_timestamp_ms())
}

/// Complete timing and create metric
pub fn end_query_timing(
  context: StorageTimingContext,
  success: Bool,
) -> QueryMetric {
  let end_time = get_timestamp_ms()
  let duration = int.to_float(end_time - context.start_time)

  QueryMetric(
    query_name: context.query_name,
    duration_ms: duration,
    timestamp: end_time,
    success: success,
  )
}

/// Record a storage query metric in the registry
pub fn record_query(
  registry: MetricsRegistry,
  metric: QueryMetric,
) -> MetricsRegistry {
  record_metric(registry, metric, StorageQuery)
}

/// Time a storage query operation with automatic success/error tracking
pub fn time_storage_operation(
  registry: MetricsRegistry,
  query_name: String,
  operation: fn() -> Result(a, e),
) -> #(Result(a, e), MetricsRegistry) {
  let context = start_query_timing(query_name)
  let result = operation()
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_query_timing(context, success)
  let updated_registry = record_query(registry, metric)

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
