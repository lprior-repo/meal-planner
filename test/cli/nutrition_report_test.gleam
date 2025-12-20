//// TDD Test for CLI nutrition report command
////
//// RED PHASE: This test MUST fail initially because the implementation
//// does not exist yet. The test validates:
//// 1. Generate nutrition report for a specific date (mp nutrition report --date 2025-12-19)
//// 2. Display macro breakdown (protein, carbs, fat, calories)
//// 3. Compare actual vs goal values
//// 4. Calculate percentage deviations
////
//// Test follows Gleam 7 Commandments:
//// - Immutability: All test data is immutable
//// - No Nulls: Uses Option(T) and Result(T, E) exclusively
//// - Exhaustive Matching: All case branches covered
//// - Type Safety: Custom types for domain concepts

import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/nutrition as nutrition_cmd
import meal_planner/config
import meal_planner/ncp.{type NutritionData, NutritionData}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Test config for CLI commands
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

/// Mock nutrition data for a test date
fn mock_nutrition_data() -> NutritionData {
  NutritionData(protein: 150.0, fat: 70.0, carbs: 200.0, calories: 2100.0)
}

// ============================================================================
// RED PHASE: Tests that MUST FAIL initially
// ============================================================================

/// Test: mp nutrition report --date 2025-12-19
///
/// EXPECTED FAILURE: nutrition_cmd.generate_report function does not exist yet
///
/// This test validates that the report command:
/// 1. Fetches nutrition data for the specified date
/// 2. Compares against user's nutrition goals
/// 3. Calculates percentage deviations
/// 4. Returns formatted report string
///
/// Implementation strategy:
/// - Add generate_report function to meal_planner/cli/domains/nutrition.gleam
/// - Function signature: fn generate_report(config: Config, date: String) -> Result(String, String)
/// - Fetch meal plan for date using meal_planner/tandoor/mealplan
/// - For each meal, fetch recipe nutrition using meal_planner/tandoor/recipe
/// - Sum nutrition totals using meal_planner/ncp
/// - Calculate deviations from goals
/// - Format report with nutrition_cmd.format_nutrition_data
pub fn nutrition_report_generates_for_date_test() {
  let cfg = test_config()
  let date = "2025-12-19"

  // When: calling generate_report for a specific date
  let result = nutrition_cmd.generate_report(cfg, date: date)

  // Then: should return Ok with formatted report
  // This will FAIL because nutrition_cmd.generate_report does not exist
  result
  |> should.be_ok()
}

/// Test: nutrition report displays macro breakdown
///
/// EXPECTED FAILURE: nutrition_cmd.generate_report does not display macros
///
/// This test validates that the report shows:
/// 1. Protein in grams
/// 2. Carbs in grams
/// 3. Fat in grams
/// 4. Total calories
///
/// Constraint: Must use nutrition_cmd.format_nutrition_data helper
pub fn nutrition_report_displays_macros_test() {
  let cfg = test_config()
  let date = "2025-12-19"

  // When: calling generate_report
  let result = nutrition_cmd.generate_report(cfg, date: date)

  // Then: should include formatted nutrition data
  case result {
    Ok(report) -> {
      // Report should contain macro values
      report
      |> should_contain("Protein:")

      report
      |> should_contain("Fat:")

      report
      |> should_contain("Carbs:")

      report
      |> should_contain("Calories:")
    }
    Error(_) -> should.fail()
  }
}

/// Test: nutrition report compares against goals
///
/// EXPECTED FAILURE: nutrition_cmd.generate_report does not compare goals
///
/// This test validates goal comparison:
/// 1. Fetches user's nutrition goals
/// 2. Calculates deviations using ncp.calculate_deviation
/// 3. Displays actual vs goal values
/// 4. Shows percentage differences
///
/// Constraint: Must use ncp module for calculations
pub fn nutrition_report_compares_goals_test() {
  let cfg = test_config()
  let date = "2025-12-19"

  // When: calling generate_report
  let result = nutrition_cmd.generate_report(cfg, date: date)

  // Then: should include goal comparison
  case result {
    Ok(report) -> {
      // Report should show deviations
      report
      |> should_contain("Goal:")

      report
      |> should_contain("%")
    }
    Error(_) -> should.fail()
  }
}

/// Test: nutrition report handles invalid date format
///
/// EXPECTED FAILURE: nutrition_cmd.generate_report does not validate date
///
/// This test validates error handling:
/// 1. Detects invalid date format
/// 2. Returns Error with descriptive message
/// 3. Does not attempt to fetch data
///
/// Constraint: date must be in YYYY-MM-DD format
pub fn nutrition_report_invalid_date_test() {
  let cfg = test_config()
  let invalid_date = "12/19/2025"

  // When: calling generate_report with invalid date
  let result = nutrition_cmd.generate_report(cfg, date: invalid_date)

  // Then: should return Error
  result
  |> should.be_error()
}

/// Test: nutrition report handles no data for date
///
/// EXPECTED FAILURE: nutrition_cmd.generate_report does not handle empty data
///
/// This test validates behavior when no meals logged:
/// 1. Returns report showing zero nutrition
/// 2. Displays "No meals logged for this date" message
/// 3. Still shows goals for comparison
///
/// Constraint: Empty data is not an error condition
pub fn nutrition_report_no_data_test() {
  let cfg = test_config()
  let date = "2025-12-25"

  // When: calling generate_report for date with no meals
  let result = nutrition_cmd.generate_report(cfg, date: date)

  // Then: should return Ok with zero nutrition
  case result {
    Ok(report) -> {
      report
      |> should_contain("No meals")
    }
    Error(_) -> should.fail()
  }
}

/// Test: nutrition report uses "today" as default date
///
/// EXPECTED FAILURE: nutrition_cmd.generate_report does not handle "today"
///
/// This test validates default date handling:
/// 1. Accepts "today" as date value
/// 2. Converts to current date in YYYY-MM-DD format
/// 3. Generates report for current date
///
/// Constraint: Must use birl for date conversion
pub fn nutrition_report_today_default_test() {
  let cfg = test_config()

  // When: calling generate_report with "today"
  let result = nutrition_cmd.generate_report(cfg, date: "today")

  // Then: should convert to current date and generate report
  result
  |> should.be_ok()
}

/// Test: nutrition report formats output as table
///
/// EXPECTED FAILURE: nutrition_cmd.generate_report does not format as table
///
/// This test validates output formatting:
/// 1. Uses nutrition_cmd.build_goals_table for structured output
/// 2. Aligns columns properly
/// 3. Shows actual vs goal side-by-side
///
/// Constraint: Must use existing format_nutrition_data and build_goals_table helpers
pub fn nutrition_report_formats_table_test() {
  let cfg = test_config()
  let date = "2025-12-19"

  // When: calling generate_report
  let result = nutrition_cmd.generate_report(cfg, date: date)

  // Then: should format as table
  case result {
    Ok(report) -> {
      // Table should contain box drawing characters
      report
      |> should_contain("│")
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
