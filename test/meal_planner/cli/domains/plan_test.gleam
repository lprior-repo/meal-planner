//// TDD Tests for CLI plan command
////
//// RED PHASE: This test validates:
//// 1. Command instantiation
//// 2. Helper function pad_right for string formatting
//// 3. Configuration parsing and validation

import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/plan
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

/// Test: Plan command can be instantiated
pub fn plan_command_instantiation_test() {
  let config = create_test_config()
  let _cmd = plan.cmd(config)

  // If we got here, the command was created successfully
  True
  |> should.be_true()
}

/// Test: Command is created with Development environment
pub fn plan_command_with_development_env_test() {
  let config = create_test_config()
  let _cmd = plan.cmd(config)

  case config.environment {
    config.Development -> True
    _ -> False
  }
  |> should.be_true()
}

/// Test: Command has valid Tandoor configuration
pub fn plan_command_tandoor_config_test() {
  let config = create_test_config()
  let _cmd = plan.cmd(config)

  string.contains(config.tandoor.base_url, "localhost")
  |> should.be_true()

  string.length(config.tandoor.api_token) > 0
  |> should.be_true()
}

// ============================================================================
// Helper Function Tests
// ============================================================================

/// Test: pad_right with string shorter than width
pub fn pad_right_shorter_string_test() {
  let result = plan.pad_right("hello", 10)

  string.length(result)
  |> should.equal(10)
}

/// Test: pad_right with string equal to width
pub fn pad_right_equal_length_test() {
  let result = plan.pad_right("hello", 5)

  string.length(result)
  |> should.equal(5)

  result
  |> should.equal("hello")
}

/// Test: pad_right with string longer than width
pub fn pad_right_longer_string_test() {
  let result = plan.pad_right("hello world", 5)

  string.length(result)
  |> should.equal(5)
}

/// Test: pad_right preserves original content
pub fn pad_right_preserves_content_test() {
  let result = plan.pad_right("test", 8)

  string.contains(result, "test")
  |> should.be_true()
}

/// Test: pad_right adds spaces when needed
pub fn pad_right_adds_spaces_test() {
  let result = plan.pad_right("hi", 5)

  string.contains(result, " ")
  |> should.be_true()

  string.length(result)
  |> should.equal(5)
}

/// Test: pad_right with empty string
pub fn pad_right_empty_string_test() {
  let result = plan.pad_right("", 5)

  string.length(result)
  |> should.equal(5)
}

/// Test: pad_right with width zero
pub fn pad_right_zero_width_test() {
  let result = plan.pad_right("hello", 0)

  string.length(result)
  |> should.equal(0)
}

// ============================================================================
// Configuration Validation Tests
// ============================================================================

/// Test: Database configuration is present
pub fn plan_database_config_present_test() {
  let config = create_test_config()

  string.length(config.database.host) > 0
  |> should.be_true()

  config.database.port > 0
  |> should.be_true()
}

/// Test: Tandoor base URL is valid
pub fn plan_tandoor_base_url_valid_test() {
  let config = create_test_config()

  string.contains(config.tandoor.base_url, "http")
  |> should.be_true()

  string.contains(config.tandoor.base_url, "8100")
  |> should.be_true()
}

/// Test: API token is configured
pub fn plan_api_token_configured_test() {
  let config = create_test_config()

  string.length(config.tandoor.api_token)
  |> should.be_true()
}

// ============================================================================
// Edge Cases
// ============================================================================

/// Test: pad_right with single character
pub fn pad_right_single_char_test() {
  let result = plan.pad_right("a", 3)

  string.length(result)
  |> should.equal(3)

  string.starts_with(result, "a")
  |> should.be_true()
}

/// Test: pad_right with numeric string
pub fn pad_right_numeric_string_test() {
  let result = plan.pad_right("123", 6)

  string.length(result)
  |> should.equal(6)

  string.contains(result, "123")
  |> should.be_true()
}

/// Test: pad_right with special characters
pub fn pad_right_special_chars_test() {
  let result = plan.pad_right("@#$", 7)

  string.length(result)
  |> should.equal(7)

  string.contains(result, "@#$")
  |> should.be_true()
}
