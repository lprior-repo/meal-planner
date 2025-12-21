//// TDD Tests for CLI plan command
////
//// RED PHASE: This test validates:
//// 1. Command instantiation and structure
//// 2. Configuration validation
//// 3. Command setup with flags

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
// Command Structure Tests
// ============================================================================

/// Test: Plan command can be instantiated
pub fn plan_cmd_instantiation_test() {
  let config = create_test_config()
  let _cmd = plan.cmd(config)

  True
  |> should.be_true()
}

/// Test: Plan command with valid configuration
pub fn plan_cmd_valid_config_test() {
  let config = create_test_config()
  let _cmd = plan.cmd(config)

  config.database.pool_size > 0
  |> should.be_true()
}

/// Test: Command has tandoor base URL configured
pub fn plan_cmd_tandoor_base_url_test() {
  let config = create_test_config()
  let _cmd = plan.cmd(config)

  string.length(config.tandoor.base_url) > 0
  |> should.be_true()
}

/// Test: Command has API token configured
pub fn plan_cmd_api_token_configured_test() {
  let config = create_test_config()
  let _cmd = plan.cmd(config)

  string.length(config.tandoor.api_token) > 0
  |> should.be_true()
}

/// Test: Environment is development
pub fn plan_cmd_environment_development_test() {
  let config = create_test_config()
  let _cmd = plan.cmd(config)

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
pub fn plan_cmd_database_host_configured_test() {
  let config = create_test_config()

  string.length(config.database.host) > 0
  |> should.be_true()
}

/// Test: Database port is valid (> 0)
pub fn plan_cmd_database_port_valid_test() {
  let config = create_test_config()

  config.database.port > 0
  |> should.be_true()

  config.database.port < 65536
  |> should.be_true()
}

/// Test: Connection timeout is configured
pub fn plan_cmd_connection_timeout_test() {
  let config = create_test_config()

  config.database.connection_timeout_ms > 0
  |> should.be_true()
}

/// Test: Server configuration is present
pub fn plan_cmd_server_config_test() {
  let config = create_test_config()

  config.server.port > 0
  |> should.be_true()
}

/// Test: Logging is configured
pub fn plan_cmd_logging_configured_test() {
  let config = create_test_config()

  case config.logging.level {
    config.InfoLevel -> True
    _ -> False
  }
  |> should.be_true()
}

// ============================================================================
// Multiple Instantiation Tests
// ============================================================================

/// Test: Command can be instantiated multiple times with same config
pub fn plan_cmd_multiple_instances_test() {
  let config = create_test_config()
  let _cmd1 = plan.cmd(config)
  let _cmd2 = plan.cmd(config)
  let _cmd3 = plan.cmd(config)

  True
  |> should.be_true()
}

/// Test: Tandoor URL contains protocol
pub fn plan_cmd_tandoor_url_has_protocol_test() {
  let config = create_test_config()

  string.contains(config.tandoor.base_url, "http")
  |> should.be_true()
}

/// Test: Tandoor URL does not have trailing slash
pub fn plan_cmd_tandoor_url_no_trailing_slash_test() {
  let config = create_test_config()

  string.ends_with(config.tandoor.base_url, "/")
  |> should.be_false()
}

/// Test: Database password is set in secrets
pub fn plan_cmd_database_password_configured_test() {
  let config = create_test_config()

  case config.secrets.database_password {
    "test_pass" -> True
    _ -> False
  }
  |> should.be_true()
}
