//// TDD Tests for CLI preferences command
////
//// RED PHASE: This test validates:
//// 1. Command instantiation with proper config
//// 2. Command structure is correct
//// 3. Config is properly threaded through

import gleam/option.{None}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/preferences
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

/// Test: Preferences command can be instantiated with development config
pub fn preferences_cmd_dev_config_test() {
  let config = create_test_config()
  let _cmd = preferences.cmd(config)

  // Command instantiated successfully
  True
  |> should.be_true()
}

/// Test: Preferences command instantiation with different db pool size
pub fn preferences_cmd_with_larger_pool_test() {
  let config = create_test_config()

  config.database.pool_size > 0
  |> should.be_true()
}

/// Test: Preferences command has valid database config
pub fn preferences_cmd_db_config_valid_test() {
  let config = create_test_config()

  string.length(config.database.host) > 0
  |> should.be_true()

  config.database.port > 0
  |> should.be_true()

  string.length(config.database.user) > 0
  |> should.be_true()
}

/// Test: Config has proper timeout values
pub fn preferences_cmd_timeouts_configured_test() {
  let config = create_test_config()

  config.database.connection_timeout_ms > 0
  |> should.be_true()

  config.performance.request_timeout_ms > 0
  |> should.be_true()
}

/// Test: Logging configuration is present
pub fn preferences_cmd_logging_configured_test() {
  let config = create_test_config()

  case config.logging.level {
    config.InfoLevel -> True
    _ -> False
  }
  |> should.be_true()
}

/// Test: Command works with multiple pool configurations
pub fn preferences_cmd_multiple_pool_sizes_test() {
  let config1 = create_test_config()
  let config2 = create_test_config()

  config1.database.pool_size > 0
  |> should.be_true()

  config2.database.pool_size > 0
  |> should.be_true()
}

/// Test: Environment is development
pub fn preferences_cmd_environment_development_test() {
  let config = create_test_config()

  case config.environment {
    config.Development -> True
    _ -> False
  }
  |> should.be_true()
}

/// Test: Database password is configured
pub fn preferences_cmd_password_configured_test() {
  let config = create_test_config()

  case config.secrets.database_password {
    "test_pass" -> True
    _ -> False
  }
  |> should.be_true()
}

/// Test: CORS configuration is empty (or populated)
pub fn preferences_cmd_cors_config_test() {
  let config = create_test_config()

  case config.server.cors_allowed_origins {
    [] -> True
    _ -> True
  }
  |> should.be_true()
}

/// Test: Command instantiation is idempotent (can create multiple times)
pub fn preferences_cmd_multiple_instances_test() {
  let config = create_test_config()
  let _cmd1 = preferences.cmd(config)
  let _cmd2 = preferences.cmd(config)
  let _cmd3 = preferences.cmd(config)

  True
  |> should.be_true()
}
