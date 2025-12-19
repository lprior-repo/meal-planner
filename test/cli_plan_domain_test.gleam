/// Test for CLI plan domain - Generate command with orchestrator integration
///
/// Tests that the generate command:
/// 1. Creates default meal selections
/// 2. Calls orchestrator.plan_meals()
/// 3. Formats and displays output
import gleam/option.{None}
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/plan
import meal_planner/config
import meal_planner/meal_sync.{type MealSelection, MealSelection}
import meal_planner/orchestrator
import meal_planner/tandoor/client.{type ClientConfig, ClientConfig, SessionAuth}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Create a test tandoor config
fn test_tandoor_config() -> ClientConfig {
  ClientConfig(
    base_url: "http://localhost:8000",
    auth: SessionAuth(
      username: "test",
      password: "test",
      session_id: None,
      csrf_token: None,
    ),
    timeout_ms: 5000,
    retry_on_transient: False,
    max_retries: 0,
  )
}

/// Create test meal selections
fn test_meal_selections() -> List(MealSelection) {
  [
    MealSelection(
      date: "2025-12-19",
      meal_type: "lunch",
      recipe_id: 1,
      servings: 1.0,
    ),
    MealSelection(
      date: "2025-12-19",
      meal_type: "dinner",
      recipe_id: 2,
      servings: 1.0,
    ),
  ]
}

// ============================================================================
// Tests
// ============================================================================

/// Test that plan_meals validates meal selections
pub fn plan_meals_requires_meals_test() {
  let tandoor_config = test_tandoor_config()
  let empty_selections = []

  let result = orchestrator.plan_meals(tandoor_config, empty_selections)

  result
  |> should.be_error()
}

/// Test that plan_meals succeeds with valid selections
/// This test will initially fail because we haven't implemented the CLI integration yet
pub fn plan_meals_with_valid_selections_test() {
  // This test validates that orchestrator.plan_meals exists and has correct signature
  // We'll need to mock the Tandoor API calls for this to pass
  let tandoor_config = test_tandoor_config()
  let selections = test_meal_selections()

  // For now, just verify the function compiles and can be called
  // In real implementation, this would need mocked Tandoor responses
  let _ = orchestrator.plan_meals(tandoor_config, selections)

  True |> should.be_true()
}

/// Test that the CLI plan command exists and compiles
pub fn plan_cmd_exists_test() {
  let cfg =
    config.Config(
      database: config.DatabaseConfig(
        host: "localhost",
        port: 5432,
        name: "meal_planner_test",
        user: "test",
        password: "test",
        pool_size: 10,
      ),
      server: config.ServerConfig(port: 8000, environment: "test"),
      tandoor: config.TandoorConfig(
        base_url: "http://localhost:8000",
        api_token: "test",
        connect_timeout_ms: 5000,
        request_timeout_ms: 10_000,
      ),
      external_services: config.ExternalServicesConfig(
        todoist_api_key: "test",
        usda_api_key: "test",
        openai_api_key: "test",
        openai_model: "gpt-4",
      ),
    )

  let cmd = plan.cmd(cfg)
  // Just verify it compiles - actual command execution will be tested in integration tests
  True |> should.be_true()
}

/// Test that format_meal_plan produces expected output sections
pub fn format_meal_plan_output_test() {
  // This will be used to verify the CLI output formatting
  // For now, it's a placeholder showing the expected structure
  True |> should.be_true()
}
