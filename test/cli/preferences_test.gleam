//// TDD Tests for CLI preferences command
////
//// RED PHASE: This test validates:
//// 1. Nutrition goals formatting
//// 2. Activity level and goal formatting
//// 3. Preferences display functions

import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/preferences
import meal_planner/ncp.{NutritionGoals}
import meal_planner/types.{Active, Gain, Lose, Maintain, Moderate, Sedentary}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Create sample nutrition goals
fn create_sample_goals(
  calories: Float,
  protein: Float,
  carbs: Float,
  fat: Float,
) -> NutritionGoals {
  NutritionGoals(
    daily_calories: calories,
    daily_protein: protein,
    daily_carbs: carbs,
    daily_fat: fat,
  )
}

// ============================================================================
// Nutrition Goals Formatting Tests
// ============================================================================

/// Test: format_nutrition_goals includes all macro values
pub fn format_nutrition_goals_includes_all_macros_test() {
  let goals = create_sample_goals(2000.0, 150.0, 200.0, 65.0)
  let output = preferences.format_nutrition_goals(goals)

  string.contains(output, "Nutrition Goals")
  |> should.be_true()

  string.contains(output, "2000")
  |> should.be_true()

  string.contains(output, "150")
  |> should.be_true()

  string.contains(output, "200")
  |> should.be_true()

  string.contains(output, "65")
  |> should.be_true()
}

/// Test: format_nutrition_goals includes labels
pub fn format_nutrition_goals_includes_labels_test() {
  let goals = create_sample_goals(2200.0, 165.0, 220.0, 73.0)
  let output = preferences.format_nutrition_goals(goals)

  string.contains(output, "Daily Calories")
  |> should.be_true()

  string.contains(output, "Daily Protein")
  |> should.be_true()

  string.contains(output, "Daily Carbs")
  |> should.be_true()

  string.contains(output, "Daily Fat")
  |> should.be_true()
}

/// Test: format_nutrition_goals includes units
pub fn format_nutrition_goals_includes_units_test() {
  let goals = create_sample_goals(1800.0, 120.0, 180.0, 60.0)
  let output = preferences.format_nutrition_goals(goals)

  string.contains(output, "kcal")
  |> should.be_true()

  // Protein, carbs, and fat are in grams
  let lines = string.split(output, "\n")
  list.length(lines)
  |> should.be_greater_than(3)
}

// ============================================================================
// Activity Level Formatting Tests
// ============================================================================

/// Test: format_activity_level formats Sedentary correctly
pub fn format_activity_level_sedentary_test() {
  let output = preferences.format_activity_level(Sedentary)

  string.contains(output, "Sedentary")
  |> should.be_true()
}

/// Test: format_activity_level formats Moderate correctly
pub fn format_activity_level_moderate_test() {
  let output = preferences.format_activity_level(Moderate)

  string.contains(output, "Moderate")
  |> should.be_true()
}

/// Test: format_activity_level formats Active correctly
pub fn format_activity_level_active_test() {
  let output = preferences.format_activity_level(Active)

  string.contains(output, "Active")
  |> should.be_true()
}

// ============================================================================
// Goal Formatting Tests
// ============================================================================

/// Test: format_goal formats Lose correctly
pub fn format_goal_lose_test() {
  let output = preferences.format_goal(Lose)

  string.contains(output, "Lose")
  |> should.be_true()

  string.contains(output, "weight")
  |> should.be_true()
}

/// Test: format_goal formats Maintain correctly
pub fn format_goal_maintain_test() {
  let output = preferences.format_goal(Maintain)

  string.contains(output, "Maintain")
  |> should.be_true()
}

/// Test: format_goal formats Gain correctly
pub fn format_goal_gain_test() {
  let output = preferences.format_goal(Gain)

  string.contains(output, "Gain")
  |> should.be_true()

  string.contains(output, "weight")
  |> should.be_true()
}

// ============================================================================
// Preferences Summary Tests
// ============================================================================

/// Test: PreferencesSummary can be created with nutrition goals
pub fn preferences_summary_with_goals_test() {
  let goals = create_sample_goals(2000.0, 150.0, 200.0, 65.0)
  let summary =
    preferences.PreferencesSummary(
      nutrition_goals: Some(goals),
      has_dietary_restrictions: False,
      meals_per_day: Some(3),
      notifications_enabled: True,
    )

  summary.nutrition_goals
  |> should.not_equal(None)

  summary.meals_per_day
  |> should.equal(Some(3))

  summary.notifications_enabled
  |> should.be_true()
}

/// Test: PreferencesSummary can be created without goals
pub fn preferences_summary_without_goals_test() {
  let summary =
    preferences.PreferencesSummary(
      nutrition_goals: None,
      has_dietary_restrictions: True,
      meals_per_day: None,
      notifications_enabled: False,
    )

  summary.nutrition_goals
  |> should.equal(None)

  summary.has_dietary_restrictions
  |> should.be_true()

  summary.notifications_enabled
  |> should.be_false()
}

// ============================================================================
// Floating Point Formatting Tests
// ============================================================================

/// Test: Floating point values are formatted with 1 decimal place
pub fn format_nutrition_goals_float_precision_test() {
  let goals = create_sample_goals(1234.5, 56.7, 142.3, 45.8)
  let output = preferences.format_nutrition_goals(goals)

  // Should contain the float values (may be slightly rounded)
  string.contains(output, "1234.5")
  |> should.be_true()

  string.contains(output, "56.7")
  |> should.be_true()
}
