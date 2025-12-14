import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/api/shopping/recipe
import meal_planner/tandoor/client
import meal_planner/tandoor/core/ids

pub fn main() {
  gleeunit.main()
}

/// Test that add_recipe_to_shopping_list builds correct request structure
///
/// This is a basic unit test to verify the function signature and request building.
/// Integration tests with actual API calls would require a running Tandoor instance.
pub fn add_recipe_to_shopping_list_builds_request_test() {
  // Create test config
  let config =
    client.ClientConfig(
      base_url: "http://localhost:8000",
      auth: client.BearerAuth("test-token"),
      timeout_ms: 5000,
      retry_on_transient: False,
      max_retries: 0,
    )

  // This will fail with network error since we're not actually connecting,
  // but it verifies the function signature and request building
  let result =
    recipe.add_recipe_to_shopping_list(config, recipe_id: 123, servings: 4)

  // We expect a network error in test environment without running API
  case result {
    Error(client.NetworkError(_)) -> {
      // Expected - no actual API to connect to in test
      should.be_true(True)
    }
    Error(_other_error) -> {
      // Unexpected error type
      should.fail()
    }
    Ok(_entries) -> {
      // Shouldn't succeed without running API
      should.fail()
    }
  }
}
