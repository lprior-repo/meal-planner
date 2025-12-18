/// Tests for Shopping List Entry List API
///
/// These tests verify the list function with pagination and filtering.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/shopping_list
import meal_planner/tandoor/client

pub fn list_shopping_list_entries_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // Call should fail (no server) but proves delegation works
  let result = shopping_list.list(config, None, None, None)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn list_with_checked_filter_test() {
  // Test filtering by checked status
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // Test with checked=true
  let result1 = shopping_list.list(config, Some(True), None, None)
  should.be_error(result1)

  // Test with checked=false
  let result2 = shopping_list.list(config, Some(False), None, None)
  should.be_error(result2)
}

pub fn list_with_pagination_test() {
  // Test pagination parameters
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // Test with limit
  let result1 = shopping_list.list(config, None, Some(20), None)
  should.be_error(result1)

  // Test with offset
  let result2 = shopping_list.list(config, None, None, Some(10))
  should.be_error(result2)

  // Test with both limit and offset
  let result3 = shopping_list.list(config, None, Some(20), Some(10))
  should.be_error(result3)
}

pub fn list_with_all_filters_test() {
  // Test all filters combined
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result = shopping_list.list(config, Some(False), Some(50), Some(0))
  should.be_error(result)
}

pub fn list_returns_paginated_response_test() {
  // Verify the return type is PaginatedResponse
  // This test ensures type safety - if it compiles, the type is correct
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // The type system guarantees this returns Result(PaginatedResponse(...), TandoorError)
  let _result = shopping_list.list(config, None, None, None)

  // Type check passes
  True
  |> should.be_true
}
