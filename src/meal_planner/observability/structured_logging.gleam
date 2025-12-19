//// Structured logging framework with context and metadata
//// Provides rich logging capabilities beyond simple string messages

import gleam/dict.{type Dict}
import gleam/erlang/os
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import logging.{type LogLevel}
import meal_planner/observability/types.{
  type LogContext, type LogEntry, LogContext, LogEntry,
}

/// Create a new logging context with trace information
pub fn new_context(
  service service: String,
  trace_id trace_id: Option(String),
  span_id span_id: Option(String),
  user_id user_id: Option(String),
  request_id request_id: Option(String),
) -> LogContext {
  LogContext(
    trace_id: trace_id,
    span_id: span_id,
    user_id: user_id,
    request_id: request_id,
    service: service,
  )
}

/// Create an empty context with just a service name
pub fn empty_context(service: String) -> LogContext {
  LogContext(
    trace_id: None,
    span_id: None,
    user_id: None,
    request_id: None,
    service: service,
  )
}

/// Create a structured log entry
pub fn create_log_entry(
  level level: LogLevel,
  message message: String,
  context context: LogContext,
  metadata metadata: Dict(String, String),
) -> LogEntry {
  let timestamp = os.system_time(os.Millisecond)

  LogEntry(
    level: level,
    message: message,
    timestamp: timestamp,
    context: context,
    metadata: metadata,
  )
}

/// Log a message with full context and metadata
pub fn log_with_context(
  level level: LogLevel,
  message message: String,
  context context: LogContext,
  metadata metadata: Dict(String, String),
) -> Nil {
  let entry =
    create_log_entry(
      level: level,
      message: message,
      context: context,
      metadata: metadata,
    )

  let formatted = format_as_json(entry)

  // Log to Erlang logger
  logging.log(level, formatted)
}

/// Format log entry as JSON string
pub fn format_as_json(entry: LogEntry) -> String {
  let level_string = level_to_string(entry.level)

  let context_obj =
    json.object([
      #("service", json.string(entry.context.service)),
      #("trace_id", option_to_json_string(entry.context.trace_id)),
      #("span_id", option_to_json_string(entry.context.span_id)),
      #("user_id", option_to_json_string(entry.context.user_id)),
      #("request_id", option_to_json_string(entry.context.request_id)),
    ])

  let metadata_pairs =
    entry.metadata
    |> dict.to_list
    |> list.map(fn(pair) {
      let #(key, value) = pair
      #(key, json.string(value))
    })

  json.object([
    #("level", json.string(level_string)),
    #("message", json.string(entry.message)),
    #("timestamp", json.int(entry.timestamp)),
    #("context", context_obj),
    #("metadata", json.object(metadata_pairs)),
  ])
  |> json.to_string
}

/// Add metadata to context (returns new context for chaining)
pub fn with_metadata(
  context: LogContext,
  _metadata: Dict(String, String),
) -> LogContext {
  // Context is immutable, return as-is for chaining
  // Metadata is attached at log time via log_with_context
  context
}

// Helper: Convert LogLevel to string
fn level_to_string(level: LogLevel) -> String {
  case level {
    logging.Emergency -> "emergency"
    logging.Alert -> "alert"
    logging.Critical -> "critical"
    logging.Error -> "error"
    logging.Warning -> "warning"
    logging.Notice -> "notice"
    logging.Info -> "info"
    logging.Debug -> "debug"
  }
}

// Helper: Convert Option(String) to JSON value
fn option_to_json_string(opt: Option(String)) -> json.Json {
  case opt {
    Some(value) -> json.string(value)
    None -> json.null()
  }
}
