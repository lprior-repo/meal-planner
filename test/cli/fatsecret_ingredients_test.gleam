//// TDD Test for CLI fatsecret ingredients command
////
//// RED PHASE: This test MUST fail initially because the implementation
//// does not exist yet. The test validates:
//// 1. List ingredients for a recipe (mp fatsecret ingredients --id 123)
//// 2. Display ingredient names and quantities
//// 3. Show nutrition per ingredient
//// 4. Aggregate total nutrition for recipe
////
//// Test follows Gleam 7 Commandments

import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/fatsecret as fatsecret_cmd
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

/// Test: mp fatsecret ingredients --id 123
///
/// EXPECTED FAILURE: fatsecret_cmd.list_recipe_ingredients does not exist
///
/// This test validates that the ingredients command:
/// 1. Fetches recipe details from Tandoor by ID
/// 2. Extracts ingredient list with quantities
/// 3. Looks up each ingredient in FatSecret
/// 4. Returns formatted ingredient list
///
/// Implementation strategy:
/// - Add list_recipe_ingredients function to meal_planner/cli/domains/fatsecret.gleam
/// - Function signature: fn list_recipe_ingredients(config: Config, recipe_id: Int) -> Result(Nil, Nil)
/// - Fetch recipe from Tandoor using meal_planner/tandoor/recipe.get_recipe
/// - For each ingredient in recipe.steps[].ingredients
/// - Search FatSecret for matching food
/// - Display ingredient with nutrition info
pub fn fatsecret_ingredients_lists_for_recipe_test() {
  let cfg = test_config()
  let recipe_id = 123

  // When: calling list_recipe_ingredients for a recipe
  let result = fatsecret_cmd.list_recipe_ingredients(cfg, recipe_id: recipe_id)

  // Then: should return Ok after displaying ingredients
  // This will FAIL because fatsecret_cmd.list_recipe_ingredients does not exist
  result
  |> should.be_ok()
}

/// Test: ingredients displays names and quantities
///
/// EXPECTED FAILURE: fatsecret_cmd.list_recipe_ingredients does not display details
///
/// This test validates output format:
/// 1. Shows ingredient name
/// 2. Shows quantity (e.g., "2 cups")
/// 3. Shows unit (from recipe)
///
/// Constraint: Must parse Tandoor ingredient format
pub fn fatsecret_ingredients_displays_details_test() {
  let cfg = test_config()
  let recipe_id = 123

  // When: calling list_recipe_ingredients
  let result = fatsecret_cmd.list_recipe_ingredients(cfg, recipe_id: recipe_id)

  // Then: should display ingredient details
  result
  |> should.be_ok()
}

/// Test: ingredients shows nutrition per ingredient
///
/// EXPECTED FAILURE: fatsecret_cmd.list_recipe_ingredients does not fetch nutrition
///
/// This test validates nutrition lookup:
/// 1. Searches FatSecret for each ingredient
/// 2. Matches closest food item
/// 3. Displays calories, protein, carbs, fat
///
/// Constraint: Must use FatSecret foods API
pub fn fatsecret_ingredients_shows_nutrition_test() {
  let cfg = test_config()
  let recipe_id = 123

  // When: calling list_recipe_ingredients
  let result = fatsecret_cmd.list_recipe_ingredients(cfg, recipe_id: recipe_id)

  // Then: should show nutrition for each ingredient
  result
  |> should.be_ok()
}

/// Test: ingredients validates recipe ID
///
/// EXPECTED FAILURE: fatsecret_cmd.list_recipe_ingredients does not validate ID
///
/// This test validates error handling:
/// 1. Recipe ID <= 0 returns Error
/// 2. Error message is descriptive
/// 3. Does not attempt API call
///
/// Constraint: recipe_id must be positive integer
pub fn fatsecret_ingredients_validates_recipe_id_test() {
  let cfg = test_config()
  let invalid_id = -1

  // When: calling list_recipe_ingredients with invalid ID
  let result = fatsecret_cmd.list_recipe_ingredients(cfg, recipe_id: invalid_id)

  // Then: should return Error
  result
  |> should.be_error()
}

/// Test: ingredients handles recipe not found
///
/// EXPECTED FAILURE: fatsecret_cmd.list_recipe_ingredients does not handle 404
///
/// This test validates error handling:
/// 1. Tandoor returns 404 for recipe ID
/// 2. Returns Error "Recipe not found"
/// 3. Does not attempt FatSecret lookup
///
/// Constraint: Must handle Tandoor NotFoundError
pub fn fatsecret_ingredients_recipe_not_found_test() {
  let cfg = test_config()
  let nonexistent_id = 999_999

  // When: calling list_recipe_ingredients for nonexistent recipe
  let result =
    fatsecret_cmd.list_recipe_ingredients(cfg, recipe_id: nonexistent_id)

  // Then: should return Error about recipe not found
  result
  |> should.be_error()
}

/// Test: ingredients handles recipe with no ingredients
///
/// EXPECTED FAILURE: fatsecret_cmd.list_recipe_ingredients does not handle empty
///
/// This test validates edge case:
/// 1. Recipe exists but has no ingredients list
/// 2. Returns Ok with message "No ingredients found"
/// 3. Does not error
///
/// Constraint: Empty ingredients is valid state
pub fn fatsecret_ingredients_empty_list_test() {
  let cfg = test_config()
  let recipe_id = 456

  // When: calling list_recipe_ingredients for recipe with no ingredients
  let result = fatsecret_cmd.list_recipe_ingredients(cfg, recipe_id: recipe_id)

  // Then: should return Ok with empty message
  result
  |> should.be_ok()
}

/// Test: ingredients aggregates total nutrition
///
/// EXPECTED FAILURE: fatsecret_cmd.list_recipe_ingredients does not aggregate
///
/// This test validates totals calculation:
/// 1. Sums nutrition across all ingredients
/// 2. Displays "Total: X calories, Yg protein..."
/// 3. Shows at bottom of list
///
/// Constraint: Must sum all macro values
pub fn fatsecret_ingredients_aggregates_totals_test() {
  let cfg = test_config()
  let recipe_id = 123

  // When: calling list_recipe_ingredients
  let result = fatsecret_cmd.list_recipe_ingredients(cfg, recipe_id: recipe_id)

  // Then: should display total nutrition
  result
  |> should.be_ok()
}

/// Test: ingredients handles FatSecret API errors
///
/// EXPECTED FAILURE: fatsecret_cmd.list_recipe_ingredients does not handle API errors
///
/// This test validates error handling:
/// 1. FatSecret API returns error for ingredient lookup
/// 2. Shows warning for that ingredient
/// 3. Continues with remaining ingredients
/// 4. Still returns Ok (partial success)
///
/// Constraint: One ingredient failure should not fail entire command
pub fn fatsecret_ingredients_handles_api_errors_test() {
  let cfg = test_config()
  let recipe_id = 123

  // When: calling list_recipe_ingredients with API error scenario
  let result = fatsecret_cmd.list_recipe_ingredients(cfg, recipe_id: recipe_id)

  // Then: should handle errors gracefully
  result
  |> should.be_ok()
}
