import gleeunit/should
import meal_planner/config
import meal_planner/tandoor/connectivity

fn test_config_without_token() -> config.Config {
  config.Config(
    database: config.DatabaseConfig(
      host: "localhost",
      port: 5432,
      name: "test",
      user: "test",
      password: "test",
      pool_size: 1,
    ),
    server: config.ServerConfig(port: 3000, environment: "test"),
    tandoor: config.TandoorConfig(
      base_url: "http://localhost:8080",
      api_token: "",
      connect_timeout_ms: 5000,
      request_timeout_ms: 30_000,
    ),
    external_services: config.ExternalServicesConfig(
      todoist_api_key: "",
      usda_api_key: "",
      openai_api_key: "",
      openai_model: "gpt-4o",
    ),
  )
}

fn test_config_with_token() -> config.Config {
  config.Config(
    database: config.DatabaseConfig(
      host: "localhost",
      port: 5432,
      name: "test",
      user: "test",
      password: "test",
      pool_size: 1,
    ),
    server: config.ServerConfig(port: 3000, environment: "test"),
    tandoor: config.TandoorConfig(
      base_url: "http://localhost:8080",
      api_token: "test-token-123",
      connect_timeout_ms: 5000,
      request_timeout_ms: 30_000,
    ),
    external_services: config.ExternalServicesConfig(
      todoist_api_key: "",
      usda_api_key: "",
      openai_api_key: "",
      openai_model: "gpt-4o",
    ),
  )
}

pub fn health_check_returns_timestamp_test() {
  // Create a minimal config with no Tandoor token
  let test_config = test_config_without_token()

  // Perform health check
  let result = connectivity.check_health(test_config)

  // The timestamp should be greater than 0 (not the mock value)
  should.not_equal(result.timestamp_ms, 0)
  should.be_true(result.timestamp_ms > 0)
}

pub fn health_check_with_configured_tandoor_returns_timestamp_test() {
  // Create a config with Tandoor token set
  let test_config = test_config_with_token()

  // Perform health check
  let result = connectivity.check_health(test_config)

  // The timestamp should be greater than 0 (actual elapsed time in ms)
  should.not_equal(result.timestamp_ms, 0)
  should.be_true(result.timestamp_ms >= 0)
}
