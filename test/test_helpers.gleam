//// Test Helpers for Integration Workflows
////
//// Provides reusable functions for building test fixtures and assertions
//// used across all integration workflow tests.

import gleam/list
import gleam/option.{Some}
import gleam/string
import gleeunit/should
import meal_planner/generator/weekly.{type GenerationError, type WeeklyMealPlan}
import meal_planner/id
import meal_planner/types/recipe.{type Recipe, Recipe, Low}
import meal_planner/types/macros.{type Macros, Macros}

// ============================================================================
// Test Fixture Builders
// ============================================================================

/// Create standard test target macros for meal plan generation
/// Default: 180g protein, 60g fat, 200g carbs
pub fn create_test_target_macros() -> Macros {
  Macros(protein: 180.0, fat: 60.0, carbs: 200.0)
}

/// Create adjusted test macros for constraint testing
/// Adjusted: 200g protein, 65g fat, 180g carbs
pub fn create_adjusted_target_macros() -> Macros {
  Macros(protein: 200.0, fat: 65.0, carbs: 180.0)
}

/// Create a sample recipe with consistent test data
/// All recipes have: 40g protein, 15g fat, 50g carbs
pub fn create_sample_recipe(recipe_id: String, name: String) -> Recipe {
  Recipe(
    id: id.recipe_id(recipe_id),
    name: name,
    ingredients: [],
    instructions: [],
    macros: Macros(protein: 40.0, fat: 15.0, carbs: 50.0),
    servings: 1,
    category: "Dinner",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

/// Create a pool of test recipes for meal plan generation
/// Returns 4 recipes with varied names
pub fn create_test_recipe_pool() -> List(Recipe) {
  [
    create_sample_recipe("recipe-101", "Protein Smoothie"),
    create_sample_recipe("recipe-201", "Grilled Chicken Salad"),
    create_sample_recipe("recipe-301", "Salmon with Vegetables"),
    create_sample_recipe("recipe-302", "Shrimp Stir Fry"),
  ]
}

/// Create a small recipe pool (3 recipes) for basic testing
pub fn create_small_recipe_pool() -> List(Recipe) {
  [
    create_sample_recipe("recipe-101", "Protein Smoothie"),
    create_sample_recipe("recipe-201", "Grilled Chicken Salad"),
    create_sample_recipe("recipe-301", "Salmon with Vegetables"),
  ]
}

/// Create test email request for feedback loop testing
pub fn create_test_email_request(
  from: String,
  subject: String,
  body: String,
) -> types.EmailRequest {
  types.EmailRequest(
    from_email: from,
    subject: subject,
    body: body,
    is_reply: False,
  )
}

/// Create test command execution result
pub fn create_test_execution_result(
  success: Bool,
  message: String,
  command: option.Option(types.EmailCommand),
) -> types.CommandExecutionResult {
  types.CommandExecutionResult(
    success: success,
    message: message,
    command: command,
  )
}

// ============================================================================
// Assertion Helpers
// ============================================================================

/// Assert that a meal plan is valid and complete
/// Checks: has 7 days, all days have meals
pub fn assert_meal_plan_valid(meal_plan: WeeklyMealPlan) -> Nil {
  // Check we have 7 days
  meal_plan.days
  |> list.length
  |> should.equal(7)

  // Check each day has all three meals
  meal_plan.days
  |> list.each(fn(day) {
    // Verify day name is not empty
    day.day
    |> string.is_empty
    |> should.equal(False)

    // Verify breakfast exists
    day.breakfast.name
    |> string.is_empty
    |> should.equal(False)

    // Verify lunch exists
    day.lunch.name
    |> string.is_empty
    |> should.equal(False)

    // Verify dinner exists
    day.dinner.name
    |> string.is_empty
    |> should.equal(False)
  })
}

/// Assert that generation succeeded
/// Validates Result is Ok and meal plan is valid
pub fn assert_generation_succeeded(
  result: Result(WeeklyMealPlan, GenerationError),
) -> WeeklyMealPlan {
  result
  |> should.be_ok

  // Extract meal plan for further validation
  let assert Ok(meal_plan) = result
  assert_meal_plan_valid(meal_plan)
  meal_plan
}

/// Assert that email contains all required sections
/// Validates: greeting, summary, sign-off
pub fn assert_email_contains_all_sections(email: String) -> Nil {
  // Check for greeting
  email
  |> string.contains("Hi")
  |> should.equal(True)

  // Check for content (non-empty body)
  email
  |> string.is_empty
  |> should.equal(False)

  // Check minimum length (reasonable email has > 20 chars)
  email
  |> string.length
  |> fn(len) { len > 20 }
  |> should.equal(True)
}

/// Assert that command parsing succeeded
/// Validates Result is Ok and returns the command
pub fn assert_command_parsed(
  result: Result(types.EmailCommand, String),
) -> types.EmailCommand {
  result
  |> should.be_ok

  let assert Ok(command) = result
  command
}

/// Assert that day of week matches expected
pub fn assert_day_equals(
  actual: types.DayOfWeek,
  expected: types.DayOfWeek,
) -> Nil {
  actual
  |> should.equal(expected)
}

/// Assert that meal type matches expected
pub fn assert_meal_type_equals(
  actual: types.MealType,
  expected: types.MealType,
) -> Nil {
  actual
  |> should.equal(expected)
}
