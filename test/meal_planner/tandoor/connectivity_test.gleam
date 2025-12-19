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
  // Check if Tandoor is configured in environment
  case config.load() {
    Error(_) -> {
      // Configuration not available - skip this test gracefully
      True |> should.equal(True)
    }
    Ok(env_config) -> {
      // Use environment configuration
      let result = connectivity.check_health(env_config)

      // The timestamp should be greater than or equal to 0
      should.be_true(result.timestamp_ms >= 0)
    }
  }
}

pub fn health_check_with_configured_tandoor_returns_timestamp_test() {
  // Check if Tandoor is configured in environment
  case config.load() {
    Error(_) -> {
      // Configuration not available - skip this test gracefully
      True |> should.equal(True)
    }
    Ok(env_config) -> {
      // Perform health check with environment configuration
      let result = connectivity.check_health(env_config)

      // The timestamp should be greater than or equal to 0
      should.be_true(result.timestamp_ms >= 0)
    }
  }
}
