/// Calculation and business logic timing instrumentation
///
/// This module provides utilities for timing macro calculations, meal generation,
/// and other business logic operations.
import gleam/option.{type Option}
import meal_planner/metrics/mod.{
  type MetricsRegistry, type QueryMetric, Calculation, end_timing, record_metric,
  start_timing,
}

// ============================================================================
// Calculation Timing Context
// ============================================================================

/// Timing context for a calculation
pub type CalculationTimingContext {
  CalculationTimingContext(operation_name: String, start_time: Int)
}

/// Start timing a calculation operation
pub fn start_calculation_timing(
  operation_name: String,
) -> CalculationTimingContext {
  CalculationTimingContext(
    operation_name: operation_name,
    start_time: get_timestamp_ms(),
  )
}

/// Complete timing and create metric
pub fn end_calculation_timing(
  context: CalculationTimingContext,
  success: Bool,
) -> QueryMetric {
  let end_time = get_timestamp_ms()
  let duration = int.to_float(end_time - context.start_time)

  QueryMetric(
    query_name: context.operation_name,
    duration_ms: duration,
    timestamp: end_time,
    success: success,
  )
}

/// Record a calculation metric in the registry
pub fn record_calculation(
  registry: MetricsRegistry,
  metric: QueryMetric,
) -> MetricsRegistry {
  record_metric(registry, metric, Calculation)
}

/// Time a calculation operation with automatic success/error tracking
pub fn time_calculation(
  registry: MetricsRegistry,
  operation_name: String,
  operation: fn() -> Result(a, e),
) -> #(Result(a, e), MetricsRegistry) {
  let context = start_calculation_timing(operation_name)
  let result = operation()
  let success = case result {
    Ok(_) -> True
    Error(_) -> False
  }
  let metric = end_calculation_timing(context, success)
  let updated_registry = record_calculation(registry, metric)

  #(result, updated_registry)
}

/// Simple timing wrapper that doesn't require Result type
pub fn time_pure_calculation(
  registry: MetricsRegistry,
  operation_name: String,
  operation: fn() -> a,
) -> #(a, MetricsRegistry) {
  let context = start_calculation_timing(operation_name)
  let result = operation()
  let metric = end_calculation_timing(context, True)
  let updated_registry = record_calculation(registry, metric)

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
