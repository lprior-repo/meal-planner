/// Tests for Nutrition goals CLI command (meal-planner-2z4s)
///
/// RED PHASE: Test that goals command sets macro targets and persists to database
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/domains/nutrition
import meal_planner/config
import meal_planner/ncp.{NutritionGoals}
import meal_planner/postgres
import meal_planner/storage

/// Test: set_nutrition_goals saves targets to database
pub fn set_nutrition_goals_saves_to_database_test() {
  // Create test config with all required fields
  let test_config =
    config.Config(
      environment: config.Development,
      database: config.DatabaseConfig(
        host: "localhost",
        port: 5432,
        name: "meal_planner_test",
        user: "postgres",
        password: "",
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
        database_password: "",
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

  // Test data: set calorie and macro targets
  let test_goals =
    NutritionGoals(
      daily_calories: 2000.0,
      daily_protein: 150.0,
      daily_carbs: 200.0,
      daily_fat: 67.0,
    )

  // Call set_nutrition_goals handler
  let result =
    nutrition.set_nutrition_goals(
      test_config,
      calories: Some(2000),
      protein: Some(150),
      carbs: Some(200),
      fat: Some(67),
    )

  // Should return Ok(Nil) on success
  result
  |> should.be_ok

  // Verify goals were persisted to database
  let db_config =
    postgres.Config(
      host: test_config.database.host,
      port: test_config.database.port,
      database: test_config.database.name,
      user: test_config.database.user,
      password: case test_config.database.password {
        "" -> None
        pwd -> Some(pwd)
      },
      pool_size: test_config.database.pool_size,
    )

  case postgres.connect(db_config) {
    Ok(conn) -> {
      case storage.get_goals(conn) {
        Ok(saved_goals) -> {
          saved_goals.daily_calories
          |> should.equal(2000.0)

          saved_goals.daily_protein
          |> should.equal(150.0)

          saved_goals.daily_carbs
          |> should.equal(200.0)

          saved_goals.daily_fat
          |> should.equal(67.0)
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

/// Test: set_nutrition_goals validates input ranges
pub fn set_nutrition_goals_validates_input_test() {
  let test_config =
    config.Config(
      environment: config.Development,
      database: config.DatabaseConfig(
        host: "localhost",
        port: 5432,
        name: "meal_planner_test",
        user: "postgres",
        password: "",
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
        database_password: "",
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

  // Test invalid calorie value (too high)
  let result =
    nutrition.set_nutrition_goals(
      test_config,
      calories: Some(15_000),
      protein: None,
      carbs: None,
      fat: None,
    )

  result
  |> should.be_error
}
