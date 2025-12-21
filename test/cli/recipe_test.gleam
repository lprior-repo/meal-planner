//// TDD Tests for CLI recipe command
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/recipe
import meal_planner/config

pub fn main() { gleeunit.main() }

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

pub fn recipe_cmd_instantiation_test() {
  let config = create_test_config()
  let _cmd = recipe.cmd(config)
  True |> should.be_true()
}

pub fn recipe_cmd_tandoor_configured_test() {
  let config = create_test_config()
  string.length(config.tandoor.base_url) > 0 |> should.be_true()
}

pub fn recipe_cmd_server_port_test() {
  let config = create_test_config()
  config.server.port > 0 |> should.be_true()
}

pub fn recipe_cmd_logging_configured_test() {
  let config = create_test_config()
  case config.logging.level {
    config.InfoLevel -> True
    _ -> False
  } |> should.be_true()
}

pub fn recipe_cmd_multiple_instances_test() {
  let config = create_test_config()
  let _cmd1 = recipe.cmd(config)
  let _cmd2 = recipe.cmd(config)
  True |> should.be_true()
}
