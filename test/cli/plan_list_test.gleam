/// TDD Tests for `mp plan list` command
///
/// Tests the following functionality:
/// 1. Basic list - Display all meal plans
/// 2. Date range filtering - Filter by --start-date and --end-date
/// 3. Grouped by date output - Group meal plans by date
///
/// RED PHASE: All tests MUST fail initially
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/plan as plan_cmd
import meal_planner/config
import meal_planner/tandoor/mealplan.{type MealPlanEntry, MealPlanEntry}

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

/// Create a test meal plan entry
fn test_meal_plan_entry(
  id: Int,
  date: String,
  meal_type_id: Int,
  meal_type_name: String,
  recipe_id: Int,
  title: String,
) -> MealPlanEntry {
  MealPlanEntry(
    id: id,
    title: title,
    recipe_id: Some(recipe_id),
    recipe_name: title,
    servings: 1.0,
    from_date: date,
    to_date: date,
    meal_type_id: meal_type_id,
    meal_type_name: meal_type_name,
    shopping: False,
  )
}

// ============================================================================
// RED PHASE: Failing Tests
// ============================================================================

/// Test: Basic list command displays all meal plans
///
/// Expected behavior:
/// - Call `mp plan list` with no arguments
/// - Should fetch all meal plan entries from Tandoor API
/// - Should display meal plans grouped by date
/// - Should show meal type (Breakfast, Lunch, Dinner)
/// - Should show recipe name and servings
///
/// MUST FAIL: Function `list_meal_plans` does not exist yet
pub fn plan_list_basic_test() {
  let config = test_config()

  // This should call a function that doesn't exist yet
  // Expected signature: list_meal_plans(config: Config) -> Result(String, String)
  let result = plan_cmd.list_meal_plans(config)

  // Should return formatted output
  result
  |> should.be_ok

  // Output should contain meal plan data
  let output = result |> result.unwrap("")
  output
  |> string.contains("2025-12-19")
  |> should.be_true
}

/// Test: Date range filtering with --start-date flag
///
/// Expected behavior:
/// - Call `mp plan list --start-date 2025-12-20`
/// - Should only fetch meal plans from 2025-12-20 onwards
/// - Should not include plans before start date
///
/// MUST FAIL: Function `list_meal_plans_with_filters` does not exist yet
pub fn plan_list_start_date_filter_test() {
  let config = test_config()
  let start_date = "2025-12-20"

  // This should call a function that doesn't exist yet
  // Expected signature: list_meal_plans_with_filters(
  //   config: Config,
  //   start_date: Option(String),
  //   end_date: Option(String)
  // ) -> Result(String, String)
  let result =
    plan_cmd.list_meal_plans_with_filters(
      config,
      start_date: Some(start_date),
      end_date: None,
    )

  result
  |> should.be_ok

  let output = result |> result.unwrap("")

  // Should contain dates >= 2025-12-20
  output
  |> string.contains("2025-12-20")
  |> should.be_true

  // Should NOT contain dates before 2025-12-20
  output
  |> string.contains("2025-12-19")
  |> should.be_false
}

/// Test: Date range filtering with --end-date flag
///
/// Expected behavior:
/// - Call `mp plan list --end-date 2025-12-25`
/// - Should only fetch meal plans up to 2025-12-25
/// - Should not include plans after end date
///
/// MUST FAIL: Function `list_meal_plans_with_filters` does not exist yet
pub fn plan_list_end_date_filter_test() {
  let config = test_config()
  let end_date = "2025-12-25"

  let result =
    plan_cmd.list_meal_plans_with_filters(
      config,
      start_date: None,
      end_date: Some(end_date),
    )

  result
  |> should.be_ok

  let output = result |> result.unwrap("")

  // Should contain dates <= 2025-12-25
  output
  |> string.contains("2025-12-25")
  |> should.be_true

  // Should NOT contain dates after 2025-12-25
  output
  |> string.contains("2025-12-26")
  |> should.be_false
}

/// Test: Date range filtering with both --start-date and --end-date
///
/// Expected behavior:
/// - Call `mp plan list --start-date 2025-12-20 --end-date 2025-12-25`
/// - Should only fetch meal plans within the date range
/// - Should not include plans outside the range
///
/// MUST FAIL: Function `list_meal_plans_with_filters` does not exist yet
pub fn plan_list_date_range_filter_test() {
  let config = test_config()
  let start_date = "2025-12-20"
  let end_date = "2025-12-25"

  let result =
    plan_cmd.list_meal_plans_with_filters(
      config,
      start_date: Some(start_date),
      end_date: Some(end_date),
    )

  result
  |> should.be_ok

  let output = result |> result.unwrap("")

  // Should contain dates in range
  output
  |> string.contains("2025-12-20")
  |> should.be_true

  output
  |> string.contains("2025-12-25")
  |> should.be_true

  // Should NOT contain dates outside range
  output
  |> string.contains("2025-12-19")
  |> should.be_false

  output
  |> string.contains("2025-12-26")
  |> should.be_false
}

/// Test: Grouped by date output format
///
/// Expected behavior:
/// - Meal plans should be grouped by date
/// - Within each date, meals should be ordered: Breakfast, Lunch, Dinner
/// - Each meal should show: meal type, recipe name, servings
///
/// Example output:
/// ```
/// 2025-12-20
///   Breakfast: Oatmeal (1 serving)
///   Lunch: Chicken Salad (1 serving)
///   Dinner: Grilled Salmon (1 serving)
///
/// 2025-12-21
///   Breakfast: Scrambled Eggs (1 serving)
///   ...
/// ```
///
/// MUST FAIL: Function `format_meal_plans_grouped_by_date` does not exist yet
pub fn plan_list_grouped_by_date_output_test() {
  // Create test meal plan entries
  // Meal type IDs: 1=Breakfast, 2=Lunch, 3=Dinner
  let meal_plans = [
    test_meal_plan_entry(1, "2025-12-20", 1, "Breakfast", 101, "Oatmeal"),
    test_meal_plan_entry(2, "2025-12-20", 2, "Lunch", 102, "Chicken Salad"),
    test_meal_plan_entry(3, "2025-12-20", 3, "Dinner", 103, "Grilled Salmon"),
    test_meal_plan_entry(4, "2025-12-21", 1, "Breakfast", 104, "Scrambled Eggs"),
  ]

  // This should call a function that doesn't exist yet
  // Expected signature: format_meal_plans_grouped_by_date(
  //   meal_plans: List(MealPlanEntry)
  // ) -> String
  let output = plan_cmd.format_meal_plans_grouped_by_date(meal_plans)

  // Output should contain dates as headers
  output
  |> string.contains("2025-12-20")
  |> should.be_true

  output
  |> string.contains("2025-12-21")
  |> should.be_true

  // Output should contain meal types
  output
  |> string.contains("Breakfast")
  |> should.be_true

  output
  |> string.contains("Lunch")
  |> should.be_true

  output
  |> string.contains("Dinner")
  |> should.be_true

  // Output should contain recipe names
  output
  |> string.contains("Oatmeal")
  |> should.be_true

  output
  |> string.contains("Chicken Salad")
  |> should.be_true

  output
  |> string.contains("Grilled Salmon")
  |> should.be_true

  // Meals should be ordered: Breakfast before Lunch before Dinner
  let breakfast_idx = string_index_of(output, "Breakfast")
  let lunch_idx = string_index_of(output, "Lunch")
  let dinner_idx = string_index_of(output, "Dinner")

  // Breakfast should come before Lunch
  case breakfast_idx < lunch_idx {
    True -> should.be_true(True)
    False -> should.be_true(False)
  }

  // Lunch should come before Dinner
  case lunch_idx < dinner_idx {
    True -> should.be_true(True)
    False -> should.be_true(False)
  }
}

/// Test: Empty meal plan list
///
/// Expected behavior:
/// - When no meal plans exist, should display a friendly message
/// - Should not error out
///
/// MUST FAIL: Function `format_meal_plans_grouped_by_date` does not exist yet
pub fn plan_list_empty_test() {
  let meal_plans = []

  let output = plan_cmd.format_meal_plans_grouped_by_date(meal_plans)

  // Should contain a message indicating no meal plans
  output
  |> string.contains("No meal plans")
  |> should.be_true
}

// ============================================================================
// Helper Functions (Minimal implementations for tests to compile)
// ============================================================================

/// Helper to find string index (simplified)
fn string_index_of(haystack: String, needle: String) -> Int {
  case string.split(haystack, needle) {
    [before, ..] -> string.length(before)
    [] -> -1
  }
}
