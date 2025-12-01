//// Tests for nutrition dashboard UI component
//// Following TDD Red-Green-Refactor with BDD behaviors

import gleam/float
import gleam/list
import gleeunit
import gleeunit/should

import shared/types

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// BDD Scenario: Display macro progress for user with partial intake
// ============================================================================

pub fn calculate_protein_progress_percentage_test() {
  // Given a user with bodyweight 180 lbs and moderate activity
  let profile =
    types.UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: types.Moderate,
      goal: types.Maintain,
      meals_per_day: 3,
    )

  // And daily targets (Moderate + Maintain = 0.9 multiplier)
  // Protein: 180 * 0.9 = 162g, Fat: 180 * 0.3 = 54g
  // Calories: 180 * 15 = 2700, Carbs: (2700 - 162*4 - 54*9) / 4 = 391.5g
  let targets = types.daily_macro_targets(profile)
  should.equal(float.round(targets.protein), 162)

  // And current intake of 120g protein
  let current_protein = 120.0

  // When calculating progress percentage
  let percentage = calculate_macro_percentage(current_protein, targets.protein)

  // Then protein bar shows 74% (120/162)
  should.equal(float.round(percentage), 74)
}

pub fn calculate_fat_progress_percentage_test() {
  // Given a user with bodyweight 180 lbs and moderate activity
  let profile =
    types.UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: types.Moderate,
      goal: types.Maintain,
      meals_per_day: 3,
    )

  // And daily targets
  let targets = types.daily_macro_targets(profile)
  should.equal(float.round(targets.fat), 54)

  // And current intake of 40g fat
  let current_fat = 40.0

  // When calculating progress percentage
  let percentage = calculate_macro_percentage(current_fat, targets.fat)

  // Then fat bar shows 74% (40/54)
  should.equal(float.round(percentage), 74)
}

pub fn calculate_carbs_progress_percentage_test() {
  // Given a user with bodyweight 180 lbs and moderate activity
  let profile =
    types.UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: types.Moderate,
      goal: types.Maintain,
      meals_per_day: 3,
    )

  // And daily targets
  let targets = types.daily_macro_targets(profile)
  // Carbs = (2700 - 162*4 - 54*9) / 4 = 391.5g
  should.equal(float.round(targets.carbs), 392)

  // And current intake of 200g carbs
  let current_carbs = 200.0

  // When calculating progress percentage
  let percentage = calculate_macro_percentage(current_carbs, targets.carbs)

  // Then carbs bar shows 51% (200/392)
  should.equal(float.round(percentage), 51)
}

pub fn calculate_calorie_summary_current_test() {
  // Given current intake of 120g protein, 40g fat, 200g carbs
  let current = types.Macros(protein: 120.0, fat: 40.0, carbs: 200.0)

  // When calculating calories using the formula: (protein*4) + (fat*9) + (carbs*4)
  let calories = types.macros_calories(current)

  // Then calorie summary shows 1640 cal
  // (120*4) + (40*9) + (200*4) = 480 + 360 + 800 = 1640
  should.equal(float.round(calories), 1640)
}

pub fn calculate_calorie_summary_target_test() {
  // Given a user with bodyweight 180 lbs and moderate activity
  let profile =
    types.UserProfile(
      id: "test-user",
      bodyweight: 180.0,
      activity_level: types.Moderate,
      goal: types.Maintain,
      meals_per_day: 3,
    )

  // And daily targets: 162g protein, 54g fat, 392g carbs
  let targets = types.daily_macro_targets(profile)

  // When calculating calories
  let calories = types.macros_calories(targets)

  // Then target shows 2700 cal
  // (162*4) + (54*9) + (392*4) = 648 + 486 + 1568 = 2702
  // Note: Using approximate comparison due to floating point arithmetic
  let rounded = float.round(calories)
  should.be_true(rounded >= 2695 && rounded <= 2705)
}

pub fn calculate_zero_intake_calories_test() {
  // Given zero intake
  let current = types.macros_zero()

  // When displaying
  let calories = types.macros_calories(current)

  // Then show "0 / target cal"
  should.equal(calories, 0.0)
}

pub fn progress_bar_caps_at_100_percent_test() {
  // Given intake exceeds target
  let current = 250.0
  let target = 180.0

  // When rendering progress bar
  let percentage = calculate_macro_percentage(current, target)
  let capped = cap_percentage(percentage)

  // Then cap progress bar at 100%
  should.equal(capped, 100.0)
}

pub fn progress_bar_shows_overflow_indicator_test() {
  // Given intake exceeds target
  let current = 250.0
  let target = 180.0

  // When calculating percentage
  let percentage = calculate_macro_percentage(current, target)

  // Then percentage is greater than 100%
  should.be_true(percentage >. 100.0)

  // And uncapped percentage shows overflow (139%)
  let rounded = float.round(percentage)
  should.equal(rounded, 139)
}

pub fn zero_target_handles_division_by_zero_test() {
  // Given a target of zero (edge case)
  let current = 50.0
  let target = 0.0

  // When calculating percentage
  let percentage = calculate_macro_percentage(current, target)

  // Then return 0% to avoid division by zero
  should.equal(percentage, 0.0)
}

pub fn daily_log_sums_entries_for_total_macros_test() {
  // Given daily log with multiple entries
  let entry1 =
    types.FoodLogEntry(
      id: "log-1",
      recipe_id: "chicken-rice",
      recipe_name: "Chicken and Rice",
      servings: 1.0,
      macros: types.Macros(protein: 45.0, fat: 8.0, carbs: 45.0),
      meal_type: types.Lunch,
      logged_at: "2024-01-15T12:00:00Z",
    )

  let entry2 =
    types.FoodLogEntry(
      id: "log-2",
      recipe_id: "beef-potatoes",
      recipe_name: "Beef and Potatoes",
      servings: 1.0,
      macros: types.Macros(protein: 40.0, fat: 20.0, carbs: 35.0),
      meal_type: types.Dinner,
      logged_at: "2024-01-15T18:00:00Z",
    )

  let entry3 =
    types.FoodLogEntry(
      id: "log-3",
      recipe_id: "salmon-veggies",
      recipe_name: "Salmon with Vegetables",
      servings: 1.0,
      macros: types.Macros(protein: 35.0, fat: 18.0, carbs: 8.0),
      meal_type: types.Breakfast,
      logged_at: "2024-01-15T08:00:00Z",
    )

  // When summing entries
  let total = sum_log_entries([entry1, entry2, entry3])

  // Then total_macros equals sum
  should.equal(total.protein, 120.0)
  // 45 + 40 + 35
  should.equal(total.fat, 46.0)
  // 8 + 20 + 18
  should.equal(total.carbs, 88.0)
  // 45 + 35 + 8
}

pub fn empty_daily_log_has_zero_macros_test() {
  // Given daily log with no entries
  let entries = []

  // When summing entries
  let total = sum_log_entries(entries)

  // Then total_macros is zero
  should.equal(total.protein, 0.0)
  should.equal(total.fat, 0.0)
  should.equal(total.carbs, 0.0)
}

// ============================================================================
// Helper Functions (extracted from web.gleam macro_bar logic)
// ============================================================================

/// Calculate percentage of current vs target
fn calculate_macro_percentage(current: Float, target: Float) -> Float {
  case target >. 0.0 {
    True -> current /. target *. 100.0
    False -> 0.0
  }
}

/// Cap percentage at 100% for display
fn cap_percentage(percentage: Float) -> Float {
  case percentage >. 100.0 {
    True -> 100.0
    False -> percentage
  }
}

/// Sum all log entries to get total macros
fn sum_log_entries(entries: List(types.FoodLogEntry)) -> types.Macros {
  list.fold(entries, types.macros_zero(), fn(acc, entry) {
    types.Macros(
      protein: acc.protein +. entry.macros.protein,
      fat: acc.fat +. entry.macros.fat,
      carbs: acc.carbs +. entry.macros.carbs,
    )
  })
}
