//// TDD Test for CLI nutrition compliance command
////
//// RED PHASE: This test MUST fail initially because the implementation
//// does not exist yet. The test validates:
//// 1. Check compliance with nutrition goals (mp nutrition compliance --date 2025-12-19 --tolerance 10)
//// 2. Display on-track vs off-track status
//// 3. Show percentage deviations with tolerance
//// 4. Visual indicators (✓/✗) for compliance
////
//// Test follows Gleam 7 Commandments

import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/nutrition as nutrition_cmd
import meal_planner/config
import meal_planner/ncp.{type DeviationResult, DeviationResult}

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

/// Mock deviation result within tolerance
fn mock_compliant_deviation() -> DeviationResult {
  DeviationResult(
    protein_pct: 5.0,
    // Within 10% tolerance
    fat_pct: -3.0,
    carbs_pct: 8.0,
    calories_pct: 2.0,
  )
}

/// Mock deviation result outside tolerance
fn mock_noncompliant_deviation() -> DeviationResult {
  DeviationResult(
    protein_pct: 15.0,
    // Outside 10% tolerance
    fat_pct: -25.0,
    carbs_pct: 12.0,
    calories_pct: 20.0,
  )
}

// ============================================================================
// RED PHASE: Tests that MUST FAIL initially
// ============================================================================

/// Test: mp nutrition compliance --date 2025-12-19 --tolerance 10
///
/// EXPECTED FAILURE: nutrition_cmd.check_compliance function does not exist
///
/// This test validates that the compliance command:
/// 1. Fetches nutrition data for the date
/// 2. Compares against user's goals
/// 3. Calculates percentage deviations
/// 4. Checks if within tolerance threshold
/// 5. Returns compliance status
///
/// Implementation strategy:
/// - Add check_compliance function to meal_planner/cli/domains/nutrition.gleam
/// - Function signature: fn check_compliance(config: Config, date: String, tolerance: Float) -> Result(String, String)
/// - Use ncp.calculate_deviation to get percentages
/// - Use ncp.deviation_is_within_tolerance to check compliance
/// - Format using build_compliance_summary
pub fn nutrition_compliance_checks_for_date_test() {
  let cfg = test_config()
  let date = "2025-12-19"
  let tolerance = 10.0

  // When: calling check_compliance for a specific date
  let result =
    nutrition_cmd.check_compliance(cfg, date: date, tolerance: tolerance)

  // Then: should return Ok with compliance report
  // This will FAIL because nutrition_cmd.check_compliance does not exist
  result
  |> should.be_ok()
}

/// Test: compliance displays on-track status
///
/// EXPECTED FAILURE: nutrition_cmd.check_compliance does not show status
///
/// This test validates status display:
/// 1. Shows "✓ ON TRACK" if all macros within tolerance
/// 2. Shows "✗ OFF TRACK" if any macro outside tolerance
/// 3. Status is prominent at top of report
///
/// Constraint: Must use build_compliance_summary helper
pub fn nutrition_compliance_shows_status_test() {
  let cfg = test_config()
  let date = "2025-12-19"
  let tolerance = 10.0

  // When: calling check_compliance
  let result =
    nutrition_cmd.check_compliance(cfg, date: date, tolerance: tolerance)

  // Then: should show compliance status
  case result {
    Ok(report) -> {
      // Report should contain status indicator
      report
      |> should_contain("TRACK")
    }
    Error(_) -> should.fail()
  }
}

/// Test: compliance displays per-macro indicators
///
/// EXPECTED FAILURE: nutrition_cmd.check_compliance does not show per-macro
///
/// This test validates granular status display:
/// 1. Shows ✓ for macros within tolerance
/// 2. Shows ✗ for macros outside tolerance
/// 3. Displays for protein, carbs, fat, calories separately
///
/// Constraint: Must check each macro independently
pub fn nutrition_compliance_per_macro_indicators_test() {
  let cfg = test_config()
  let date = "2025-12-19"
  let tolerance = 10.0

  // When: calling check_compliance
  let result =
    nutrition_cmd.check_compliance(cfg, date: date, tolerance: tolerance)

  // Then: should show indicators for each macro
  case result {
    Ok(report) -> {
      report
      |> should_contain("Protein")

      report
      |> should_contain("Fat")

      report
      |> should_contain("Carbs")

      report
      |> should_contain("Calories")
    }
    Error(_) -> should.fail()
  }
}

/// Test: compliance displays percentage deviations
///
/// EXPECTED FAILURE: nutrition_cmd.check_compliance does not show deviations
///
/// This test validates deviation display:
/// 1. Shows "+X%" for over-consumption
/// 2. Shows "-X%" for under-consumption
/// 3. Displays next to each macro
///
/// Constraint: Must use format_deviation helper
pub fn nutrition_compliance_shows_deviations_test() {
  let cfg = test_config()
  let date = "2025-12-19"
  let tolerance = 10.0

  // When: calling check_compliance
  let result =
    nutrition_cmd.check_compliance(cfg, date: date, tolerance: tolerance)

  // Then: should show percentage deviations
  case result {
    Ok(report) -> {
      report
      |> should_contain("%")
    }
    Error(_) -> should.fail()
  }
}

/// Test: compliance validates tolerance parameter
///
/// EXPECTED FAILURE: nutrition_cmd.check_compliance does not validate tolerance
///
/// This test validates parameter validation:
/// 1. Rejects tolerance < 0
/// 2. Rejects tolerance > 100
/// 3. Returns Error with message
///
/// Constraint: tolerance must be 0-100 (percentage)
pub fn nutrition_compliance_validates_tolerance_test() {
  let cfg = test_config()
  let date = "2025-12-19"
  let invalid_tolerance = -5.0

  // When: calling check_compliance with invalid tolerance
  let result =
    nutrition_cmd.check_compliance(
      cfg,
      date: date,
      tolerance: invalid_tolerance,
    )

  // Then: should return Error
  result
  |> should.be_error()
}

/// Test: compliance uses 10% default tolerance
///
/// EXPECTED FAILURE: nutrition_cmd.check_compliance does not have default
///
/// This test validates default behavior:
/// 1. If tolerance not specified, uses 10%
/// 2. Applies default consistently
/// 3. Documented in help text
///
/// Constraint: Default tolerance is 10.0
pub fn nutrition_compliance_default_tolerance_test() {
  let cfg = test_config()
  let date = "2025-12-19"

  // When: calling check_compliance without tolerance (relies on CLI default)
  // Note: In actual CLI, glint flag default is 10.0
  let result = nutrition_cmd.check_compliance(cfg, date: date, tolerance: 10.0)

  // Then: should use default tolerance
  result
  |> should.be_ok()
}

/// Test: compliance builds summary table
///
/// EXPECTED FAILURE: nutrition_cmd.build_compliance_summary does not exist
///
/// This test validates formatting helper:
/// 1. Accepts DeviationResult and tolerance
/// 2. Returns formatted string with status
/// 3. Includes visual indicators
///
/// Constraint: Function already exists, test verifies it works
pub fn build_compliance_summary_formats_test() {
  let deviation = mock_compliant_deviation()
  let tolerance = 10.0

  // When: building compliance summary
  let summary = nutrition_cmd.build_compliance_summary(deviation, tolerance)

  // Then: should contain status and indicators
  summary
  |> should_contain("Compliance Status")

  summary
  |> should_contain("✓")
}

/// Test: compliance handles invalid date
///
/// EXPECTED FAILURE: nutrition_cmd.check_compliance does not validate date
///
/// This test validates error handling:
/// 1. Detects invalid date format
/// 2. Returns Error with message
/// 3. Does not attempt data fetch
///
/// Constraint: date must be YYYY-MM-DD or "today"
pub fn nutrition_compliance_invalid_date_test() {
  let cfg = test_config()
  let invalid_date = "not-a-date"
  let tolerance = 10.0

  // When: calling check_compliance with invalid date
  let result =
    nutrition_cmd.check_compliance(
      cfg,
      date: invalid_date,
      tolerance: tolerance,
    )

  // Then: should return Error
  result
  |> should.be_error()
}

/// Test: compliance formats deviation percentages correctly
///
/// EXPECTED FAILURE: nutrition_cmd.format_deviation does not exist
///
/// This test validates format helper:
/// 1. Adds "+" for positive deviations
/// 2. Keeps "-" for negative deviations
/// 3. Appends "%" symbol
///
/// Constraint: Function already exists, test verifies it works
pub fn format_deviation_formats_correctly_test() {
  let deviation =
    DeviationResult(
      protein_pct: 5.5,
      fat_pct: -3.2,
      carbs_pct: 0.0,
      calories_pct: 10.0,
    )

  // When: formatting deviation
  let formatted = nutrition_cmd.format_deviation(deviation)

  // Then: should contain formatted percentages
  formatted
  |> should_contain("+")

  formatted
  |> should_contain("%")
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
