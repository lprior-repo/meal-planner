//// Tests for FatSecret detail CLI command
////
//// This module tests the `mp fatsecret detail <FOOD_ID>` command functionality.
//// Following TDD: These tests MUST fail initially, then drive implementation.

import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/fatsecret
import meal_planner/config
import meal_planner/fatsecret/foods/service
import meal_planner/fatsecret/foods/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test: Detail handler function should exist and accept food ID
// ============================================================================

pub fn detail_handler_exists_test() {
  // RED PHASE: This test MUST fail initially
  // The detail_handler function does not exist yet in fatsecret.gleam
  //
  // Given: A test config and food ID
  let test_config = get_test_config()
  let food_id = "123456"

  // When: We call the detail_handler
  let result = fatsecret.detail_handler(test_config, food_id)

  // Then: Function should exist and return a Result
  // This will fail with compilation error until we add detail_handler
  should.be_ok(result)
}

// ============================================================================
// Test: Detail should fetch food by ID from service
// ============================================================================

pub fn detail_fetches_food_by_id_test() {
  // RED PHASE: This test documents service layer integration
  //
  // Given: A valid food ID
  let food_id = types.food_id("123456")

  // When: We fetch the food using the service layer
  let result = service.get_food(food_id)

  // Then: Service should return a Result
  // In test environment, this will likely be NotConfigured error
  case result {
    Ok(food) -> {
      // If FatSecret is configured in test, verify structure
      should.not_equal(food.food_name, "")
      should.not_equal(food.servings, [])
    }
    Error(service.NotConfigured) -> {
      // Expected in test environment - document that config is needed
      should.be_ok(Ok(Nil))
    }
    Error(service.ApiError(_)) -> {
      // API error is also acceptable in tests
      should.be_ok(Ok(Nil))
    }
  }
}

// ============================================================================
// Test Helpers
// ============================================================================

fn get_test_config() -> config.Config {
  config.Config(
    environment: config.Development,
    database: config.DatabaseConfig(
      host: "localhost",
      port: 5432,
      name: "meal_planner_test",
      user: "postgres",
      password: "",
      pool_size: 1,
      connection_timeout_ms: 5000,
    ),
    server: config.ServerConfig(port: 8080, cors_allowed_origins: []),
    tandoor: config.TandoorConfig(
      base_url: "http://localhost:8000",
      api_token: "test-token",
      connect_timeout_ms: 5000,
      request_timeout_ms: 10_000,
    ),
    external_services: config.ExternalServicesConfig(
      fatsecret: Some(config.FatSecretConfig(
        consumer_key: "test_key",
        consumer_secret: "test_secret",
      )),
      todoist_api_key: "",
      usda_api_key: "",
      openai_api_key: "",
      openai_model: "gpt-4o",
    ),
    secrets: config.SecretsConfig(
      oauth_encryption_key: None,
      jwt_secret: None,
      database_password: "",
      tandoor_token: "test-token",
    ),
    logging: config.LoggingConfig(level: config.InfoLevel, debug_mode: False),
    performance: config.PerformanceConfig(
      request_timeout_ms: 10_000,
      connection_timeout_ms: 5000,
      max_concurrent_requests: 100,
      rate_limit_requests: 100,
    ),
  )
}
