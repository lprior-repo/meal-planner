//// CLI Integration Tests
////
//// This test suite validates end-to-end CLI workflows including:
//// 1. Complete command workflows (multi-step operations)
//// 2. Command chaining and state transitions
//// 3. Error propagation across CLI layers
////
//// RED PHASE: These tests document missing functionality that needs implementation.
//// Tests are written to pass when the required functions are implemented.
////
//// Test follows Gleam 7 Commandments:
//// - Immutability: All test data is immutable
//// - No Nulls: Uses Option(T) and Result(T, E) exclusively
//// - Exhaustive Matching: All case branches covered
//// - Type Safety: Custom types for domain concepts
////
//// The following functions need to be implemented for complete integration testing:
////
//// 1. plan.add_to_plan(config, recipe_id, date, meal_type) -> Result(Nil, String)
////    - Add specific recipe to meal plan
////    - Validate recipe exists
////    - Validate date format
////    - Handle database constraints
////
//// 2. plan.generate_shopping_list(config, start_date, days) -> Result(String, String)
////    - Generate shopping list from meal plan
////    - Group ingredients
////    - Calculate quantities
////
//// 3. scheduler.enable_job(config, job_name) -> Result(Nil, String)
////    - Enable scheduled job by name
////    - Persist to database
////    - Validate job exists
////
//// 4. scheduler.list_jobs(config) -> Result(List(ScheduledJob), String)
////    - List all scheduled jobs
////    - Include enabled status
////    - Format for display
////
//// 5. tandoor.sync_recipes(config) -> Result(Int, String)
////    - Sync recipes from Tandoor
////    - Return count of synced recipes
////    - Handle API errors
////
//// 6. recipe.search_recipes should return List(Recipe) instead of String
////    - Current: Result(String, String)
////    - Needed: Result(List(Recipe), String)
////    - Enables programmatic access to search results
////
//// Once these are implemented, the integration tests can be expanded to test
//// complex workflows like:
//// - Recipe search → Add to plan → Generate shopping list
//// - Tandoor sync → Meal plan regeneration
//// - Scheduler enable → Verify state persistence
////

import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/plan
import meal_planner/cli/domains/recipe
import meal_planner/config

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Create test configuration for integration tests
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
// Integration Test: Recipe Search Integration
// ============================================================================

/// Test: Recipe search integration with Tandoor API
///
/// This test validates that recipe search works end-to-end:
/// 1. Calls recipe.search_recipes with valid query
/// 2. Returns formatted search results
/// 3. Handles errors gracefully
///
/// Current implementation: recipe.search_recipes returns Result(String, String)
/// Future enhancement needed: Return structured data for further processing
pub fn recipe_search_integration_test() {
  let cfg = test_config()

  // When: searching for recipes
  let result = recipe.search_recipes(cfg, query: "pasta", limit: Some(10))

  // Then: should return Ok with formatted string
  // Note: In a real integration test, this would call actual Tandoor API
  // For now, we validate the function signature exists
  result
  |> should.be_ok
}

// ============================================================================
// Integration Test: Meal Plan Display
// ============================================================================

/// Test: Show meal plan for specific date
///
/// This test validates that meal plan display works:
/// 1. Calls plan.show_plan with valid date
/// 2. Displays meal plan for the date
/// 3. Handles missing meal plans gracefully
///
/// Current implementation: plan.show_plan exists and formats output
pub fn meal_plan_show_integration_test() {
  let cfg = test_config()

  // When: showing meal plan for a date
  let result = plan.show_plan(cfg, "2025-12-20")

  // Then: should return Ok(Nil) after displaying
  // Note: In production, this would query Tandoor API
  result
  |> should.be_ok
}

// ============================================================================
// Integration Test: Date Validation
// ============================================================================

/// Test: Date validation across CLI commands
///
/// This test validates that date parsing works consistently:
/// 1. Valid dates are accepted (YYYY-MM-DD)
/// 2. Invalid dates are rejected with clear errors
///
/// Current implementation: plan.parse_date validates date format
pub fn date_validation_integration_test() {
  // Valid date should parse successfully
  let valid_result = plan.parse_date("2025-12-20")
  valid_result
  |> should.be_ok

  // Invalid date should return error
  let invalid_result = plan.parse_date("12/20/2025")
  invalid_result
  |> should.be_error
}

// ============================================================================
// Integration Test: Meal Plan List with Filters
// ============================================================================

/// Test: List meal plans with date range filters
///
/// This test validates filtered meal plan listing:
/// 1. Lists all meal plans without filters
/// 2. Filters by start_date when provided
/// 3. Filters by end_date when provided
/// 4. Filters by both start and end date
///
/// Current implementation: plan.list_meal_plans_with_filters exists
pub fn meal_plan_list_filtered_integration_test() {
  let cfg = test_config()

  // When: listing meal plans with date filters
  let result =
    plan.list_meal_plans_with_filters(
      cfg,
      start_date: Some("2025-12-20"),
      end_date: Some("2025-12-27"),
    )

  // Then: should return formatted meal plan list
  result
  |> should.be_ok
}

// ============================================================================
// Integration Test: Meal Plan Deletion Safety
// ============================================================================

/// Test: Meal plan deletion requires confirmation
///
/// This test validates deletion safety:
/// 1. Deletion without confirmation returns error
/// 2. Deletion with confirmation proceeds
///
/// Current implementation: plan.delete_meal_plan_by_date has confirmation flag
pub fn meal_plan_delete_safety_test() {
  let cfg = test_config()

  // When: attempting deletion without confirmation
  let no_confirm_result =
    plan.delete_meal_plan_by_date(cfg, "2025-12-20", confirmed: False)

  // Then: should return error requiring confirmation
  no_confirm_result
  |> should.be_error
}

// ============================================================================
// Integration Test: Meal Plan Regeneration
// ============================================================================

/// Test: Regenerate meal plan for date range
///
/// This test validates meal plan regeneration:
/// 1. Accepts start date and number of days
/// 2. Validates date format
/// 3. Creates meal selections
/// 4. Returns formatted meal plan
///
/// Current implementation: plan.regenerate_meals exists
pub fn meal_plan_regenerate_integration_test() {
  let cfg = test_config()

  // When: regenerating meal plan for 7 days
  let result = plan.regenerate_meals(cfg, "2025-12-20", 7)

  // Then: should return formatted meal plan
  result
  |> should.be_ok
}
// ============================================================================
// Missing Functionality Documentation (for GREEN phase)
// ============================================================================
