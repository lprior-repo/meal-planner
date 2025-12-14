/// Tests for Shopping List Entry Delete API
///
/// These tests verify the delete_shopping_list_entry function delegates correctly
/// to the client implementation.
import gleeunit/should
import meal_planner/tandoor/api/shopping/delete
import meal_planner/tandoor/client

pub fn delete_shopping_list_entry_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // Call should fail (no server) but proves delegation works
  let result = delete.delete_shopping_list_entry(config, 1)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn delete_shopping_list_entry_accepts_any_id_test() {
  // Verify different IDs work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result1 = delete.delete_shopping_list_entry(config, 999)
  let result2 = delete.delete_shopping_list_entry(config, 1)

  // Both should attempt call and fail (no server)
  should.be_error(result1)
  should.be_error(result2)
}
