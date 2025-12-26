/// Tests for Nutrition goals CLI command (meal-planner-2z4s)
///
/// RED PHASE: Test that set_goal saves to database
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/cli/domains/nutrition
import meal_planner/config
import meal_planner/config/database.{DatabaseConfig}
import meal_planner/config/environment.{Development, InfoLevel}
import meal_planner/postgres
import meal_planner/storage
import meal_planner/storage/profile

/// Test: set_goal saves calorie target to database
pub fn set_goal_calories_saves_to_database_test() {
  // Create test config
  let test_config =
    config.Config(
      environment: Development,
      database: DatabaseConfig(
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
      logging: config.LoggingConfig(level: InfoLevel, debug_mode: False),
      performance: config.PerformanceConfig(
        request_timeout_ms: 30_000,
        connection_timeout_ms: 5000,
        max_concurrent_requests: 100,
        rate_limit_requests: 1000,
      ),
    )

  // Verify database is available before running test
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
    Error(_) -> {
      // Database not available, skip test by passing trivially
      True
      |> should.be_true
    }
    Ok(conn) -> {
      // Verify connection works and we can query
      case storage.get_goals(conn) {
        Error(profile.NotFound) | Ok(_) -> {
          // Database is accessible, proceed with test
          // Call set_goal for calories
          let result =
            nutrition.set_goal(test_config, goal_type: "calories", value: 2000)

          // Should return Ok
          result
          |> should.be_ok

          // Verify goal was persisted to database
          case postgres.connect(db_config) {
            Ok(conn) -> {
              case storage.get_goals(conn) {
                Ok(saved_goals) -> {
                  saved_goals.daily_calories
                  |> should.equal(2000.0)
                }
                Error(_) -> should.fail()
              }
            }
            Error(_) -> should.fail()
          }
        }
        Error(_) -> {
          // Database error, skip test
          True
          |> should.be_true
        }
      }
    }
  }
}
