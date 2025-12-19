/// Tests for tandoor CLI domain
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/domains/tandoor
import meal_planner/config.{type Config, Config, TandoorConfig}

/// Mock config for testing
fn mock_config() -> Config {
  Config(
    database: config.DatabaseConfig(
      host: "localhost",
      port: 5432,
      name: "test_db",
      user: "test_user",
      password: Some("test_pass"),
    ),
    server: config.ServerConfig(host: "localhost", port: 8080),
    tandoor: TandoorConfig(
      base_url: "http://localhost:8000",
      api_token: "test_token",
      connect_timeout_ms: 5000,
      request_timeout_ms: 30_000,
    ),
    external_services: config.ExternalServicesConfig(
      fatsecret_consumer_key: None,
      fatsecret_consumer_secret: None,
    ),
  )
}

pub fn parse_delete_command_with_id_test() {
  // Test that delete command extracts ID from --id flag
  let result = tandoor.parse_delete_args(["delete"], id: Some(42))

  result
  |> should.be_ok
  |> should.equal(42)
}

pub fn parse_delete_command_missing_id_test() {
  // Test that delete command fails without --id flag
  let result = tandoor.parse_delete_args(["delete"], id: None)

  result
  |> should.be_error
}

pub fn delete_recipe_success_test() {
  // This test will fail until we implement the actual delete function
  // For now, we're just testing the structure
  let config = mock_config()
  let result = tandoor.delete_recipe_command(config, recipe_id: 42)

  // Should return Ok when deletion succeeds
  result
  |> should.be_ok
}

// ============================================================================
// Get Command Tests
// ============================================================================

pub fn parse_get_command_with_id_test() {
  // Test that get command extracts ID from --id flag
  let result = tandoor.parse_get_args(["get"], id: Some(123))

  result
  |> should.be_ok
  |> should.equal(123)
}

pub fn parse_get_command_missing_id_test() {
  // Test that get command fails without --id flag
  let result = tandoor.parse_get_args(["get"], id: None)

  result
  |> should.be_error
}

pub fn get_recipe_success_test() {
  // This test will fail until we implement the actual get function
  // For now, we're testing that the function signature exists
  let config = mock_config()
  let result = tandoor.get_recipe_command(config, recipe_id: 123)

  // Should return Ok with recipe details when fetch succeeds
  result
  |> should.be_ok
}

// ============================================================================
// Search Command Tests
// ============================================================================

pub fn parse_search_command_with_query_test() {
  // Test that search command extracts query from --query flag
  let result = tandoor.parse_search_args(["search"], query: Some("pasta"))

  result
  |> should.be_ok
  |> should.equal("pasta")
}

pub fn parse_search_command_missing_query_test() {
  // Test that search command fails without --query flag
  let result = tandoor.parse_search_args(["search"], query: None)

  result
  |> should.be_error
}
