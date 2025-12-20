/// TDD Tests for `mp plan delete` command
///
/// Tests the following functionality:
/// 1. Delete by date with --confirm flag - Deletes all meal plans for a given date
/// 2. Safety check without --confirm flag - Prevents accidental deletion
/// 3. Confirmation message - Displays what was deleted
/// 4. Invalid date handling - Proper error for malformed dates
/// 5. Non-existent date handling - Handles dates with no meal plans
///
/// RED PHASE: All tests MUST fail initially
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/plan as plan_cmd
import meal_planner/config

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Helpers
// ============================================================================

/// Create a minimal test config for meal plan operations
fn test_config() -> config.Config {
  config.Config(
    environment: config.Development,
    database: config.DatabaseConfig(
      host: "localhost",
      port: 5432,
      name: "test_db",
      user: "test_user",
      password: "test_pass",
      pool_size: 5,
      connection_timeout_ms: 5000,
    ),
    server: config.ServerConfig(port: 8000, cors_allowed_origins: []),
    tandoor: config.TandoorConfig(
      base_url: "http://localhost:8080",
      api_token: "test-token",
      connect_timeout_ms: 5000,
      request_timeout_ms: 5000,
    ),
    external_services: config.ExternalServicesConfig(
      fatsecret: Some(config.FatSecretConfig(
        consumer_key: "test-key",
        consumer_secret: "test-secret",
      )),
      todoist_api_key: "test-todoist",
      usda_api_key: "test-usda",
      openai_api_key: "test-openai",
      openai_model: "gpt-4",
    ),
    secrets: config.SecretsConfig(
      oauth_encryption_key: None,
      jwt_secret: None,
      database_password: "test-pass",
      tandoor_token: "test-token",
    ),
    logging: config.LoggingConfig(level: config.InfoLevel, debug_mode: False),
    performance: config.PerformanceConfig(
      request_timeout_ms: 5000,
      connection_timeout_ms: 5000,
      max_concurrent_requests: 10,
      rate_limit_requests: 100,
    ),
  )
}

// ============================================================================
// RED PHASE: Failing Tests
// ============================================================================

/// Test: Delete meal plan by date with --confirm flag
///
/// Expected behavior:
/// - Call `mp plan delete 2025-12-20 --confirm`
/// - Should validate date format (YYYY-MM-DD)
/// - Should fetch all meal plans for that date
/// - Should delete each meal plan for the date
/// - Should return success message with count of deleted items
///
/// MUST FAIL: Function `delete_meal_plan_by_date` does not exist yet
pub fn plan_delete_with_confirm_flag_test() {
  let config = test_config()
  let date = "2025-12-20"

  // This should call a function that doesn't exist yet
  // Expected signature: delete_meal_plan_by_date(
  //   config: Config,
  //   date: String,
  //   confirmed: Bool
  // ) -> Result(String, String)
  let result = plan_cmd.delete_meal_plan_by_date(config, date, confirmed: True)

  // Should return success message
  result
  |> should.be_ok

  let output = result |> should.be_ok

  // Output should confirm deletion
  output
  |> string.contains("Deleted")
  |> should.be_true

  // Output should mention the date
  output
  |> string.contains("2025-12-20")
  |> should.be_true
}

/// Test: Safety check - deletion without --confirm flag should fail
///
/// Expected behavior:
/// - Call `mp plan delete 2025-12-20` (without --confirm)
/// - Should NOT delete any meal plans
/// - Should return error message prompting user to add --confirm flag
/// - Safety mechanism to prevent accidental deletion
///
/// MUST FAIL: Function `delete_meal_plan_by_date` does not exist yet
pub fn plan_delete_without_confirm_flag_test() {
  let config = test_config()
  let date = "2025-12-20"

  // Attempt to delete without confirmation
  let result = plan_cmd.delete_meal_plan_by_date(config, date, confirmed: False)

  // Should return an error
  result
  |> should.be_error

  let error_msg = result |> should.be_error

  // Error should mention confirmation requirement
  error_msg
  |> string.contains("--confirm")
  |> should.be_true
}

/// Test: Confirmation message shows what was deleted
///
/// Expected behavior:
/// - Call `mp plan delete 2025-12-20 --confirm`
/// - Success message should show:
///   - Number of meal plans deleted (e.g., "Deleted 3 meal plans")
///   - The date that was targeted
///   - List of deleted meal types (Breakfast, Lunch, Dinner)
///
/// MUST FAIL: Function `delete_meal_plan_by_date` does not exist yet
pub fn plan_delete_confirmation_message_test() {
  let config = test_config()
  let date = "2025-12-20"

  let result = plan_cmd.delete_meal_plan_by_date(config, date, confirmed: True)

  result
  |> should.be_ok

  let output = result |> should.be_ok

  // Should show count of deleted items
  // Using a flexible check - could be "Deleted 0", "Deleted 1", "Deleted 3", etc.
  output
  |> string.contains("Deleted")
  |> should.be_true

  // Should show the target date
  output
  |> string.contains(date)
  |> should.be_true

  // Should indicate meal plans (plural form acceptable)
  let has_meal_plan_singular = string.contains(output, "meal plan")
  let has_meal_plan_plural = string.contains(output, "meal plans")

  case has_meal_plan_singular || has_meal_plan_plural {
    True -> should.be_true(True)
    False -> should.be_true(False)
  }
}

/// Test: Invalid date format handling
///
/// Expected behavior:
/// - Call `mp plan delete invalid-date --confirm`
/// - Should validate date format before attempting deletion
/// - Should return error message indicating invalid date format
/// - Should show expected format (YYYY-MM-DD)
///
/// MUST FAIL: Function `delete_meal_plan_by_date` does not exist yet
pub fn plan_delete_invalid_date_test() {
  let config = test_config()
  let invalid_date = "12/20/2025"

  let result =
    plan_cmd.delete_meal_plan_by_date(config, invalid_date, confirmed: True)

  // Should return an error
  result
  |> should.be_error

  let error_msg = result |> should.be_error

  // Error should mention invalid date or date format
  let has_invalid = string.contains(error_msg, "Invalid")
  let has_date = string.contains(error_msg, "date")

  case has_invalid && has_date {
    True -> should.be_true(True)
    False -> should.be_true(False)
  }

  // Error should show expected format
  error_msg
  |> string.contains("YYYY-MM-DD")
  |> should.be_true
}

/// Test: Deleting date with no meal plans
///
/// Expected behavior:
/// - Call `mp plan delete 2099-12-31 --confirm` (future date unlikely to have plans)
/// - Should not error out
/// - Should return success message indicating 0 meal plans deleted
/// - Should be a no-op, but not a failure
///
/// MUST FAIL: Function `delete_meal_plan_by_date` does not exist yet
pub fn plan_delete_empty_date_test() {
  let config = test_config()
  let empty_date = "2099-12-31"

  let result =
    plan_cmd.delete_meal_plan_by_date(config, empty_date, confirmed: True)

  // Should succeed even if nothing to delete
  result
  |> should.be_ok

  let output = result |> should.be_ok

  // Output should indicate deletion (even if 0 items)
  output
  |> string.contains("Deleted")
  |> should.be_true

  // Could check for "0 meal plans" but implementation may vary
  // At minimum, should contain the date
  output
  |> string.contains(empty_date)
  |> should.be_true
}

/// Test: Date parsing uses existing parse_date helper
///
/// Expected behavior:
/// - Should reuse the existing `parse_date` function from plan module
/// - Valid dates should parse successfully
/// - Invalid dates should return proper error
///
/// MUST FAIL: Test will fail if parse_date behavior changes or is not reused
pub fn plan_delete_date_parsing_consistency_test() {
  // Valid date should parse
  let valid_result = plan_cmd.parse_date("2025-12-20")
  valid_result
  |> should.be_ok

  // Invalid date should fail with proper error message
  let invalid_result = plan_cmd.parse_date("not-a-date")
  invalid_result
  |> should.be_error

  let error = invalid_result |> should.be_error
  error
  |> string.contains("Invalid date")
  |> should.be_true
}

/// Test: Multiple meal plans deleted on same date
///
/// Expected behavior:
/// - If date has 3 meal plans (Breakfast, Lunch, Dinner)
/// - All 3 should be deleted
/// - Confirmation should show count of 3
///
/// MUST FAIL: Function `delete_meal_plan_by_date` does not exist yet
pub fn plan_delete_multiple_meals_same_date_test() {
  let config = test_config()
  let date = "2025-12-20"

  // Assuming test data has multiple meal plans for this date
  let result = plan_cmd.delete_meal_plan_by_date(config, date, confirmed: True)

  result
  |> should.be_ok

  let output = result |> should.be_ok

  // Should mention deletion
  output
  |> string.contains("Deleted")
  |> should.be_true

  // Should contain the date
  output
  |> string.contains(date)
  |> should.be_true

  // Should use plural "meal plans" if multiple (implementation-dependent)
  // This is a soft check - actual count depends on test data
  let has_meal_plans = string.contains(output, "meal plan")
  has_meal_plans
  |> should.be_true
}
