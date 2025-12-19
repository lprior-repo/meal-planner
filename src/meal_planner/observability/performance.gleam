//// Performance monitoring utilities
//// Track operation duration and performance metrics

import gleam/dict.{type Dict}
import gleam/erlang/os
import gleam/int
import meal_planner/observability/metrics
import meal_planner/observability/structured_logging as logging
import meal_planner/observability/types.{
  type LogContext, type PerformanceMetric, PerformanceMetric,
}

/// Start timing an operation
pub fn start_timer() -> Int {
  os.system_time(os.Millisecond)
}

/// Calculate elapsed time in milliseconds
pub fn elapsed_ms(start_time: Int) -> Int {
  let end_time = os.system_time(os.Millisecond)
  end_time - start_time
}

/// Create a performance metric
pub fn record_performance(
  operation operation: String,
  duration_ms duration_ms: Int,
  context context: LogContext,
  metadata metadata: Dict(String, String),
) -> PerformanceMetric {
  let timestamp = os.system_time(os.Millisecond)

  PerformanceMetric(
    operation: operation,
    duration_ms: duration_ms,
    timestamp: timestamp,
    context: context,
    metadata: metadata,
  )
}

/// Log performance metric
pub fn log_performance(metric: PerformanceMetric) -> Nil {
  let perf_metadata =
    metric.metadata
    |> dict.insert("operation", metric.operation)
    |> dict.insert("duration_ms", int.to_string(metric.duration_ms))

  logging.log_with_context(
    level: logging_lib.Info,
    message: "Performance: "
      <> metric.operation
      <> " took "
      <> int.to_string(metric.duration_ms)
      <> "ms",
    context: metric.context,
    metadata: perf_metadata,
  )
}

/// Create histogram metric for duration
pub fn record_duration_histogram(
  name name: String,
  duration_ms duration_ms: Int,
  labels labels: Dict(String, String),
) -> types.Metric {
  let duration_seconds = int.to_float(duration_ms) /. 1000.0

  let buckets = [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0]

  metrics.histogram(
    name: name,
    value: duration_seconds,
    buckets: buckets,
    labels: labels,
  )
}

/// Measure and record operation performance
pub fn measure(
  operation operation: String,
  context context: LogContext,
  func func: fn() -> a,
) -> #(a, PerformanceMetric) {
  let start = start_timer()
  let result = func()
  let duration = elapsed_ms(start)

  let metric =
    record_performance(
      operation: operation,
      duration_ms: duration,
      context: context,
      metadata: dict.new(),
    )

  #(result, metric)
}

import logging as logging_lib
import meal_planner/observability/types
