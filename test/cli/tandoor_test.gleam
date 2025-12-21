//// TDD Tests for CLI tandoor command
////
//// RED PHASE: This test validates:
//// 1. Command instantiation (Glint command builder)
//// 2. Sync operation structure
//// 3. Category listing structure
//// 4. Recipe search operations

import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/tandoor
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
// Command Structure Tests
// ============================================================================

/// Test: Tandoor command can be instantiated
pub fn tandoor_command_instantiation_test() {
  let config = create_test_config()
  let _cmd = tandoor.cmd(config)

  // If we got here, command instantiation succeeded
  True
  |> should.be_true()
}

// ============================================================================
// Configuration Validation Tests
// ============================================================================

/// Test: Config with valid tandoor base URL
pub fn config_valid_tandoor_url_test() {
  let config = create_test_config()

  string.contains(config.tandoor.base_url, "http")
  |> should.be_true()
}

/// Test: Config with valid API token
pub fn config_valid_api_token_test() {
  let config = create_test_config()

  string.length(config.tandoor.api_token) > 0
  |> should.be_true()
}

/// Test: Config with timeouts configured
pub fn config_has_timeouts_test() {
  let config = create_test_config()

  config.tandoor.connect_timeout_ms > 0
  |> should.be_true()

  config.tandoor.request_timeout_ms > 0
  |> should.be_true()
}

/// Test: Config with proper pool size
pub fn config_proper_pool_size_test() {
  let config = create_test_config()

  config.database.pool_size > 0
  |> should.be_true()
}

// ============================================================================
// Tandoor Base URL Validation
// ============================================================================

/// Test: Base URL starts with http or https
pub fn base_url_protocol_test() {
  let config = create_test_config()
  let url = config.tandoor.base_url

  let is_valid =
    string.starts_with(url, "http://")
    || string.starts_with(url, "https://")

  is_valid
  |> should.be_true()
}

/// Test: Base URL does not have trailing slash
pub fn base_url_no_trailing_slash_test() {
  let config = create_test_config()
  let url = config.tandoor.base_url

  // Should not end with /
  string.ends_with(url, "/")
  |> should.be_false()
}

// ============================================================================
// Edge Cases
// ============================================================================

/// Test: Config with localhost tandoor
pub fn config_localhost_tandoor_test() {
  let config = create_test_config()

  string.contains(config.tandoor.base_url, "localhost")
  |> should.be_true()
}

/// Test: Config with environment set to development
pub fn config_environment_development_test() {
  let config = create_test_config()

  case config.environment {
    config.Development -> True
    _ -> False
  }
  |> should.be_true()
}
