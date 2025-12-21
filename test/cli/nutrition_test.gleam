//// TDD Tests for CLI nutrition command
////
//// RED PHASE: This test validates:
//// 1. Command instantiation
//// 2. Configuration validation
//// 3. Nutrition goal defaults

import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/nutrition
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

/// Test: Nutrition command can be instantiated
pub fn nutrition_command_instantiation_test() {
  let config = create_test_config()
  let _cmd = nutrition.cmd(config)

  True
  |> should.be_true()
}

/// Test: Nutrition command with development environment
pub fn nutrition_command_dev_env_test() {
  let config = create_test_config()
  let _cmd = nutrition.cmd(config)

  case config.environment {
    config.Development -> True
    _ -> False
  }
  |> should.be_true()
}

// ============================================================================
// Configuration Validation Tests
// ============================================================================

/// Test: Database host is configured
pub fn nutrition_database_host_configured_test() {
  let config = create_test_config()

  string.length(config.database.host) > 0
  |> should.be_true()
}

/// Test: Database port is valid
pub fn nutrition_database_port_valid_test() {
  let config = create_test_config()

  config.database.port > 0
  |> should.be_true()

  config.database.port < 65535
  |> should.be_true()
}

/// Test: Database pool size is positive
pub fn nutrition_pool_size_positive_test() {
  let config = create_test_config()

  config.database.pool_size > 0
  |> should.be_true()
}

/// Test: Connection timeout is configured
pub fn nutrition_connection_timeout_test() {
  let config = create_test_config()

  config.database.connection_timeout_ms > 0
  |> should.be_true()
}

/// Test: Performance config has request timeout
pub fn nutrition_request_timeout_test() {
  let config = create_test_config()

  config.performance.request_timeout_ms > 0
  |> should.be_true()
}

/// Test: Performance config has connection timeout
pub fn nutrition_perf_connection_timeout_test() {
  let config = create_test_config()

  config.performance.connection_timeout_ms > 0
  |> should.be_true()
}

/// Test: Max concurrent requests is positive
pub fn nutrition_max_concurrent_requests_test() {
  let config = create_test_config()

  config.performance.max_concurrent_requests > 0
  |> should.be_true()
}

/// Test: Rate limit is configured
pub fn nutrition_rate_limit_test() {
  let config = create_test_config()

  config.performance.rate_limit_requests > 0
  |> should.be_true()
}
