//// TDD Test for CLI nutrition trends command
////
//// RED PHASE: This test MUST fail initially because the implementation
//// does not exist yet. The test validates:
//// 1. Display nutrition trends over time (mp nutrition trends --days 7)
//// 2. Show average macros per day
//// 3. Identify trend directions (increasing/decreasing/stable)
//// 4. Visualize trends with arrows
////
//// Test follows Gleam 7 Commandments

import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/nutrition as nutrition_cmd
import meal_planner/config
import meal_planner/ncp.{type TrendDirection, Decreasing, Increasing, Stable}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn test_config() -> config.Config {
  config.Config(
    environment: config.Development,
    database: config.DatabaseConfig(
      host: "localhost",
      port: 5432,
      name: "meal_planner_test",
      user: "test_user",
      password: "test_password",
      pool_size: 10,
      connection_timeout_ms: 5000,
    ),
    server: config.ServerConfig(port: 8080, cors_allowed_origins: []),
    tandoor: config.TandoorConfig(
      base_url: "http://localhost:8000",
      api_token: "test_token",
      connect_timeout_ms: 5000,
      request_timeout_ms: 30_000,
    ),
    external_services: config.ExternalServicesConfig(
      fatsecret: Some(config.FatSecretConfig(
        consumer_key: "test_client_id",
        consumer_secret: "test_client_secret",
      )),
      todoist_api_key: "test_todoist",
      usda_api_key: "test_usda",
      openai_api_key: "test_openai",
      openai_model: "gpt-4",
    ),
    secrets: config.SecretsConfig(
      oauth_encryption_key: None,
      jwt_secret: None,
      database_password: "test_password",
      tandoor_token: "test_token",
    ),
    logging: config.LoggingConfig(level: config.InfoLevel, debug_mode: False),
    performance: config.PerformanceConfig(
      request_timeout_ms: 30_000,
      connection_timeout_ms: 5000,
      max_concurrent_requests: 100,
      rate_limit_requests: 1000,
    ),
  )
}

// ============================================================================
// RED PHASE: Tests that MUST FAIL initially
// ============================================================================

/// Test: mp nutrition trends --days 7
///
/// EXPECTED FAILURE: nutrition_cmd.display_trends function does not exist
///
/// This test validates that the trends command:
/// 1. Fetches nutrition data for last N days
/// 2. Calculates daily averages
/// 3. Identifies trend directions
/// 4. Returns formatted trends report
///
/// Implementation strategy:
/// - Add display_trends function to meal_planner/cli/domains/nutrition.gleam
/// - Function signature: fn display_trends(config: Config, days: Int) -> Result(String, String)
/// - Fetch meal plans for date range using birl for date calculations
/// - Calculate nutrition totals per day
/// - Use ncp.analyze_trend to determine direction
/// - Format with nutrition_cmd.format_trend_direction
pub fn nutrition_trends_displays_for_days_test() {
  let cfg = test_config()
  let days = 7

  // When: calling display_trends for 7 days
  let result = nutrition_cmd.display_trends(cfg, days: days)

  // Then: should return Ok with formatted trends
  // This will FAIL because nutrition_cmd.display_trends does not exist
  result
  |> should.be_ok()
}

/// Test: nutrition trends shows daily averages
///
/// EXPECTED FAILURE: nutrition_cmd.display_trends does not calculate averages
///
/// This test validates average calculations:
/// 1. Sums nutrition for each day
/// 2. Calculates mean across all days
/// 3. Displays "Average: X.Xg protein, Y.Yg carbs..."
///
/// Constraint: Must show averages for protein, carbs, fat, calories
pub fn nutrition_trends_shows_averages_test() {
  let cfg = test_config()
  let days = 7

  // When: calling display_trends
  let result = nutrition_cmd.display_trends(cfg, days: days)

  // Then: should include averages
  case result {
    Ok(report) -> {
      report
      |> should_contain("Average")

      report
      |> should_contain("protein")
    }
    Error(_) -> should.fail()
  }
}

/// Test: nutrition trends identifies increasing trend
///
/// EXPECTED FAILURE: nutrition_cmd.display_trends does not analyze trends
///
/// This test validates trend detection:
/// 1. Uses ncp.analyze_trend to detect pattern
/// 2. Shows "↑ Increasing" for upward trend
/// 3. Displays for each macro separately
///
/// Constraint: Must use TrendDirection type from ncp module
pub fn nutrition_trends_identifies_increasing_test() {
  let cfg = test_config()
  let days = 7

  // When: calling display_trends with increasing data
  let result = nutrition_cmd.display_trends(cfg, days: days)

  // Then: should show trend direction
  case result {
    Ok(report) -> {
      // Should contain trend indicator
      report
      |> should_contain("↑")
    }
    Error(_) -> should.fail()
  }
}

/// Test: nutrition trends handles insufficient data
///
/// EXPECTED FAILURE: nutrition_cmd.display_trends does not validate data
///
/// This test validates error handling:
/// 1. Returns Error if less than 2 days of data
/// 2. Shows message "Insufficient data for trend analysis"
/// 3. Suggests logging more meals
///
/// Constraint: Trend analysis requires minimum 2 data points
pub fn nutrition_trends_insufficient_data_test() {
  let cfg = test_config()
  let days = 7

  // When: calling display_trends with no data
  let result = nutrition_cmd.display_trends(cfg, days: days)

  // Then: should return Error or message about insufficient data
  case result {
    Error(msg) -> {
      msg
      |> should_contain("Insufficient")
    }
    Ok(report) -> {
      // If Ok, report should mention no data
      report
      |> should_contain("Insufficient")
    }
  }
}

/// Test: nutrition trends validates days parameter
///
/// EXPECTED FAILURE: nutrition_cmd.display_trends does not validate input
///
/// This test validates parameter validation:
/// 1. Rejects days <= 0
/// 2. Returns Error "Days must be positive"
/// 3. Does not attempt to fetch data
///
/// Constraint: days parameter must be >= 1
pub fn nutrition_trends_validates_days_parameter_test() {
  let cfg = test_config()
  let invalid_days = 0

  // When: calling display_trends with invalid days
  let result = nutrition_cmd.display_trends(cfg, days: invalid_days)

  // Then: should return Error
  result
  |> should.be_error()
}

/// Test: nutrition trends formats trend direction with arrows
///
/// EXPECTED FAILURE: nutrition_cmd.display_trends does not format trends
///
/// This test validates formatting:
/// 1. Uses format_trend_direction helper
/// 2. Shows "↑ Increasing", "↓ Decreasing", or "→ Stable"
/// 3. Applies to each macro individually
///
/// Constraint: Must use existing format_trend_direction function
pub fn nutrition_trends_formats_direction_test() {
  // Test format_trend_direction directly
  nutrition_cmd.format_trend_direction(Increasing)
  |> should.equal("↑ Increasing")

  nutrition_cmd.format_trend_direction(Decreasing)
  |> should.equal("↓ Decreasing")

  nutrition_cmd.format_trend_direction(Stable)
  |> should.equal("→ Stable")
}

/// Test: nutrition trends displays per-macro trends
///
/// EXPECTED FAILURE: nutrition_cmd.display_trends does not show per-macro
///
/// This test validates granular trend display:
/// 1. Shows separate trend for protein
/// 2. Shows separate trend for carbs
/// 3. Shows separate trend for fat
/// 4. Shows separate trend for calories
///
/// Constraint: Each macro can have different trend direction
pub fn nutrition_trends_per_macro_test() {
  let cfg = test_config()
  let days = 7

  // When: calling display_trends
  let result = nutrition_cmd.display_trends(cfg, days: days)

  // Then: should show trend for each macro
  case result {
    Ok(report) -> {
      report
      |> should_contain("Protein")

      report
      |> should_contain("Carbs")

      report
      |> should_contain("Fat")

      report
      |> should_contain("Calories")
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Helper function for substring matching
// ============================================================================

fn should_contain(haystack: String, needle: String) {
  let contains = contains_substring(haystack, needle)
  case contains {
    True -> should.be_true(True)
    False -> should.fail()
  }
}

fn contains_substring(haystack: String, needle: String) -> Bool {
  gleam_string_contains(haystack, needle)
}

@external(erlang, "string", "find")
fn gleam_string_contains(haystack: String, needle: String) -> Bool
