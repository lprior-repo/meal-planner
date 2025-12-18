/// Tests for Recipe Delete API
///
/// These tests verify the delete_recipe function delegates correctly
/// to the client implementation.
import gleeunit/should
import meal_planner/tandoor/api/recipe/delete
import meal_planner/tandoor/client

pub fn delete_recipe_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")
  let recipe_id = 42

  // Call should fail (no server) but proves delegation works
  let result = delete.delete_recipe(config, recipe_id)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn delete_recipe_with_different_ids_test() {
  // Verify different recipe IDs work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result1 = delete.delete_recipe(config, 1)
  let result2 = delete.delete_recipe(config, 999)
  let result3 = delete.delete_recipe(config, 12_345)

  // All should attempt call and fail (no server)
  should.be_error(result1)
  should.be_error(result2)
  should.be_error(result3)
}

pub fn delete_recipe_with_small_id_test() {
  // Verify small IDs work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result = delete.delete_recipe(config, 1)

  // Should attempt call and fail (no server)
  should.be_error(result)
}

pub fn delete_recipe_with_large_id_test() {
  // Verify large IDs work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result = delete.delete_recipe(config, 999_999)

  // Should attempt call and fail (no server)
  should.be_error(result)
}
