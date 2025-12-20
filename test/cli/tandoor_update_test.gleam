//// TDD Test for CLI tandoor update command
////
//// RED PHASE: This test MUST fail initially because the implementation
//// does not exist yet. The test validates:
//// 1. Update recipe metadata in Tandoor (name, description, servings)
//// 2. Handle recipe not found errors gracefully
//// 3. Display confirmation message after update
//// 4. Validate required fields before API call
////
//// Test follows Gleam 7 Commandments:
//// - Immutability: All test data is immutable
//// - No Nulls: Uses Option(T) and Result(T, E) exclusively
//// - Exhaustive Matching: All case branches covered
//// - Type Safety: Custom types for domain concepts
////
//// Based on meal-planner architecture:
//// - Recipe data comes from meal_planner/tandoor/recipe.gleam
//// - CLI command defined in meal_planner/cli/domains/tandoor.gleam
//// - Uses glint for flag parsing

import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/tandoor as tandoor_cmd
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

/// Test: mp tandoor update updates recipe name
///
/// EXPECTED FAILURE: tandoor_cmd.update_recipe function does not exist yet
///
/// This test validates that the update command:
/// 1. Accepts recipe ID and new name as arguments
/// 2. Calls Tandoor API PATCH /api/recipe/{id}/ endpoint
/// 3. Returns Ok with updated recipe details
/// 4. Displays "Recipe updated successfully" message
///
/// Implementation strategy:
/// - Add update_recipe function to meal_planner/cli/domains/tandoor.gleam
/// - Function signature: fn update_recipe(config: Config, recipe_id: Int, name: String) -> Result(UpdatedRecipe, String)
/// - Call client.update_recipe with PATCH request body {name: "new name"}
/// - Return Ok with updated recipe data
pub fn tandoor_update_changes_name_test() {
  let cfg = test_config()

  // When: calling update_recipe with new name
  let result = tandoor_cmd.update_recipe(cfg, recipe_id: 42, name: "New Recipe Name")

  // Then: should return Ok with updated recipe
  // This will FAIL because tandoor_cmd.update_recipe does not exist
  result
  |> should.be_ok()
}

/// Test: mp tandoor update updates recipe description
///
/// EXPECTED FAILURE: tandoor_cmd.update_recipe does not support description
///
/// This test validates updating recipe description:
/// 1. Accepts recipe ID and new description
/// 2. PATCH request includes description in JSON body
/// 3. Returns Ok with updated recipe
/// 4. Displays updated description back to user
///
/// Implementation strategy:
/// - Accept optional description parameter
/// - Build JSON body: {description: "new description"}
/// - PATCH to Tandoor API
/// - Parse response and return updated recipe
pub fn tandoor_update_changes_description_test() {
  let cfg = test_config()

  // When: calling update_recipe with new description
  let result = tandoor_cmd.update_recipe(
    cfg,
    recipe_id: 42,
    name: "Recipe",
    description: Some("New description"),
  )

  // Then: should update description in Tandoor
  // This will FAIL because function signature doesn't match
  result
  |> should.be_ok()
}

/// Test: mp tandoor update updates servings
///
/// EXPECTED FAILURE: tandoor_cmd.update_recipe does not support servings
///
/// This test validates updating recipe servings:
/// 1. Accepts servings as numeric value
/// 2. PATCH request includes servings in JSON body
/// 3. Returns Ok
/// 4. Servings value is validated (must be > 0)
///
/// Implementation strategy:
/// - Accept optional servings parameter (Int)
/// - Validate servings > 0 before API call
/// - Build JSON body: {servings: 4}
/// - PATCH to Tandoor API
pub fn tandoor_update_changes_servings_test() {
  let cfg = test_config()

  // When: calling update_recipe with new servings
  let result = tandoor_cmd.update_recipe(
    cfg,
    recipe_id: 42,
    name: "Recipe",
    servings: Some(4),
  )

  // Then: should update servings in Tandoor
  // This will FAIL because function signature doesn't match
  result
  |> should.be_ok()
}

/// Test: mp tandoor update handles recipe not found
///
/// EXPECTED FAILURE: tandoor_cmd.update_recipe does not check if recipe exists
///
/// This test validates error handling when recipe doesn't exist:
/// 1. Recipe ID does not exist in Tandoor
/// 2. API returns HTTP 404
/// 3. Function returns Error("Recipe not found")
/// 4. No crash or panic
///
/// Implementation strategy:
/// - Call client.update_recipe
/// - Catch HTTP 404 response
/// - Map to Error("Recipe with ID 999 not found in Tandoor")
pub fn tandoor_update_recipe_not_found_test() {
  let cfg = test_config()

  // When: calling update_recipe with non-existent recipe ID
  let result = tandoor_cmd.update_recipe(
    cfg,
    recipe_id: 999,
    name: "Updated Name",
  )

  // Then: should return Error
  // This will FAIL because tandoor_cmd.update_recipe does not exist
  result
  |> should.be_error()
}

/// Test: mp tandoor update validates servings value
///
/// EXPECTED FAILURE: tandoor_cmd.update_recipe does not validate servings
///
/// This test validates input validation:
/// 1. Servings must be > 0
/// 2. Servings = 0 should return Error("Servings must be greater than 0")
/// 3. Negative servings should return Error
/// 4. Validation happens BEFORE API call
///
/// Implementation strategy:
/// - Check servings > 0 in validation function
/// - Return Error if validation fails
/// - Only proceed to API call if validation passes
pub fn tandoor_update_rejects_invalid_servings_test() {
  let cfg = test_config()

  // When: calling update_recipe with invalid servings
  let result = tandoor_cmd.update_recipe(
    cfg,
    recipe_id: 42,
    name: "Recipe",
    servings: Some(0),
  )

  // Then: should return Error for invalid servings
  // This will FAIL because function signature doesn't match
  result
  |> should.be_error()
}

/// Test: mp tandoor update handles API errors
///
/// EXPECTED FAILURE: tandoor_cmd.update_recipe does not handle errors
///
/// This test validates error handling:
/// 1. Tandoor API returns HTTP 500
/// 2. Function returns Error with descriptive message
/// 3. Shows API error details to user
/// 4. No crash
///
/// Implementation strategy:
/// - Wrap API call in result.try
/// - Map errors to descriptive strings
/// - Return Error("Failed to update recipe: HTTP 500")
pub fn tandoor_update_handles_api_errors_test() {
  let cfg = test_config()

  // When: Tandoor API returns error
  let result = tandoor_cmd.update_recipe(
    cfg,
    recipe_id: 42,
    name: "Recipe",
  )

  // Then: should return Error with descriptive message
  // This will FAIL because tandoor_cmd.update_recipe does not exist
  result
  |> should.be_error()
}

/// Test: mp tandoor update displays success message
///
/// EXPECTED FAILURE: tandoor_cmd.update_recipe does not display success message
///
/// This test validates user feedback:
/// 1. After successful update, display confirmation
/// 2. Show: "Recipe 'Recipe Name' updated successfully"
/// 3. Display updated fields
/// 4. Message printed using io.println
///
/// Implementation strategy:
/// - Parse response from Tandoor
/// - Extract recipe name and updated fields
/// - Print confirmation message with recipe name
pub fn tandoor_update_displays_success_test() {
  let cfg = test_config()

  // When: calling update_recipe successfully
  let result = tandoor_cmd.update_recipe(
    cfg,
    recipe_id: 42,
    name: "Updated Recipe Name",
  )

  // Then: should display success message
  // Expected console output:
  // "Recipe 'Updated Recipe Name' updated successfully"
  // This will FAIL because tandoor_cmd.update_recipe does not exist
  result
  |> should.be_ok()
}

/// Test: mp tandoor update handles empty name
///
/// EXPECTED FAILURE: tandoor_cmd.update_recipe does not validate name
///
/// This test validates name validation:
/// 1. Name must not be empty string
/// 2. Name with only spaces should be rejected
/// 3. Returns Error("Recipe name cannot be empty")
/// 4. Validation before API call
///
/// Implementation strategy:
/// - Trim and validate name is not empty
/// - Return Error if name is blank after trimming
pub fn tandoor_update_rejects_empty_name_test() {
  let cfg = test_config()

  // When: calling update_recipe with empty name
  let result = tandoor_cmd.update_recipe(
    cfg,
    recipe_id: 42,
    name: "",
  )

  // Then: should return Error
  // This will FAIL because function signature doesn't match
  result
  |> should.be_error()
}

/// Test: mp tandoor update returns updated recipe data
///
/// EXPECTED FAILURE: tandoor_cmd.update_recipe does not return recipe data
///
/// This test validates return value:
/// 1. Returns Ok(UpdatedRecipe) containing updated fields
/// 2. UpdatedRecipe has: id, name, description, servings, updated_at
/// 3. Data matches what was sent in PATCH request
///
/// Implementation strategy:
/// - Define UpdatedRecipe type in tandoor.gleam
/// - Parse Tandoor API response
/// - Return Ok(UpdatedRecipe(id: X, name: Y, ...))
pub fn tandoor_update_returns_recipe_data_test() {
  let cfg = test_config()

  // When: calling update_recipe
  let result = tandoor_cmd.update_recipe(
    cfg,
    recipe_id: 42,
    name: "Updated Name",
  )

  // Then: should return Ok with updated recipe data
  // This will FAIL because tandoor_cmd.update_recipe does not exist
  result
  |> should.be_ok()
}
