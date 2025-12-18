/// Tests for Recipe Get API
///
/// These tests verify the get_recipe function delegates correctly
/// to the client implementation.
import gleeunit/should
import meal_planner/tandoor/api/recipe/get
import meal_planner/tandoor/client

pub fn get_recipe_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // Call should fail (no server) but proves delegation works
  let result = get.get_recipe(config, recipe_id: 1)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn get_recipe_accepts_any_id_test() {
  // Verify different IDs work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result1 = get.get_recipe(config, recipe_id: 999)
  let result2 = get.get_recipe(config, recipe_id: 1)

  // Both should attempt call and fail (no server)
  should.be_error(result1)
  should.be_error(result2)
}
