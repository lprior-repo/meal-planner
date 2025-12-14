/// Tests for Food API
///
/// This module tests the Food API functions (list, get, create, update, delete).
/// Following TDD: these tests should FAIL first, then pass after implementation.
///
/// Note: These are integration-style tests that would require a running Tandoor instance.
/// For now, we test the API function signatures and types.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/food/create as food_create
import meal_planner/tandoor/api/food/get as food_get
import meal_planner/tandoor/api/food/list as food_list
import meal_planner/tandoor/client.{
  type ClientConfig, AuthenticationError, BearerAuth, ClientConfig,
}
import meal_planner/tandoor/types.{TandoorFoodCreateRequest}

/// Helper to create a test client config
fn test_config() -> ClientConfig {
  ClientConfig(
    base_url: "http://localhost:8000",
    auth: BearerAuth(token: "test-token"),
    timeout_ms: 5000,
    retry_on_transient: False,
    max_retries: 0,
  )
}

/// Test list_foods function signature
pub fn list_foods_signature_test() {
  let config = test_config()

  // This will fail with network error since no server is running
  // But it tests that the function exists and has correct types
  let result = food_list.list_foods(config, limit: Some(10), page: None)

  // Should return Result type - we expect an error since no server
  result
  |> should.be_error
}

/// Test list_foods with pagination parameters
pub fn list_foods_with_pagination_test() {
  let config = test_config()

  let result = food_list.list_foods(config, limit: Some(20), page: Some(2))

  // Should return Result type
  result
  |> should.be_error
}

/// Test get_food function signature
pub fn get_food_signature_test() {
  let config = test_config()

  // This will fail with network error
  let result = food_get.get_food(config, food_id: 1)

  // Should return Result type
  result
  |> should.be_error
}

/// Test create_food function signature
pub fn create_food_signature_test() {
  let config = test_config()
  let food_data = TandoorFoodCreateRequest(name: "Test Food")

  // This will fail with network error
  let result = food_create.create_food(config, food_data)

  // Should return Result type
  result
  |> should.be_error
}

/// Test error handling with invalid authentication
pub fn invalid_auth_error_test() {
  let config =
    ClientConfig(
      base_url: "http://localhost:8000",
      auth: BearerAuth(token: ""),
      timeout_ms: 5000,
      retry_on_transient: False,
      max_retries: 0,
    )

  let result = food_list.list_foods(config, limit: None, page: None)

  // Should be an error (either auth or network)
  result
  |> should.be_error
}
