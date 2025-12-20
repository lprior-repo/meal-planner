/// Tests for plan CLI domain
import gleeunit/should
import meal_planner/cli/domains/plan
import meal_planner/config

pub fn sync_command_exists_test() {
  // Create minimal test config
  let config =
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
        base_url: "http://test",
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

  // Build the Glint command - should not crash
  let _cmd = plan.cmd(config)

  // If we got here, the command was created successfully
  True
  |> should.be_true
}
