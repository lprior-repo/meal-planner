//// Observability types and contracts
//// Defines the core data structures for logging, metrics, and tracing

import gleam/dict.{type Dict}
import gleam/option.{type Option}
import logging.{type LogLevel}

/// Structured log entry with context and metadata
pub type LogEntry {
  LogEntry(
    level: LogLevel,
    message: String,
    timestamp: Int,
    context: LogContext,
    metadata: Dict(String, String),
  )
}

/// Logging context containing request/trace information
pub type LogContext {
  LogContext(
    trace_id: Option(String),
    span_id: Option(String),
    user_id: Option(String),
    request_id: Option(String),
    service: String,
  )
}

/// Metric types for different measurement patterns
pub type Metric {
  Counter(name: String, value: Int, labels: Dict(String, String))
  Gauge(name: String, value: Float, labels: Dict(String, String))
  Histogram(
    name: String,
    value: Float,
    buckets: List(Float),
    labels: Dict(String, String),
  )
  Summary(
    name: String,
    value: Float,
    quantiles: List(Float),
    labels: Dict(String, String),
  )
}

/// Metric collector configuration
pub type MetricConfig {
  MetricConfig(
    namespace: String,
    subsystem: String,
    enabled: Bool,
    export_interval_ms: Int,
  )
}

/// Distributed trace span
pub type Span {
  Span(
    trace_id: String,
    span_id: String,
    parent_span_id: Option(String),
    name: String,
    start_time: Int,
    end_time: Option(Int),
    attributes: Dict(String, String),
    events: List(SpanEvent),
    status: SpanStatus,
  )
}

/// Span event for marking significant moments within a span
pub type SpanEvent {
  SpanEvent(name: String, timestamp: Int, attributes: Dict(String, String))
}

/// Span completion status
pub type SpanStatus {
  Ok
  Error(message: String)
  Unset
}

/// Tracing configuration
pub type TracingConfig {
  TracingConfig(
    service_name: String,
    enabled: Bool,
    sample_rate: Float,
    exporter: TraceExporter,
  )
}

/// Trace export destination
pub type TraceExporter {
  ConsoleExporter
  OtlpExporter(endpoint: String)
  JaegerExporter(endpoint: String)
}

/// Performance monitoring entry
pub type PerformanceMetric {
  PerformanceMetric(
    operation: String,
    duration_ms: Int,
    timestamp: Int,
    context: LogContext,
    metadata: Dict(String, String),
  )
}

/// Error tracking entry with full context
pub type ErrorEntry {
  ErrorEntry(
    error_type: String,
    message: String,
    stack_trace: Option(String),
    timestamp: Int,
    context: LogContext,
    metadata: Dict(String, String),
    severity: ErrorSeverity,
  )
}

/// Error severity levels
pub type ErrorSeverity {
  Low
  Medium
  High
  Critical
}

/// Alert rule definition
pub type AlertRule {
  AlertRule(
    name: String,
    condition: AlertCondition,
    threshold: Float,
    window_ms: Int,
    enabled: Bool,
  )
}

/// Alert condition types
pub type AlertCondition {
  ErrorRateExceeds
  LatencyExceeds
  MetricValueExceeds(metric_name: String)
  MetricValueBelow(metric_name: String)
}

/// Observability configuration
pub type ObservabilityConfig {
  ObservabilityConfig(
    logging_enabled: Bool,
    metrics_enabled: Bool,
    tracing_enabled: Bool,
    metric_config: MetricConfig,
    tracing_config: TracingConfig,
  )
}
