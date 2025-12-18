import gleeunit/should
import meal_planner/config
import meal_planner/tandoor/connectivity

pub fn health_check_returns_timestamp_test() {
  // Create a minimal config with no Tandoor token
  let test_config =
    config.Config(
      database: config.DatabaseConfig(
        host: "localhost",
        port: 5432,
        user: "test",
        password: "test",
        database: "test",
        pool_size: 1,
        queue_size: 10,
      ),
      server: config.ServerConfig(port: 3000, secret: "test-secret"),
      tandoor: config.TandoorConfig(
        base_url: "http://localhost:8080",
        api_token: "",
      ),
      mailtrap: config.MailtrapConfig(api_token: "", inbox_id: 0),
      todoist: config.TodoistConfig(api_token: ""),
      fatsecret: config.FatSecretConfig(
        client_id: "",
        client_secret: "",
        enabled: False,
      ),
      enable_auth: False,
    )

  // Perform health check
  let result = connectivity.check_health(test_config)

  // The timestamp should be greater than 0 (not the mock value)
  should.not_equal(result.timestamp_ms, 0)
  should.be_true(result.timestamp_ms > 0)
}

pub fn health_check_with_configured_tandoor_returns_timestamp_test() {
  // Create a config with Tandoor token set
  let test_config =
    config.Config(
      database: config.DatabaseConfig(
        host: "localhost",
        port: 5432,
        user: "test",
        password: "test",
        database: "test",
        pool_size: 1,
        queue_size: 10,
      ),
      server: config.ServerConfig(port: 3000, secret: "test-secret"),
      tandoor: config.TandoorConfig(
        base_url: "http://localhost:8080",
        api_token: "test-token-123",
      ),
      mailtrap: config.MailtrapConfig(api_token: "", inbox_id: 0),
      todoist: config.TodoistConfig(api_token: ""),
      fatsecret: config.FatSecretConfig(
        client_id: "",
        client_secret: "",
        enabled: False,
      ),
      enable_auth: False,
    )

  // Perform health check
  let result = connectivity.check_health(test_config)

  // The timestamp should be greater than 0 (actual elapsed time in ms)
  should.not_equal(result.timestamp_ms, 0)
  should.be_true(result.timestamp_ms >= 0)
}
