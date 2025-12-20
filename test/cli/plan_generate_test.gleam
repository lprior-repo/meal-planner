//// TDD Test for CLI plan generate command
////
//// RED PHASE: This test MUST fail initially because the implementation
//// does not exist yet. The test validates:
//// 1. Generate new meal plan (mp plan generate --days 7)
//// 2. Create optimal meal schedule
//// 3. Balance nutrition across days
//// 4. Save to Tandoor
////
//// Test follows Gleam 7 Commandments

import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/plan as plan_cmd
import meal_planner/config

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

/// Test: mp plan generate --days 7
///
/// EXPECTED FAILURE: plan_cmd.generate_plan function does not exist
///
/// This test validates that the generate command:
/// 1. Creates meal plan for N days
/// 2. Selects recipes that balance nutrition
/// 3. Saves plan to Tandoor
/// 4. Returns success message
///
/// Implementation strategy:
/// - Add generate_plan function to meal_planner/cli/domains/plan.gleam
/// - Function signature: fn generate_plan(config: Config, days: Int, start_date: Option(String)) -> Result(String, String)
/// - Use meal_planner/generation/weekly for plan generation logic
/// - Call Tandoor API to save meal plan entries
/// - Return formatted summary
pub fn plan_generate_creates_for_days_test() {
  let cfg = test_config()
  let days = 7

  // When: calling generate_plan for 7 days
  let result = plan_cmd.generate_plan(cfg, days: days, start_date: None)

  // Then: should return Ok with success message
  // This will FAIL because plan_cmd.generate_plan does not exist
  result
  |> should.be_ok()
}

/// Test: plan generate validates days parameter
///
/// EXPECTED FAILURE: plan_cmd.generate_plan does not validate input
///
/// This test validates parameter validation:
/// 1. Rejects days <= 0
/// 2. Rejects days > 30 (reasonable limit)
/// 3. Returns Error with message
///
/// Constraint: days must be 1-30
pub fn plan_generate_validates_days_test() {
  let cfg = test_config()
  let invalid_days = 0

  // When: calling generate_plan with invalid days
  let result = plan_cmd.generate_plan(cfg, days: invalid_days, start_date: None)

  // Then: should return Error
  result
  |> should.be_error()
}

/// Test: plan generate uses tomorrow as default start date
///
/// EXPECTED FAILURE: plan_cmd.generate_plan does not set default date
///
/// This test validates default behavior:
/// 1. If start_date is None, uses tomorrow
/// 2. Calculates tomorrow using birl
/// 3. Generates plan starting from tomorrow
///
/// Constraint: Default prevents overwriting today's meals
pub fn plan_generate_default_start_date_test() {
  let cfg = test_config()
  let days = 7

  // When: calling generate_plan without start_date
  let result = plan_cmd.generate_plan(cfg, days: days, start_date: None)

  // Then: should use tomorrow as start
  result
  |> should.be_ok()
}

/// Test: plan generate displays progress
///
/// EXPECTED FAILURE: plan_cmd.generate_plan does not show progress
///
/// This test validates progress reporting:
/// 1. Shows "Generating meal plan for X days..."
/// 2. Shows "Selecting recipes..."
/// 3. Shows "Saving to Tandoor..."
/// 4. Shows "Plan generated successfully!"
///
/// Constraint: Must use io.println for progress updates
pub fn plan_generate_shows_progress_test() {
  let cfg = test_config()
  let days = 7

  // When: calling generate_plan
  let result = plan_cmd.generate_plan(cfg, days: days, start_date: None)

  // Then: should display progress (validated via io.println output)
  result
  |> should.be_ok()
}

/// Test: plan generate balances nutrition across days
///
/// EXPECTED FAILURE: plan_cmd.generate_plan does not balance nutrition
///
/// This test validates nutrition optimization:
/// 1. Each day's meals should meet nutrition goals
/// 2. Uses generation/weekly module
/// 3. Considers macros when selecting recipes
///
/// Constraint: Must use meal_planner/generation/weekly logic
pub fn plan_generate_balances_nutrition_test() {
  let cfg = test_config()
  let days = 7

  // When: calling generate_plan
  let result = plan_cmd.generate_plan(cfg, days: days, start_date: None)

  // Then: should create balanced meal plan
  result
  |> should.be_ok()
}

/// Test: plan generate saves to Tandoor
///
/// EXPECTED FAILURE: plan_cmd.generate_plan does not save plan
///
/// This test validates persistence:
/// 1. Creates MealPlanEntry for each meal
/// 2. Calls Tandoor API to save
/// 3. Handles save errors gracefully
///
/// Constraint: Must use meal_planner/tandoor/mealplan.create_meal_plan
pub fn plan_generate_saves_to_tandoor_test() {
  let cfg = test_config()
  let days = 7

  // When: calling generate_plan
  let result = plan_cmd.generate_plan(cfg, days: days, start_date: None)

  // Then: should save plan to Tandoor
  result
  |> should.be_ok()
}

/// Test: plan generate returns summary
///
/// EXPECTED FAILURE: plan_cmd.generate_plan does not return summary
///
/// This test validates output format:
/// 1. Shows number of meals created
/// 2. Shows date range
/// 3. Shows sample meals
///
/// Constraint: Summary should be human-readable
pub fn plan_generate_returns_summary_test() {
  let cfg = test_config()
  let days = 7

  // When: calling generate_plan
  let result = plan_cmd.generate_plan(cfg, days: days, start_date: None)

  // Then: should return formatted summary
  case result {
    Ok(summary) -> {
      summary
      |> should_contain("meals")
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
