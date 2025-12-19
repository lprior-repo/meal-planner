//// Distributed tracing framework
//// Supports OpenTelemetry-style spans with correlation IDs

import gleam/dict.{type Dict}
import gleam/erlang/os
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import meal_planner/observability/types.{
  type Span, type SpanEvent, type SpanStatus, Error as SpanError, Ok as SpanOk,
  Span, SpanEvent, Unset,
}

/// Start a new span
pub fn start_span(
  trace_id trace_id: String,
  span_id span_id: String,
  parent_span_id parent_span_id: Option(String),
  name name: String,
  attributes attributes: Dict(String, String),
) -> Span {
  let start_time = os.system_time(os.Millisecond)

  Span(
    trace_id: trace_id,
    span_id: span_id,
    parent_span_id: parent_span_id,
    name: name,
    start_time: start_time,
    end_time: None,
    attributes: attributes,
    events: [],
    status: Unset,
  )
}

/// End a span and record the end time
pub fn end_span(span: Span) -> Span {
  let end_time = os.system_time(os.Millisecond)

  Span(..span, end_time: Some(end_time))
}

/// Add an event to a span
pub fn add_event(
  span: Span,
  name name: String,
  attributes attributes: Dict(String, String),
) -> Span {
  let timestamp = os.system_time(os.Millisecond)

  let event =
    SpanEvent(name: name, timestamp: timestamp, attributes: attributes)

  Span(..span, events: [event, ..span.events])
}

/// Set the status of a span
pub fn set_status(span: Span, status: SpanStatus) -> Span {
  Span(..span, status: status)
}

/// Add attributes to a span
pub fn add_attributes(span: Span, attributes: Dict(String, String)) -> Span {
  let merged =
    span.attributes
    |> dict.merge(attributes)

  Span(..span, attributes: merged)
}

/// Calculate span duration in milliseconds
pub fn span_duration_ms(span: Span) -> Option(Int) {
  case span.end_time {
    Some(end_time) -> Some(end_time - span.start_time)
    None -> None
  }
}

/// Generate a random trace ID (simplified UUID v4)
pub fn generate_trace_id() -> String {
  let timestamp = os.system_time(os.Millisecond)
  let random = int.random(1_000_000_000)

  "trace-" <> int.to_string(timestamp) <> "-" <> int.to_string(random)
}

/// Generate a random span ID
pub fn generate_span_id() -> String {
  let timestamp = os.system_time(os.Millisecond)
  let random = int.random(1_000_000_000)

  "span-" <> int.to_string(timestamp) <> "-" <> int.to_string(random)
}

/// Format span as JSON for export
pub fn format_span_json(span: Span) -> String {
  let attributes_str = format_attributes(span.attributes)
  let events_str = format_events(span.events)
  let status_str = format_status(span.status)

  let end_time_str = case span.end_time {
    Some(t) -> int.to_string(t)
    None -> "null"
  }

  let parent_str = case span.parent_span_id {
    Some(p) -> "\"" <> p <> "\""
    None -> "null"
  }

  "{"
  <> "\"trace_id\":\""
  <> span.trace_id
  <> "\","
  <> "\"span_id\":\""
  <> span.span_id
  <> "\","
  <> "\"parent_span_id\":"
  <> parent_str
  <> ","
  <> "\"name\":\""
  <> span.name
  <> "\","
  <> "\"start_time\":"
  <> int.to_string(span.start_time)
  <> ","
  <> "\"end_time\":"
  <> end_time_str
  <> ","
  <> "\"attributes\":"
  <> attributes_str
  <> ","
  <> "\"events\":"
  <> events_str
  <> ","
  <> "\"status\":\""
  <> status_str
  <> "\""
  <> "}"
}

// Helper: Format attributes as JSON object
fn format_attributes(attrs: Dict(String, String)) -> String {
  let pairs = dict.to_list(attrs)

  case pairs {
    [] -> "{}"
    _ -> {
      let formatted =
        pairs
        |> list.map(fn(pair) {
          let #(key, value) = pair
          "\"" <> key <> "\":\"" <> value <> "\""
        })
        |> string.join(",")

      "{" <> formatted <> "}"
    }
  }
}

// Helper: Format events as JSON array
fn format_events(events: List(SpanEvent)) -> String {
  case events {
    [] -> "[]"
    _ -> {
      let formatted =
        events
        |> list.reverse
        |> list.map(fn(event) {
          let attrs = format_attributes(event.attributes)
          "{"
          <> "\"name\":\""
          <> event.name
          <> "\","
          <> "\"timestamp\":"
          <> int.to_string(event.timestamp)
          <> ","
          <> "\"attributes\":"
          <> attrs
          <> "}"
        })
        |> string.join(",")

      "[" <> formatted <> "]"
    }
  }
}

// Helper: Format status as string
fn format_status(status: SpanStatus) -> String {
  case status {
    SpanOk -> "ok"
    SpanError(msg) -> "error:" <> msg
    Unset -> "unset"
  }
}
