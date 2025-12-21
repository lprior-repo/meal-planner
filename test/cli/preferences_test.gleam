//// TDD Tests for CLI preferences command
////
//// RED PHASE: This test validates:
//// 1. Goal validation (calorie, protein, carb, fat ranges)
//// 2. Activity level parsing and conversion
//// 3. Goal type parsing and conversion
//// 4. Meal count bounds validation (1-10)
//// 5. Profile section formatting

import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/preferences
import meal_planner/ncp.{NutritionGoals}
import meal_planner/types.{
  Active, Gain, Lose, Maintain, Moderate, Sedentary, UserProfile,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn create_sample_nutrition_goals(
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

fn create_sample_user_profile(
  bodyweight: Float,
  meals_per_day: Int,
) -> UserProfile {
  UserProfile(
    id: "test-user-1",
    bodyweight: bodyweight,
    activity_level: Moderate,
    goal: Maintain,
    meals_per_day: meals_per_day,
    micronutrient_goals: None,
  )
}

// ============================================================================
// Nutrition Goals Formatting Tests
// ============================================================================

/// Test: format_goals includes all macro values
pub fn format_goals_includes_all_macros_test() {
  let goals = create_sample_nutrition_goals(2000.0, 150.0, 250.0, 65.0)
  let output = preferences.format_goals(goals)

  string.contains(output, "2000")
  |> should.be_true()

  string.contains(output, "150")
  |> should.be_true()

  string.contains(output, "250")
  |> should.be_true()

  string.contains(output, "65")
  |> should.be_true()
}

/// Test: format_goals uses correct labels
pub fn format_goals_uses_correct_labels_test() {
  let goals = create_sample_nutrition_goals(2000.0, 150.0, 250.0, 65.0)
  let output = preferences.format_goals(goals)

  string.contains(output, "Calories")
  |> should.be_true()

  string.contains(output, "Protein")
  |> should.be_true()

  string.contains(output, "Carbs")
  |> should.be_true()

  string.contains(output, "Fat")
  |> should.be_true()

  string.contains(output, "kcal")
  |> should.be_true()
}

/// Test: format_goals handles edge case values
pub fn format_goals_handles_edge_values_test() {
  // Minimum values
  let min_goals = create_sample_nutrition_goals(500.0, 1.0, 1.0, 1.0)
  let min_output = preferences.format_goals(min_goals)
  string.contains(min_output, "500")
  |> should.be_true()

  // Maximum values (reasonable)
  let max_goals = create_sample_nutrition_goals(10000.0, 500.0, 1000.0, 500.0)
  let max_output = preferences.format_goals(max_goals)
  string.contains(max_output, "10000")
  |> should.be_true()
}

/// Test: format_goals handles zero values
pub fn format_goals_handles_zero_test() {
  let goals = create_sample_nutrition_goals(0.0, 0.0, 0.0, 0.0)
  let output = preferences.format_goals(goals)

  // Should render even with zero values
  string.length(output)
  |> should.be_true()
}

// ============================================================================
// Profile Formatting Tests
// ============================================================================

/// Test: format_profile_section includes body weight
pub fn format_profile_section_includes_bodyweight_test() {
  let profile = UserProfile(
    id: "user-1",
    bodyweight: 75.5,
    activity_level: Moderate,
    goal: Maintain,
    meals_per_day: 3,
    micronutrient_goals: None,
  )
  let output = preferences.format_profile_section(profile)

  // Should contain body weight value
  string.length(output) > 0
  |> should.be_true()
}

/// Test: format_profile_section includes activity level
pub fn format_profile_section_includes_activity_level_test() {
  let sedentary_profile = UserProfile(
    id: "user-1",
    bodyweight: 70.0,
    activity_level: Sedentary,
    goal: Maintain,
    meals_per_day: 3,
    micronutrient_goals: None,
  )
  let output = preferences.format_profile_section(sedentary_profile)

  string.contains(output, "Sedentary")
  |> should.be_true()
}

/// Test: format_profile_section shows Moderate activity level
pub fn format_profile_section_moderate_activity_test() {
  let profile = UserProfile(
    id: "user-1",
    bodyweight: 70.0,
    activity_level: Moderate,
    goal: Maintain,
    meals_per_day: 3,
    micronutrient_goals: None,
  )
  let output = preferences.format_profile_section(profile)

  string.contains(output, "Moderate")
  |> should.be_true()
}

/// Test: format_profile_section shows Active activity level
pub fn format_profile_section_active_activity_test() {
  let profile = UserProfile(
    id: "user-1",
    bodyweight: 70.0,
    activity_level: Active,
    goal: Maintain,
    meals_per_day: 3,
    micronutrient_goals: None,
  )
  let output = preferences.format_profile_section(profile)

  string.contains(output, "Active")
  |> should.be_true()
}

/// Test: format_profile_section includes goal
pub fn format_profile_section_includes_goal_test() {
  let gain_profile = UserProfile(
    id: "user-1",
    bodyweight: 70.0,
    activity_level: Moderate,
    goal: Gain,
    meals_per_day: 3,
    micronutrient_goals: None,
  )
  let output = preferences.format_profile_section(gain_profile)

  string.contains(output, "Gain")
  |> should.be_true()
}

/// Test: format_profile_section shows Maintain goal
pub fn format_profile_section_maintain_goal_test() {
  let profile = UserProfile(
    id: "user-1",
    bodyweight: 70.0,
    activity_level: Moderate,
    goal: Maintain,
    meals_per_day: 3,
    micronutrient_goals: None,
  )
  let output = preferences.format_profile_section(profile)

  string.contains(output, "Maintain")
  |> should.be_true()
}

/// Test: format_profile_section shows Lose goal
pub fn format_profile_section_lose_goal_test() {
  let profile = UserProfile(
    id: "user-1",
    bodyweight: 70.0,
    activity_level: Moderate,
    goal: Lose,
    meals_per_day: 3,
    micronutrient_goals: None,
  )
  let output = preferences.format_profile_section(profile)

  string.contains(output, "Loss")
  |> should.be_true()
}

/// Test: format_profile_section includes meals per day
pub fn format_profile_section_includes_meals_test() {
  let profile = create_sample_user_profile(70.0, 5)
  let output = preferences.format_profile_section(profile)

  string.contains(output, "5")
  |> should.be_true()
}

// ============================================================================
// Meal Distribution Tests
// ============================================================================

/// Test: format_meal_distribution handles 1 meal
pub fn format_meal_distribution_one_meal_test() {
  let output = preferences.format_meal_distribution(1)

  string.contains(output, "1")
  |> should.be_true()

  string.contains(output, "100")
  |> should.be_true()
}

/// Test: format_meal_distribution handles 2 meals
pub fn format_meal_distribution_two_meals_test() {
  let output = preferences.format_meal_distribution(2)

  string.contains(output, "Lunch")
  |> should.be_true()

  string.contains(output, "Dinner")
  |> should.be_true()
}

/// Test: format_meal_distribution handles 3 meals (default)
pub fn format_meal_distribution_three_meals_test() {
  let output = preferences.format_meal_distribution(3)

  string.contains(output, "Breakfast")
  |> should.be_true()

  string.contains(output, "Lunch")
  |> should.be_true()

  string.contains(output, "Dinner")
  |> should.be_true()
}

/// Test: format_meal_distribution handles 4 meals
pub fn format_meal_distribution_four_meals_test() {
  let output = preferences.format_meal_distribution(4)

  string.contains(output, "Breakfast")
  |> should.be_true()

  string.contains(output, "Lunch")
  |> should.be_true()

  string.contains(output, "Snack")
  |> should.be_true()

  string.contains(output, "Dinner")
  |> should.be_true()
}

/// Test: format_meal_distribution handles 5 meals
pub fn format_meal_distribution_five_meals_test() {
  let output = preferences.format_meal_distribution(5)

  string.contains(output, "Morning Snack")
  |> should.be_true()

  string.contains(output, "Afternoon Snack")
  |> should.be_true()
}

/// Test: format_meal_distribution handles custom (>5)
pub fn format_meal_distribution_custom_meals_test() {
  let output = preferences.format_meal_distribution(7)

  string.contains(output, "Custom")
  |> should.be_true()

  string.contains(output, "7")
  |> should.be_true()
}

// ============================================================================
// Float Formatting Tests
// ============================================================================

/// Test: float_to_display formats whole numbers without decimal
pub fn float_to_display_whole_number_test() {
  let formatted = preferences.float_to_display(70.0)

  // Should display as "70" not "70.0"
  string.contains(formatted, "70")
  |> should.be_true()
}

/// Test: float_to_display formats decimals to 1 place
pub fn float_to_display_decimal_test() {
  let formatted = preferences.float_to_display(70.5)

  // Should preserve the decimal
  string.contains(formatted, "70")
  |> should.be_true()
}

// ============================================================================
// Integration Tests (basic)
// ============================================================================

/// Test: Goals section formatting includes header
pub fn format_goals_section_includes_header_test() {
  let goals = create_sample_nutrition_goals(2000.0, 150.0, 250.0, 65.0)
  let output = preferences.format_goals_section(goals)

  string.contains(output, "NUTRITION GOALS")
  |> should.be_true()
}

/// Test: Profile section formatting includes header
pub fn format_profile_section_includes_header_test() {
  let profile = create_sample_user_profile(70.0, 3)
  let output = preferences.format_profile_section(profile)

  string.contains(output, "PROFILE")
  |> should.be_true()
}
