//// Tests for structured logging framework
//// RED phase - these tests should fail until implementation is complete

import gleam/dict
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import logging
import meal_planner/observability/structured_logging
import meal_planner/observability/types.{LogContext, LogEntry}

pub fn main() {
  gleeunit.main()
}

pub fn create_log_context_test() {
  let context =
    structured_logging.new_context(
      service: "meal-planner-test",
      trace_id: Some("trace-123"),
      span_id: Some("span-456"),
      user_id: Some("user-789"),
      request_id: Some("req-abc"),
    )

  context.service
  |> should.equal("meal-planner-test")

  context.trace_id
  |> should.equal(Some("trace-123"))

  context.span_id
  |> should.equal(Some("span-456"))

  context.user_id
  |> should.equal(Some("user-789"))

  context.request_id
  |> should.equal(Some("req-abc"))
}

pub fn create_log_entry_test() {
  let context =
    structured_logging.new_context(
      service: "test-service",
      trace_id: None,
      span_id: None,
      user_id: None,
      request_id: None,
    )

  let metadata =
    dict.new()
    |> dict.insert("key1", "value1")
    |> dict.insert("key2", "value2")

  let entry =
    structured_logging.create_log_entry(
      level: logging.Info,
      message: "Test message",
      context: context,
      metadata: metadata,
    )

  entry.level
  |> should.equal(logging.Info)

  entry.message
  |> should.equal("Test message")

  entry.context.service
  |> should.equal("test-service")

  dict.get(entry.metadata, "key1")
  |> should.equal(Ok("value1"))

  dict.get(entry.metadata, "key2")
  |> should.equal(Ok("value2"))
}

pub fn log_with_context_info_test() {
  let context =
    structured_logging.new_context(
      service: "meal-planner",
      trace_id: Some("trace-xyz"),
      span_id: None,
      user_id: None,
      request_id: None,
    )

  let metadata =
    dict.new()
    |> dict.insert("endpoint", "/api/recipes")

  // Should successfully log without panic
  structured_logging.log_with_context(
    level: logging.Info,
    message: "Recipe fetched",
    context: context,
    metadata: metadata,
  )
  |> should.equal(Nil)
}

pub fn log_with_context_error_test() {
  let context =
    structured_logging.new_context(
      service: "meal-planner",
      trace_id: Some("trace-error"),
      span_id: None,
      user_id: Some("user-123"),
      request_id: None,
    )

  let metadata =
    dict.new()
    |> dict.insert("error_code", "DB_CONN_FAILED")

  structured_logging.log_with_context(
    level: logging.Error,
    message: "Database connection failed",
    context: context,
    metadata: metadata,
  )
  |> should.equal(Nil)
}

pub fn format_log_entry_as_json_test() {
  let context =
    structured_logging.new_context(
      service: "test",
      trace_id: Some("t1"),
      span_id: Some("s1"),
      user_id: None,
      request_id: None,
    )

  let metadata =
    dict.new()
    |> dict.insert("key", "value")

  let entry =
    structured_logging.create_log_entry(
      level: logging.Info,
      message: "Test",
      context: context,
      metadata: metadata,
    )

  let json = structured_logging.format_as_json(entry)

  // Should contain expected fields
  json
  |> should.not_equal("")

  // Should be valid JSON (basic check - contains braces)
  json
  |> should.be_ok
}

pub fn add_metadata_to_context_test() {
  let context =
    structured_logging.new_context(
      service: "test",
      trace_id: None,
      span_id: None,
      user_id: None,
      request_id: None,
    )

  let metadata =
    dict.new()
    |> dict.insert("ip", "127.0.0.1")

  let updated = structured_logging.with_metadata(context, metadata)

  // Context should be unchanged (immutable)
  context.service
  |> should.equal("test")

  // Should return updated context for chaining
  updated.service
  |> should.equal("test")
}

pub fn empty_context_test() {
  let context = structured_logging.empty_context("minimal-service")

  context.service
  |> should.equal("minimal-service")

  context.trace_id
  |> should.equal(None)

  context.span_id
  |> should.equal(None)

  context.user_id
  |> should.equal(None)

  context.request_id
  |> should.equal(None)
}
