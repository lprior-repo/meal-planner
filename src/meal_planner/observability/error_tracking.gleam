//// Error tracking with full context capture
//// Integrates with logging and tracing systems

import gleam/dict.{type Dict}
import gleam/erlang/os
import gleam/option.{type Option, None, Some}
import logging
import meal_planner/observability/structured_logging as slog
import meal_planner/observability/types.{
  type ErrorEntry, type ErrorSeverity, type LogContext, Critical, ErrorEntry,
  High, Low, Medium,
}

/// Create an error entry
pub fn create_error(
  error_type error_type: String,
  message message: String,
  stack_trace stack_trace: Option(String),
  context context: LogContext,
  metadata metadata: Dict(String, String),
  severity severity: ErrorSeverity,
) -> ErrorEntry {
  let timestamp = os.system_time(os.Millisecond)

  ErrorEntry(
    error_type: error_type,
    message: message,
    stack_trace: stack_trace,
    timestamp: timestamp,
    context: context,
    metadata: metadata,
    severity: severity,
  )
}

/// Log an error with full context
pub fn log_error(error: ErrorEntry) -> Nil {
  let log_level = severity_to_log_level(error.severity)

  let error_metadata =
    error.metadata
    |> dict.insert("error_type", error.error_type)
    |> dict.insert("severity", severity_to_string(error.severity))

  let error_metadata = case error.stack_trace {
    Some(trace) -> dict.insert(error_metadata, "stack_trace", trace)
    None -> error_metadata
  }

  slog.log_with_context(
    level: log_level,
    message: error.message,
    context: error.context,
    metadata: error_metadata,
  )
}

/// Quick error logging helper
pub fn track_error(
  error_type: String,
  message: String,
  context: LogContext,
  severity: ErrorSeverity,
) -> Nil {
  let error =
    create_error(
      error_type: error_type,
      message: message,
      stack_trace: None,
      context: context,
      metadata: dict.new(),
      severity: severity,
    )

  log_error(error)
}

/// Convert severity to log level
fn severity_to_log_level(severity: ErrorSeverity) -> logging.LogLevel {
  case severity {
    Low -> logging.Warning
    Medium -> logging.Error
    High -> logging.Error
    Critical -> logging.Critical
  }
}

/// Convert severity to string
fn severity_to_string(severity: ErrorSeverity) -> String {
  case severity {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
    Critical -> "critical"
  }
}

/// Get error severity from HTTP status code
pub fn severity_from_http_status(status: Int) -> ErrorSeverity {
  case status {
    _ if status >= 500 -> High
    _ if status >= 400 -> Medium
    _ -> Low
  }
}
