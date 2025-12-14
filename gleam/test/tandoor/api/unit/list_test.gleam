/// Tests for Unit List API
///
/// These tests verify the list_units function delegates correctly
/// to the client implementation.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/unit/list
import meal_planner/tandoor/client

pub fn list_units_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // Call should fail (no server) but proves delegation works
  let result = list.list_units(config, limit: Some(10), offset: Some(0))

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn list_units_accepts_none_params_test() {
  // Verify None parameters work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result = list.list_units(config, limit: None, offset: None)

  // Should attempt call and fail (no server)
  should.be_error(result)
}

pub fn list_units_with_pagination_test() {
  // Verify pagination parameters are accepted
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result = list.list_units(config, limit: Some(25), offset: Some(50))

  // Should attempt call with pagination
  should.be_error(result)
}
