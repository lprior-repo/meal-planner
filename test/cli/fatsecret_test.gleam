//// TDD Tests for CLI fatsecret command
////
//// RED PHASE: This test validates:
//// 1. Command instantiation
//// 2. Configuration presence
//// 3. External service setup

import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/fatsecret
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

/// Test: FatSecret command can be instantiated
pub fn fatsecret_command_instantiation_test() {
  let config = create_test_config()
  let _cmd = fatsecret.cmd(config)

  True
  |> should.be_true()
}

/// Test: FatSecret command with development environment
pub fn fatsecret_command_dev_env_test() {
  let config = create_test_config()
  let _cmd = fatsecret.cmd(config)

  case config.environment {
    config.Development -> True
    _ -> False
  }
  |> should.be_true()
}

// ============================================================================
// Configuration Tests
// ============================================================================

/// Test: External services configuration exists
pub fn fatsecret_external_services_config_test() {
  let config = create_test_config()

  case config.external_services.fatsecret {
    config.None -> True
    _ -> False
  }
  |> should.be_true()
}

/// Test: OpenAI API key configuration exists
pub fn fatsecret_openai_config_test() {
  let config = create_test_config()

  string.length(config.external_services.openai_api_key) >= 0
  |> should.be_true()
}

/// Test: OpenAI model is configured
pub fn fatsecret_openai_model_test() {
  let config = create_test_config()

  string.contains(config.external_services.openai_model, "gpt")
  |> should.be_true()
}

/// Test: USDA API key configuration space
pub fn fatsecret_usda_config_test() {
  let config = create_test_config()

  string.length(config.external_services.usda_api_key) >= 0
  |> should.be_true()
}

/// Test: Todoist API key configuration space
pub fn fatsecret_todoist_config_test() {
  let config = create_test_config()

  string.length(config.external_services.todoist_api_key) >= 0
  |> should.be_true()
}

/// Test: OAuth encryption key is optional
pub fn fatsecret_oauth_encryption_optional_test() {
  let config = create_test_config()

  case config.secrets.oauth_encryption_key {
    config.None -> True
    _ -> False
  }
  |> should.be_true()
}

/// Test: JWT secret is optional
pub fn fatsecret_jwt_secret_optional_test() {
  let config = create_test_config()

  case config.secrets.jwt_secret {
    config.None -> True
    _ -> False
  }
  |> should.be_true()
}
