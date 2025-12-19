//// Tests for distributed tracing framework
//// RED phase - these tests should fail until implementation is complete

import gleam/dict
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/observability/tracing
import meal_planner/observability/types.{
  Error as SpanError, Ok as SpanOk, Span, SpanEvent, Unset,
}

pub fn main() {
  gleeunit.main()
}

pub fn create_span_test() {
  let attributes =
    dict.new()
    |> dict.insert("db.system", "postgresql")

  let span =
    tracing.start_span(
      trace_id: "trace-123",
      span_id: "span-456",
      parent_span_id: None,
      name: "database_query",
      attributes: attributes,
    )

  span.trace_id
  |> should.equal("trace-123")

  span.span_id
  |> should.equal("span-456")

  span.name
  |> should.equal("database_query")

  span.parent_span_id
  |> should.equal(None)

  span.end_time
  |> should.equal(None)
}

pub fn create_child_span_test() {
  let parent_span =
    tracing.start_span(
      trace_id: "trace-abc",
      span_id: "span-parent",
      parent_span_id: None,
      name: "http_request",
      attributes: dict.new(),
    )

  let child_span =
    tracing.start_span(
      trace_id: "trace-abc",
      span_id: "span-child",
      parent_span_id: Some(parent_span.span_id),
      name: "db_query",
      attributes: dict.new(),
    )

  child_span.parent_span_id
  |> should.equal(Some("span-parent"))

  child_span.trace_id
  |> should.equal(parent_span.trace_id)
}

pub fn end_span_test() {
  let span =
    tracing.start_span(
      trace_id: "trace-1",
      span_id: "span-1",
      parent_span_id: None,
      name: "operation",
      attributes: dict.new(),
    )

  span.end_time
  |> should.equal(None)

  let ended = tracing.end_span(span)

  case ended.end_time {
    Some(_timestamp) -> should.be_ok()
    None -> should.fail()
  }
}

pub fn add_span_event_test() {
  let span =
    tracing.start_span(
      trace_id: "trace-2",
      span_id: "span-2",
      parent_span_id: None,
      name: "request",
      attributes: dict.new(),
    )

  let event_attrs =
    dict.new()
    |> dict.insert("query", "SELECT * FROM users")

  let updated =
    tracing.add_event(span, name: "query_prepared", attributes: event_attrs)

  updated.events
  |> list.is_empty
  |> should.equal(False)
}

pub fn set_span_status_ok_test() {
  let span =
    tracing.start_span(
      trace_id: "trace-3",
      span_id: "span-3",
      parent_span_id: None,
      name: "operation",
      attributes: dict.new(),
    )

  let updated = tracing.set_status(span, SpanOk)

  updated.status
  |> should.equal(SpanOk)
}

pub fn set_span_status_error_test() {
  let span =
    tracing.start_span(
      trace_id: "trace-4",
      span_id: "span-4",
      parent_span_id: None,
      name: "failed_op",
      attributes: dict.new(),
    )

  let updated = tracing.set_status(span, SpanError("Connection timeout"))

  case updated.status {
    SpanError(msg) -> {
      msg
      |> should.equal("Connection timeout")
    }
    _ -> should.fail()
  }
}

pub fn generate_trace_id_test() {
  let trace_id = tracing.generate_trace_id()

  trace_id
  |> should.not_equal("")

  // Should be different each time
  let trace_id2 = tracing.generate_trace_id()

  trace_id
  |> should.not_equal(trace_id2)
}

pub fn generate_span_id_test() {
  let span_id = tracing.generate_span_id()

  span_id
  |> should.not_equal("")

  // Should be different each time
  let span_id2 = tracing.generate_span_id()

  span_id
  |> should.not_equal(span_id2)
}

pub fn span_duration_test() {
  let span =
    tracing.start_span(
      trace_id: "trace-5",
      span_id: "span-5",
      parent_span_id: None,
      name: "timed_op",
      attributes: dict.new(),
    )

  let ended = tracing.end_span(span)

  let duration = tracing.span_duration_ms(ended)

  case duration {
    Some(d) -> {
      d
      |> should.be_ok()
    }
    None -> should.fail()
  }
}

pub fn add_span_attributes_test() {
  let span =
    tracing.start_span(
      trace_id: "trace-6",
      span_id: "span-6",
      parent_span_id: None,
      name: "op",
      attributes: dict.new(),
    )

  let new_attrs =
    dict.new()
    |> dict.insert("http.method", "GET")
    |> dict.insert("http.status_code", "200")

  let updated = tracing.add_attributes(span, new_attrs)

  dict.get(updated.attributes, "http.method")
  |> should.equal(Ok("GET"))
}
