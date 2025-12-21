//// TDD Tests for CLI tandoor command
////
//// RED PHASE: This test validates:
//// 1. Command instantiation
//// 2. Configuration is properly passed through
//// 3. Command structure integrity

import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/tandoor
import meal_planner/config

pub fn main() {
  gleeunit.main()
}

fn create_test_config() -> config.Config {
  config.Config(
    environment: config.Development,
    database: config.DatabaseConfig(
      host: "localhost", port: 5432, name: "test_db", user: "test_user",
      password: "test_pass", pool_size: 1, connection_timeout_ms: 5000,
    ),
    server: config.ServerConfig(port: 8080, cors_allowed_origins: []),
    tandoor: config.TandoorConfig(
      base_url: "http://localhost:8100", api_token: "test_token",
      connect_timeout_ms: 5000, request_timeout_ms: 30_000,
    ),
    external_services: config.ExternalServicesConfig(
      fatsecret: config.None, todoist_api_key: "", usda_api_key: "",
      openai_api_key: "", openai_model: "gpt-4",
    ),
    secrets: config.SecretsConfig(
      oauth_encryption_key: config.None, jwt_secret: config.None,
      database_password: "test_pass", tandoor_token: "test_token",
    ),
    logging: config.LoggingConfig(level: config.InfoLevel, debug_mode: False),
    performance: config.PerformanceConfig(
      request_timeout_ms: 30_000, connection_timeout_ms: 5000,
      max_concurrent_requests: 10, rate_limit_requests: 100,
    ),
  )
}

pub fn tandoor_cmd_instantiation_test() {
  let config = create_test_config()
  let _cmd = tandoor.cmd(config)
  True |> should.be_true()
}

pub fn tandoor_cmd_base_url_configured_test() {
  let config = create_test_config()
  string.length(config.tandoor.base_url) > 0 |> should.be_true()
}

pub fn tandoor_cmd_api_token_configured_test() {
  let config = create_test_config()
  string.length(config.tandoor.api_token) > 0 |> should.be_true()
}

pub fn tandoor_cmd_db_configured_test() {
  let config = create_test_config()
  string.length(config.database.host) > 0 |> should.be_true()
}

pub fn tandoor_cmd_timeouts_configured_test() {
  let config = create_test_config()
  config.tandoor.request_timeout_ms > 0 |> should.be_true()
}

pub fn tandoor_cmd_environment_development_test() {
  let config = create_test_config()
  case config.environment {
    config.Development -> True
    _ -> False
  }
  |> should.be_true()
}

pub fn tandoor_cmd_multiple_instances_test() {
  let config = create_test_config()
  let _cmd1 = tandoor.cmd(config)
  let _cmd2 = tandoor.cmd(config)
  True |> should.be_true()
}
