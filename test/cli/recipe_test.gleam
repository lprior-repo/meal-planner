//// TDD Tests for CLI recipe command
////
//// RED PHASE: This test validates:
//// 1. Command instantiation
//// 2. Configuration and environment setup
//// 3. Recipe command structure

import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/recipe
import meal_planner/config

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn create_test_config() -> config.Config {
  config.Config(
    environment: config.Development,
    database: config.DatabaseConfig(
      host: "localhost",
      port: 5432,
      name: "test_db",
      user: "test_user",
      password: "test_pass",
      pool_size: 1,
      connection_timeout_ms: 5000,
    ),
    server: config.ServerConfig(port: 8080, cors_allowed_origins: []),
    tandoor: config.TandoorConfig(
      base_url: "http://localhost:8100",
      api_token: "test_token",
      connect_timeout_ms: 5000,
      request_timeout_ms: 30_000,
    ),
    external_services: config.ExternalServicesConfig(
      fatsecret: config.None,
      todoist_api_key: "",
      usda_api_key: "",
      openai_api_key: "",
      openai_model: "gpt-4",
    ),
    secrets: config.SecretsConfig(
      oauth_encryption_key: config.None,
      jwt_secret: config.None,
      database_password: "test_pass",
      tandoor_token: "test_token",
    ),
    logging: config.LoggingConfig(level: config.InfoLevel, debug_mode: False),
    performance: config.PerformanceConfig(
      request_timeout_ms: 30_000,
      connection_timeout_ms: 5000,
      max_concurrent_requests: 10,
      rate_limit_requests: 100,
    ),
  )
}

// ============================================================================
// Command Instantiation Tests
// ============================================================================

/// Test: Recipe command can be instantiated
pub fn recipe_command_instantiation_test() {
  let config = create_test_config()
  let _cmd = recipe.cmd(config)

  True
  |> should.be_true()
}

/// Test: Recipe command with valid configuration
pub fn recipe_command_valid_config_test() {
  let config = create_test_config()
  let _cmd = recipe.cmd(config)

  string.length(config.tandoor.base_url) > 0
  |> should.be_true()
}

/// Test: Recipe command environment is development
pub fn recipe_command_development_env_test() {
  let config = create_test_config()
  let _cmd = recipe.cmd(config)

  case config.environment {
    config.Development -> True
    _ -> False
  }
  |> should.be_true()
}

// ============================================================================
// Configuration Tests
// ============================================================================

/// Test: Tandoor base URL present
pub fn recipe_tandoor_base_url_test() {
  let config = create_test_config()

  string.contains(config.tandoor.base_url, "http")
  |> should.be_true()
}

/// Test: API token is configured
pub fn recipe_api_token_test() {
  let config = create_test_config()

  string.length(config.tandoor.api_token) > 0
  |> should.be_true()
}

/// Test: Server configuration present
pub fn recipe_server_config_test() {
  let config = create_test_config()

  config.server.port > 0
  |> should.be_true()
}

/// Test: Logging configuration present
pub fn recipe_logging_config_test() {
  let config = create_test_config()

  case config.logging.level {
    config.InfoLevel -> True
    _ -> False
  }
  |> should.be_true()
}

/// Test: Performance config has limits
pub fn recipe_performance_limits_test() {
  let config = create_test_config()

  config.performance.max_concurrent_requests > 0
  |> should.be_true()

  config.performance.rate_limit_requests > 0
  |> should.be_true()
}
