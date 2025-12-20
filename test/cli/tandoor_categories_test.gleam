/// Tests for Tandoor categories CLI command (meal-planner-e5if)
///
/// RED PHASE: Test that categories command lists cuisines and keywords
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/domains/tandoor
import meal_planner/config

/// Test: categories command lists available categories
pub fn categories_list_returns_ok_test() {
  // Create test config with all required fields
  let test_config =
    config.Config(
      environment: config.Development,
      database: config.DatabaseConfig(
        host: "localhost",
        port: 5432,
        name: "test",
        user: "test",
        password: "test",
        pool_size: 5,
        connection_timeout_ms: 5000,
      ),
      server: config.ServerConfig(port: 8080, cors_allowed_origins: []),
      tandoor: config.TandoorConfig(
        base_url: "http://localhost",
        api_token: "test",
        connect_timeout_ms: 5000,
        request_timeout_ms: 5000,
      ),
      external_services: config.ExternalServicesConfig(
        fatsecret: Some(config.FatSecretConfig(
          consumer_key: "test_key",
          consumer_secret: "test_secret",
        )),
        todoist_api_key: "",
        usda_api_key: "",
        openai_api_key: "",
        openai_model: "",
      ),
      secrets: config.SecretsConfig(
        oauth_encryption_key: None,
        jwt_secret: None,
        database_password: "test",
        tandoor_token: "test",
      ),
      logging: config.LoggingConfig(level: config.InfoLevel, debug_mode: False),
      performance: config.PerformanceConfig(
        request_timeout_ms: 30_000,
        connection_timeout_ms: 5000,
        max_concurrent_requests: 100,
        rate_limit_requests: 1000,
      ),
    )

  // Call the categories handler
  // This should list cuisines and keywords with recipe counts
  let result = tandoor.list_categories_handler(test_config, limit: 50)

  // Should return Ok(Nil) on success
  should.be_ok(result)
}
