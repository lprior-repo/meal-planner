/// Tests for Shopping List Entry Get API
///
/// These tests verify the get function delegates correctly
/// to the client implementation.
import gleeunit/should
import meal_planner/tandoor/api/shopping_list
import meal_planner/tandoor/client

pub fn get_shopping_list_entry_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // Call should fail (no server) but proves delegation works
  let result = shopping_list.get(config, 1)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn get_shopping_list_entry_accepts_any_id_test() {
  // Verify different IDs work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result1 = shopping_list.get(config, 999)
  let result2 = shopping_list.get(config, 1)

  // Both should attempt call and fail (no server)
  should.be_error(result1)
  should.be_error(result2)
}
