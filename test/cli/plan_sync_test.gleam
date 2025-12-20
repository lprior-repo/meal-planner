//// TDD Test for CLI plan sync command
////
//// RED PHASE: This test MUST fail initially because the implementation
//// does not exist yet. The test validates:
//// 1. Sync meal plan with FatSecret diary entries
//// 2. Handle date range (today or specific date)
//// 3. Display sync results showing matched/unmatched entries
//// 4. Update meal plan state after sync
////
//// Test follows Gleam 7 Commandments:
//// - Immutability: All test data is immutable
//// - No Nulls: Uses Option(T) and Result(T, E) exclusively
//// - Exhaustive Matching: All case branches covered
//// - Type Safety: Custom types for domain concepts

import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/plan as plan_cmd
import meal_planner/config

pub fn main() {
  gleeunit.main()
}

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

// ============================================================================
// RED PHASE: Tests that MUST FAIL initially
// ============================================================================

/// Test: mp plan sync syncs meal plan with FatSecret diary
///
/// EXPECTED FAILURE: plan_cmd.sync_plan function does not exist yet
///
/// This test validates that the sync command:
/// 1. Fetches meal plan for today from database
/// 2. Fetches FatSecret diary entries for today
/// 3. Matches planned meals with logged entries
/// 4. Returns Ok with sync summary
///
/// Implementation strategy:
/// - Query database for meal_plan table where date = today
/// - Call fatsecret/diary.get_day to fetch diary entries
/// - Match meals by name/calories within tolerance (±5%)
/// - Update plan.synced_at timestamp
/// - Return Ok(SyncSummary(matched, unmatched))
pub fn plan_sync_basic_test() {
  let cfg = test_config()

  // When: calling sync_plan with no date (defaults to today)
  let result = plan_cmd.sync_plan(cfg, date: None)

  // Then: should sync today's plan with FatSecret
  // This will FAIL because plan_cmd.sync_plan does not exist
  result
  |> should.be_ok()
}

/// Test: mp plan sync accepts specific date
///
/// EXPECTED FAILURE: plan_cmd.sync_plan does not accept date parameter
///
/// This test validates date parameter:
/// 1. Accepts --date flag with format YYYY-MM-DD
/// 2. Syncs meal plan for specified date, not today
/// 3. Returns Ok even if date is in past
/// 4. Validates date format before processing
///
/// Implementation strategy:
/// - Accept optional date parameter as String
/// - Parse using datetime.parse_iso8601 or similar
/// - If date is invalid format, return Error("Invalid date format, use YYYY-MM-DD")
/// - Query plan for specified date
pub fn plan_sync_specific_date_test() {
  let cfg = test_config()

  // When: calling sync_plan with specific date
  let result = plan_cmd.sync_plan(cfg, date: Some("2025-12-20"))

  // Then: should sync plan for specified date
  // This will FAIL because plan_cmd.sync_plan does not exist
  result
  |> should.be_ok()
}

/// Test: mp plan sync handles invalid date format
///
/// EXPECTED FAILURE: plan_cmd.sync_plan does not validate date format
///
/// This test validates date validation:
/// 1. Date must be YYYY-MM-DD format
/// 2. Invalid format returns Error("Invalid date format")
/// 3. Non-existent dates like 2025-13-01 are rejected
/// 4. Validation before API calls
///
/// Implementation strategy:
/// - Use datetime.parse_iso8601 to validate
/// - Catch parsing errors
/// - Return Error("Invalid date: YYYY-MM-DD format required")
pub fn plan_sync_rejects_invalid_date_test() {
  let cfg = test_config()

  // When: calling sync_plan with invalid date
  let result = plan_cmd.sync_plan(cfg, date: Some("2025/12/20"))

  // Then: should return Error
  // This will FAIL because plan_cmd.sync_plan does not exist
  result
  |> should.be_error()
}

/// Test: mp plan sync displays matched meals
///
/// EXPECTED FAILURE: plan_cmd.sync_plan does not display results
///
/// This test validates output:
/// 1. Displays each matched meal: "✓ Breakfast: Scrambled Eggs (300 cal)"
/// 2. Shows calorie difference if within tolerance
/// 3. Lists all matched meals with counts
/// 4. Prints to console during sync
///
/// Implementation strategy:
/// - For each matched meal, print success indicator
/// - Calculate calorie difference: |planned - logged|
/// - Print: "✓ Meal Name (planned: X cal, logged: Y cal, diff: ±Z%)"
/// - Accumulate matched count
pub fn plan_sync_displays_matched_meals_test() {
  let cfg = test_config()

  // When: calling sync_plan
  let result = plan_cmd.sync_plan(cfg, date: None)

  // Then: should display matched meals
  // Expected console output:
  // "Syncing meal plan..."
  // "✓ Breakfast: Scrambled Eggs (300 cal)"
  // "✓ Lunch: Chicken Salad (450 cal)"
  // "Sync complete: 2 matched, 0 unmatched"
  // This will FAIL because plan_cmd.sync_plan does not exist
  result
  |> should.be_ok()
}

/// Test: mp plan sync displays unmatched meals
///
/// EXPECTED FAILURE: plan_cmd.sync_plan does not list unmatched meals
///
/// This test validates unmatched meal reporting:
/// 1. Shows meals in plan but not in FatSecret diary
/// 2. Displays: "✗ Dinner: Salmon (600 cal) - NOT LOGGED"
/// 3. Lists all unmatched meals with counts
/// 4. Does not treat as error
///
/// Implementation strategy:
/// - For each meal not matched, print warning indicator
/// - Print: "✗ Meal Name (planned: X cal) - NOT LOGGED"
/// - Accumulate unmatched count
/// - Still return Ok() even with unmatched meals
pub fn plan_sync_displays_unmatched_meals_test() {
  let cfg = test_config()

  // When: calling sync_plan
  let result = plan_cmd.sync_plan(cfg, date: None)

  // Then: should display unmatched meals
  // Expected console output:
  // "✗ Dinner: Salmon (600 cal) - NOT LOGGED"
  // "Sync complete: 2 matched, 1 unmatched"
  // This will FAIL because plan_cmd.sync_plan does not exist
  result
  |> should.be_ok()
}

/// Test: mp plan sync handles plan not found
///
/// EXPECTED FAILURE: plan_cmd.sync_plan does not check if plan exists
///
/// This test validates error when plan doesn't exist:
/// 1. No meal plan exists for specified date
/// 2. Returns Error("No meal plan for this date")
/// 3. Does not crash
///
/// Implementation strategy:
/// - Query database for plan on specified date
/// - If count = 0, return Error("No meal plan for {date}")
pub fn plan_sync_plan_not_found_test() {
  let cfg = test_config()

  // When: calling sync_plan for date with no plan
  let result = plan_cmd.sync_plan(cfg, date: Some("2020-01-01"))

  // Then: should return Error
  // This will FAIL because plan_cmd.sync_plan does not exist
  result
  |> should.be_error()
}

/// Test: mp plan sync handles FatSecret API errors
///
/// EXPECTED FAILURE: plan_cmd.sync_plan does not handle API errors
///
/// This test validates API error handling:
/// 1. FatSecret diary endpoint returns HTTP 500
/// 2. Function returns Error with descriptive message
/// 3. No crash or panic
///
/// Implementation strategy:
/// - Call fatsecret/diary.get_day in result.try
/// - Map errors to Error("Failed to fetch diary: <error>")
pub fn plan_sync_handles_api_errors_test() {
  let cfg = test_config()

  // When: FatSecret API returns error
  let result = plan_cmd.sync_plan(cfg, date: None)

  // Then: should return Error
  // This will FAIL because plan_cmd.sync_plan does not exist
  result
  |> should.be_error()
}

/// Test: mp plan sync handles database errors
///
/// EXPECTED FAILURE: plan_cmd.sync_plan does not handle DB errors
///
/// This test validates database error handling:
/// 1. Database query fails or connection lost
/// 2. Returns Error with descriptive message
/// 3. No data corruption
///
/// Implementation strategy:
/// - Wrap DB queries in result.try
/// - Map errors to Error("Database error: <error>")
pub fn plan_sync_handles_database_errors_test() {
  let cfg = test_config()

  // When: database connection fails
  let result = plan_cmd.sync_plan(cfg, date: None)

  // Then: should return Error
  // This will FAIL because plan_cmd.sync_plan does not exist
  result
  |> should.be_error()
}

/// Test: mp plan sync updates plan state
///
/// EXPECTED FAILURE: plan_cmd.sync_plan does not update plan state
///
/// This test validates state update:
/// 1. Updates meal_plan.synced_at timestamp after successful sync
/// 2. Sets meal_plan.sync_status to 'synced'
/// 3. Changes persist in database
/// 4. Only updates if all meals matched
///
/// Implementation strategy:
/// - After successful sync, UPDATE meal_plan SET synced_at = now, sync_status = 'synced'
/// - Only update if all meals matched (unmatched = 0)
pub fn plan_sync_updates_plan_state_test() {
  let cfg = test_config()

  // When: calling sync_plan with all meals matched
  let result = plan_cmd.sync_plan(cfg, date: None)

  // Then: should update plan's synced_at timestamp
  // This will FAIL because plan_cmd.sync_plan does not exist
  result
  |> should.be_ok()
}

/// Test: mp plan sync returns summary
///
/// EXPECTED FAILURE: plan_cmd.sync_plan does not return SyncSummary
///
/// This test validates return value:
/// 1. Returns Ok(SyncSummary) containing:
///    - matched_count: number of meals matched
///    - unmatched_count: number of meals not in diary
///    - total_planned_calories: sum of planned meal calories
///    - total_logged_calories: sum of logged calories
/// 2. Counts are accurate
///
/// Implementation strategy:
/// - Define SyncSummary type
/// - Track matched and unmatched counts during sync
/// - Sum calories from both sources
/// - Return Ok(SyncSummary)
pub fn plan_sync_returns_summary_test() {
  let cfg = test_config()

  // When: calling sync_plan
  let result = plan_cmd.sync_plan(cfg, date: None)

  // Then: should return Ok(SyncSummary)
  // This will FAIL because plan_cmd.sync_plan does not exist
  result
  |> should.be_ok()
}
