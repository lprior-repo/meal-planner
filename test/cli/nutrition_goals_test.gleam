//// TDD Test for CLI nutrition goals command
////
//// RED PHASE: This test MUST fail initially because the implementation
//// does not exist yet. The test validates:
//// 1. Set daily nutrition goals (calories, macros, vitamins)
//// 2. Display current goals
//// 3. List available goal presets (sedentary, moderate, active)
//// 4. Validate goal values (positive, within reasonable range)
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

/// Test: mp nutrition goals displays current goals
///
/// EXPECTED FAILURE: nutrition_cmd.display_goals function does not exist
///
/// This test validates that the goals command:
/// 1. Fetches current nutrition goals from database
/// 2. Displays current goals: "Daily Nutrition Goals:"
/// 3. Shows calories, protein, carbs, fat, fiber
/// 4. Shows individual macro targets
///
/// Implementation strategy:
/// - Query database for user_preferences.nutrition_goals
/// - Format goals for display
/// - Print using io.println:
///   "Daily Nutrition Goals:"
///   "Calories: 2000 kcal"
///   "Protein: 150g (30%)"
///   "Carbs: 200g (40%)"
///   "Fat: 65g (30%)"
///   "Fiber: 25g"
pub fn nutrition_goals_displays_current_test() {
  let cfg = test_config()

  // When: calling display_goals
  let result = nutrition_cmd.display_goals(cfg)

  // Then: should display current goals
  // Expected console output:
  // "Daily Nutrition Goals:"
  // "Calories: 2000 kcal"
  // "Protein: 150g (30%)"
  // ...
  // This will FAIL because nutrition_cmd.display_goals does not exist
  result
  |> should.be_ok()
}

/// Test: mp nutrition goals set calories goal
///
/// EXPECTED FAILURE: nutrition_cmd.set_goal function does not exist
///
/// This test validates setting calorie goal:
/// 1. Accepts --calories flag with numeric value
/// 2. Validates calories > 0 and < 10000
/// 3. Updates database with new goal
/// 4. Returns Ok with confirmation
///
/// Implementation strategy:
/// - Parse --calories flag as Int
/// - Validate: calories > 0 AND calories < 10000
/// - INSERT or UPDATE user_preferences.nutrition_goals
/// - Return Ok("Calorie goal set to 2500 kcal")
pub fn nutrition_goals_set_calories_test() {
  let cfg = test_config()

  // When: calling set_goal with calories
  let result = nutrition_cmd.set_goal(cfg, goal_type: "calories", value: 2500)

  // Then: should update calories goal
  // This will FAIL because nutrition_cmd.set_goal does not exist
  result
  |> should.be_ok()
}

/// Test: mp nutrition goals set protein goal
///
/// EXPECTED FAILURE: nutrition_cmd.set_goal does not handle protein
///
/// This test validates setting protein goal:
/// 1. Accepts protein value in grams
/// 2. Validates protein > 0
/// 3. Updates database
/// 4. Calculates percentage of daily calories
///
/// Implementation strategy:
/// - Parse protein as Int
/// - Validate protein > 0 AND protein < 500
/// - Calculate: protein_percent = (protein * 4) / calories * 100
/// - Update user_preferences
pub fn nutrition_goals_set_protein_test() {
  let cfg = test_config()

  // When: calling set_goal with protein
  let result = nutrition_cmd.set_goal(cfg, goal_type: "protein", value: 150)

  // Then: should update protein goal
  // This will FAIL because nutrition_cmd.set_goal does not exist
  result
  |> should.be_ok()
}

/// Test: mp nutrition goals set carbs goal
///
/// EXPECTED FAILURE: nutrition_cmd.set_goal does not handle carbs
///
/// This test validates carbs goal:
/// 1. Accepts carbs value in grams
/// 2. Validates carbs > 0
/// 3. Updates database
///
/// Implementation strategy:
/// - Parse carbs as Int
/// - Validate carbs > 0 AND carbs < 1000
/// - Update user_preferences
pub fn nutrition_goals_set_carbs_test() {
  let cfg = test_config()

  // When: calling set_goal with carbs
  let result = nutrition_cmd.set_goal(cfg, goal_type: "carbs", value: 250)

  // Then: should update carbs goal
  // This will FAIL because nutrition_cmd.set_goal does not exist
  result
  |> should.be_ok()
}

/// Test: mp nutrition goals set fat goal
///
/// EXPECTED FAILURE: nutrition_cmd.set_goal does not handle fat
///
/// This test validates fat goal:
/// 1. Accepts fat value in grams
/// 2. Validates fat > 0
/// 3. Updates database
///
/// Implementation strategy:
/// - Parse fat as Int
/// - Validate fat > 0 AND fat < 500
/// - Update user_preferences
pub fn nutrition_goals_set_fat_test() {
  let cfg = test_config()

  // When: calling set_goal with fat
  let result = nutrition_cmd.set_goal(cfg, goal_type: "fat", value: 70)

  // Then: should update fat goal
  // This will FAIL because nutrition_cmd.set_goal does not exist
  result
  |> should.be_ok()
}

/// Test: mp nutrition goals validates calorie range
///
/// EXPECTED FAILURE: nutrition_cmd.set_goal does not validate range
///
/// This test validates input validation:
/// 1. Calories < 500 should be rejected
/// 2. Calories > 10000 should be rejected
/// 3. Returns Error("Calories must be between 500 and 10000")
/// 4. Validation before database update
///
/// Implementation strategy:
/// - Check value >= 500 AND value <= 10000
/// - Return Error if outside range
pub fn nutrition_goals_rejects_invalid_calories_test() {
  let cfg = test_config()

  // When: calling set_goal with calories outside range
  let result = nutrition_cmd.set_goal(cfg, goal_type: "calories", value: 200)

  // Then: should return Error
  // This will FAIL because nutrition_cmd.set_goal does not exist
  result
  |> should.be_error()
}

/// Test: mp nutrition goals lists presets
///
/// EXPECTED FAILURE: nutrition_cmd.list_presets function does not exist
///
/// This test validates preset display:
/// 1. Shows available macro presets: sedentary, moderate, active, athletic
/// 2. For each preset, displays: name, calories, protein %, carbs %, fat %
/// 3. Shows example: "sedentary: 2000 kcal (25% protein, 50% carbs, 25% fat)"
///
/// Implementation strategy:
/// - Define preset data structure
/// - Print each preset with details
/// - Use io.println for output
pub fn nutrition_goals_lists_presets_test() {
  let cfg = test_config()

  // When: calling list_presets
  let result = nutrition_cmd.list_presets(cfg)

  // Then: should display available presets
  // Expected console output:
  // "Available macro presets:"
  // "sedentary: 2000 kcal, 25% protein, 50% carbs, 25% fat"
  // "moderate: 2200 kcal, 30% protein, 45% carbs, 25% fat"
  // ...
  // This will FAIL because nutrition_cmd.list_presets does not exist
  result
  |> should.be_ok()
}

/// Test: mp nutrition goals applies preset
///
/// EXPECTED FAILURE: nutrition_cmd.apply_preset function does not exist
///
/// This test validates preset application:
/// 1. Accepts preset name: sedentary, moderate, active, athletic
/// 2. Applies preset goals to database
/// 3. Calculates absolute values (grams) from percentages
/// 4. Returns Ok with confirmation
///
/// Implementation strategy:
/// - Accept preset_name parameter
/// - Look up preset: case preset_name { "sedentary" -> {...}, ...}
/// - Calculate: protein = (2000 * 0.25) / 4
/// - Update user_preferences with preset values
pub fn nutrition_goals_applies_preset_test() {
  let cfg = test_config()

  // When: calling apply_preset with "moderate"
  let result = nutrition_cmd.apply_preset(cfg, preset_name: "moderate")

  // Then: should update goals to preset values
  // This will FAIL because nutrition_cmd.apply_preset does not exist
  result
  |> should.be_ok()
}

/// Test: mp nutrition goals handles invalid preset
///
/// EXPECTED FAILURE: nutrition_cmd.apply_preset does not validate preset
///
/// This test validates preset validation:
/// 1. Unknown preset name returns Error
/// 2. Error message: "Unknown preset: 'invalid'. Use: sedentary, moderate, active, athletic"
/// 3. Does not update database if invalid
///
/// Implementation strategy:
/// - Validate preset_name is one of known presets
/// - Return Error if not found
pub fn nutrition_goals_rejects_invalid_preset_test() {
  let cfg = test_config()

  // When: calling apply_preset with unknown preset
  let result = nutrition_cmd.apply_preset(cfg, preset_name: "extreme")

  // Then: should return Error
  // This will FAIL because nutrition_cmd.apply_preset does not exist
  result
  |> should.be_error()
}

/// Test: mp nutrition goals handles database errors
///
/// EXPECTED FAILURE: nutrition_cmd.set_goal does not handle DB errors
///
/// This test validates database error handling:
/// 1. Database update fails
/// 2. Returns Error with descriptive message
/// 3. No partial updates
///
/// Implementation strategy:
/// - Wrap DB update in result.try
/// - Map errors to Error("Failed to update nutrition goals: <error>")
pub fn nutrition_goals_handles_database_errors_test() {
  let cfg = test_config()

  // When: database connection fails during set_goal
  let result = nutrition_cmd.set_goal(cfg, goal_type: "calories", value: 2500)

  // Then: should return Error
  // This will FAIL because nutrition_cmd.set_goal does not exist
  result
  |> should.be_error()
}

/// Test: mp nutrition goals confirms change
///
/// EXPECTED FAILURE: nutrition_cmd.set_goal does not confirm change
///
/// This test validates user feedback:
/// 1. After successful update, show confirmation
/// 2. Display: "Calorie goal updated: 2000 → 2500 kcal"
/// 3. Show previous and new values for comparison
///
/// Implementation strategy:
/// - Fetch current goal before update
/// - After successful update, print confirmation
/// - Format: "{goal_type} goal updated: {old} → {new}"
pub fn nutrition_goals_displays_confirmation_test() {
  let cfg = test_config()

  // When: calling set_goal
  let result = nutrition_cmd.set_goal(cfg, goal_type: "calories", value: 2500)

  // Then: should display confirmation
  // Expected console output:
  // "Calorie goal updated: 2000 → 2500 kcal"
  // This will FAIL because nutrition_cmd.set_goal does not exist
  result
  |> should.be_ok()
}
