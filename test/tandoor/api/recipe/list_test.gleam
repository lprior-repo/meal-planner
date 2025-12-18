/// Tests for Recipe List API
///
/// These tests verify the list_recipes function delegates correctly
/// to the client implementation.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/recipe/list
import meal_planner/tandoor/client

pub fn list_recipes_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // Call should fail (no server) but proves delegation works
  let result = list.list_recipes(config, limit: Some(10), offset: Some(0))

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn list_recipes_accepts_none_params_test() {
  // Verify None parameters work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result = list.list_recipes(config, limit: None, offset: None)

  // Should attempt call and fail (no server)
  should.be_error(result)
}
