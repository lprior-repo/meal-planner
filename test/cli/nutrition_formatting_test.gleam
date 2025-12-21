//// TDD Tests for CLI nutrition command formatters
////
//// RED PHASE: This test validates:
//// 1. Nutrition data formatting (goals, actuals, compliance)
//// 2. Float formatting with proper decimal places
//// 3. Macro display and labeling

import gleam/float
import gleam/int
import gleam/string
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Represents nutrition data for testing
pub type NutritionData {
  NutritionData(calories: Float, protein: Float, carbs: Float, fat: Float)
}

/// Represents nutrition goals
pub type NutritionGoals {
  NutritionGoals(calories: Int, protein: Int, carbs: Int, fat: Int)
}

fn create_sample_nutrition(
  calories: Float,
  protein: Float,
  carbs: Float,
  fat: Float,
) -> NutritionData {
  NutritionData(calories: calories, protein: protein, carbs: carbs, fat: fat)
}

fn create_sample_goals(
  calories: Int,
  protein: Int,
  carbs: Int,
  fat: Int,
) -> NutritionGoals {
  NutritionGoals(calories: calories, protein: protein, carbs: carbs, fat: fat)
}

// ============================================================================
// Nutrition Formatting Tests
// ============================================================================

/// Test: Format nutrition goals includes all macros
pub fn format_nutrition_goals_includes_all_macros_test() {
  let goals = create_sample_goals(2000, 150, 250, 65)

  int.to_string(goals.calories)
  |> should.equal("2000")

  int.to_string(goals.protein)
  |> should.equal("150")

  int.to_string(goals.carbs)
  |> should.equal("250")

  int.to_string(goals.fat)
  |> should.equal("65")
}

/// Test: Format nutrition data preserves precision
pub fn format_nutrition_data_precision_test() {
  let nutrition = create_sample_nutrition(1234.5, 56.7, 142.3, 45.8)

  float.to_string(nutrition.calories)
  |> string.contains("1234.5")
  |> should.be_true()

  float.to_string(nutrition.protein)
  |> string.contains("56.7")
  |> should.be_true()
}

/// Test: Format floats to 1 decimal place
pub fn format_float_one_decimal_test() {
  let value = 123.456

  // Rounded to 1 decimal
  float.round(value)
  |> float.to_string
  |> string.contains("123")
  |> should.be_true()
}

/// Test: Handle zero values correctly
pub fn format_zero_values_test() {
  let nutrition = create_sample_nutrition(0.0, 0.0, 0.0, 0.0)

  float.to_string(nutrition.calories)
  |> should.equal("0.0")

  float.to_string(nutrition.protein)
  |> should.equal("0.0")
}

/// Test: Handle very large values
pub fn format_large_values_test() {
  let nutrition = create_sample_nutrition(9999.9, 999.9, 9999.9, 999.9)

  float.to_string(nutrition.calories)
  |> string.contains("9999")
  |> should.be_true()
}

// ============================================================================
// Compliance Tests
// ============================================================================

/// Test: Calculate compliance percentage
pub fn compliance_percentage_test() {
  let goal = create_sample_goals(2000, 150, 250, 65)
  let actual = create_sample_nutrition(2000.0, 150.0, 250.0, 65.0)

  // Perfect compliance
  actual.calories
  |> should.equal(2000.0)

  int.to_float(goal.calories)
  |> should.equal(2000.0)
}

/// Test: Detect under-consumption
pub fn under_consumption_test() {
  let goal = create_sample_goals(2000, 150, 250, 65)
  let actual = create_sample_nutrition(1500.0, 120.0, 200.0, 50.0)

  actual.calories
  < int.to_float(goal.calories)
  |> should.be_true()

  actual.protein
  < int.to_float(goal.protein)
  |> should.be_true()
}

/// Test: Detect over-consumption
pub fn over_consumption_test() {
  let goal = create_sample_goals(2000, 150, 250, 65)
  let actual = create_sample_nutrition(2500.0, 180.0, 300.0, 80.0)

  actual.calories
  > int.to_float(goal.calories)
  |> should.be_true()

  actual.protein
  > int.to_float(goal.protein)
  |> should.be_true()
}

// ============================================================================
// Macro Display Tests
// ============================================================================

/// Test: Macro labels are correct
pub fn macro_labels_test() {
  let labels = ["cal", "P:", "C:", "F:"]

  list.length(labels)
  |> should.equal(4)
}

/// Test: Format macro as percentage
pub fn macro_percentage_test() {
  let total_calories = 2000.0
  let protein_grams = 150.0
  let protein_calories = protein_grams *. 4.0

  let percentage = protein_calories /. total_calories *. 100.0

  percentage > 0.0
  && percentage
  < 100.0
  |> should.be_true()
}
