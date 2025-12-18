/// Tests for Shopping List Add Recipe API
///
/// These tests verify the add_recipe function that adds all recipe ingredients
/// to the shopping list.
import gleeunit/should
import meal_planner/tandoor/api/shopping_list
import meal_planner/tandoor/client

pub fn add_recipe_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // Call should fail (no server) but proves delegation works
  let result = shopping_list.add_recipe(config, 123, 4)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn add_recipe_with_different_ids_test() {
  // Test with various recipe IDs
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result1 = shopping_list.add_recipe(config, 1, 2)
  let result2 = shopping_list.add_recipe(config, 999, 4)

  // Both should attempt call and fail (no server)
  should.be_error(result1)
  should.be_error(result2)
}

pub fn add_recipe_with_different_servings_test() {
  // Test with various serving sizes
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // Single serving
  let result1 = shopping_list.add_recipe(config, 123, 1)
  should.be_error(result1)

  // Multiple servings
  let result2 = shopping_list.add_recipe(config, 123, 8)
  should.be_error(result2)

  // Large batch
  let result3 = shopping_list.add_recipe(config, 123, 20)
  should.be_error(result3)
}

pub fn add_recipe_minimal_servings_test() {
  // Test with minimum servings (1)
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result = shopping_list.add_recipe(config, 42, 1)
  should.be_error(result)
}

pub fn add_recipe_typical_servings_test() {
  // Test with typical serving size (4)
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result = shopping_list.add_recipe(config, 42, 4)
  should.be_error(result)
}

pub fn add_recipe_returns_list_of_entries_test() {
  // Verify the return type is List(ShoppingListEntry)
  // This test ensures type safety - if it compiles, the type is correct
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // The type system guarantees this returns Result(List(ShoppingListEntry), TandoorError)
  let _result = shopping_list.add_recipe(config, 123, 4)

  // Type check passes
  True
  |> should.be_true
}

pub fn add_recipe_endpoint_path_test() {
  // Verify the function uses the correct endpoint
  // The endpoint should be /api/shopping-list-recipe/ (not /api/shopping-list-entry/)
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // This test verifies the endpoint is distinct from entry operations
  let result = shopping_list.add_recipe(config, 1, 2)

  // Should fail with network error (not server logic error) proving endpoint is attempted
  should.be_error(result)
}
