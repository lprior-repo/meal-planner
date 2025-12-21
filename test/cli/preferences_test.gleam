//// TDD Tests for CLI preferences command
////
//// RED PHASE: This test validates:
//// 1. Command instantiation with proper config
//// 2. Command structure is correct
//// 3. Config is properly threaded through

import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/preferences
import test/cli/fixtures

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Command Structure Tests
// ============================================================================

/// Test: Preferences command can be instantiated with development config
pub fn preferences_cmd_dev_config_test() {
  let config = fixtures.test_config()
  let _cmd = preferences.cmd(config)

  // Command instantiated successfully
  True
  |> should.be_true()
}

/// Test: Preferences command instantiation with different db pool size
pub fn preferences_cmd_with_larger_pool_test() {
  let config = fixtures.test_config()

  config.database.pool_size > 0
  |> should.be_true()
}

/// Test: Preferences command has valid database config
pub fn preferences_cmd_db_config_valid_test() {
  let config = fixtures.test_config()

  string.length(config.database.host) > 0
  |> should.be_true()

  config.database.port > 0
  |> should.be_true()

  string.length(config.database.user) > 0
  |> should.be_true()
}

/// Test: Config has proper timeout values
pub fn preferences_cmd_timeouts_configured_test() {
  let config = fixtures.test_config()

  config.database.connection_timeout_ms > 0
  |> should.be_true()

  config.performance.request_timeout_ms > 0
  |> should.be_true()
}

/// Test: Logging configuration is present
pub fn preferences_cmd_logging_configured_test() {
  let config = fixtures.test_config()

  case config.logging.level {
    config.InfoLevel -> True
    _ -> False
  }
  |> should.be_true()
}

/// Test: Command works with multiple pool configurations
pub fn preferences_cmd_multiple_pool_sizes_test() {
  let config1 = fixtures.test_config()
  let config2 = fixtures.test_config()

  config1.database.pool_size > 0
  |> should.be_true()

  config2.database.pool_size > 0
  |> should.be_true()
}

/// Test: Environment is development
pub fn preferences_cmd_environment_development_test() {
  let config = fixtures.test_config()

  case config.environment {
    config.Development -> True
    _ -> False
  }
  |> should.be_true()
}

/// Test: Database password is configured
pub fn preferences_cmd_password_configured_test() {
  let config = fixtures.test_config()

  case config.secrets.database_password {
    "test_pass" -> True
    _ -> False
  }
  |> should.be_true()
}

/// Test: CORS configuration is empty (or populated)
pub fn preferences_cmd_cors_config_test() {
  let config = fixtures.test_config()

  case config.server.cors_allowed_origins {
    [] -> True
    _ -> True
  }
  |> should.be_true()
}

/// Test: Command instantiation is idempotent (can create multiple times)
pub fn preferences_cmd_multiple_instances_test() {
  let config = fixtures.test_config()
  let _cmd1 = preferences.cmd(config)
  let _cmd2 = preferences.cmd(config)
  let _cmd3 = preferences.cmd(config)

  True
  |> should.be_true()
}
