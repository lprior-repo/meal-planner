//// TDD Tests for CLI web command
////
//// RED PHASE: This test validates:
//// 1. Web domain command creation and help text
//// 2. Configuration display functionality
//// 3. Proper Glint command registration

import gleam/option.{None, Some}
import gleeunit
import meal_planner/cli/domains/web
import meal_planner/config
import meal_planner/config/database.{DatabaseConfig}
import meal_planner/config/environment.{DebugLevel, Development}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Create a minimal test configuration
fn create_test_config() -> config.Config {
  config.Config(
    environment: Development,
    server: config.ServerConfig(port: 8080, cors_allowed_origins: []),
    database: DatabaseConfig(
      host: "localhost",
      port: 5432,
      name: "meal_planner",
      user: "test",
      password: "test",
      pool_size: 5,
      connection_timeout_ms: 5000,
    ),
    tandoor: config.TandoorConfig(
      base_url: "http://tandoor:8000",
      api_token: "test-token",
      connect_timeout_ms: 5000,
      request_timeout_ms: 30_000,
    ),
    external_services: config.ExternalServicesConfig(
      fatsecret: Some(config.FatSecretConfig(
        consumer_key: "test-key",
        consumer_secret: "test-secret",
      )),
      todoist_api_key: "",
      usda_api_key: "",
      openai_api_key: "",
      openai_model: "gpt-4",
    ),
    secrets: config.SecretsConfig(
      oauth_encryption_key: None,
      jwt_secret: None,
      database_password: "test",
      tandoor_token: "test-token",
    ),
    logging: config.LoggingConfig(level: DebugLevel, debug_mode: True),
    performance: config.PerformanceConfig(
      request_timeout_ms: 30_000,
      connection_timeout_ms: 5000,
      max_concurrent_requests: 10,
      rate_limit_requests: 100,
    ),
  )
}

// ============================================================================
// Web Command Tests
// ============================================================================

/// Test: cmd creates a valid Glint command
pub fn cmd_creates_command_test() {
  let config = create_test_config()
  let _command = web.cmd(config)
  // If we get here without panic, command was created successfully
  Nil
}
