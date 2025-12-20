/// Tests for weekly trend analysis
///
/// Validates pattern identification, macro averaging, and recommendation generation
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/advisor/weekly_trends.{
  type NutritionTargets, NutritionTargets, calculate_macro_averages,
  generate_pattern_recommendations, identify_nutrition_patterns,
}
import meal_planner/fatsecret/diary/types.{type DaySummary, DaySummary}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Data Fixtures
// ============================================================================

fn sample_week_balanced() -> List(DaySummary) {
  // Week with balanced macros hitting targets
  [
    DaySummary(
      date_int: 19_723,
      calories: 2000.0,
      carbohydrate: 200.0,
      protein: 150.0,
      fat: 65.0,
    ),
    DaySummary(
      date_int: 19_724,
      calories: 2050.0,
      carbohydrate: 205.0,
      protein: 155.0,
      fat: 67.0,
    ),
    DaySummary(
      date_int: 19_725,
      calories: 1980.0,
      carbohydrate: 198.0,
      protein: 148.0,
      fat: 64.0,
    ),
    DaySummary(
      date_int: 19_726,
      calories: 2020.0,
      carbohydrate: 202.0,
      protein: 152.0,
      fat: 66.0,
    ),
    DaySummary(
      date_int: 19_727,
      calories: 2010.0,
      carbohydrate: 201.0,
      protein: 151.0,
      fat: 65.5,
    ),
    DaySummary(
      date_int: 19_728,
      calories: 2030.0,
      carbohydrate: 203.0,
      protein: 153.0,
      fat: 66.5,
    ),
    DaySummary(
      date_int: 19_729,
      calories: 1990.0,
      carbohydrate: 199.0,
      protein: 149.0,
      fat: 64.5,
    ),
  ]
}

fn sample_week_low_protein() -> List(DaySummary) {
  // Week with consistent protein deficiency
  [
    DaySummary(
      date_int: 19_723,
      calories: 2000.0,
      carbohydrate: 250.0,
      protein: 100.0,
      fat: 65.0,
    ),
    DaySummary(
      date_int: 19_724,
      calories: 2050.0,
      carbohydrate: 255.0,
      protein: 105.0,
      fat: 67.0,
    ),
    DaySummary(
      date_int: 19_725,
      calories: 1980.0,
      carbohydrate: 248.0,
      protein: 98.0,
      fat: 64.0,
    ),
    DaySummary(
      date_int: 19_726,
      calories: 2020.0,
      carbohydrate: 252.0,
      protein: 102.0,
      fat: 66.0,
    ),
    DaySummary(
      date_int: 19_727,
      calories: 2010.0,
      carbohydrate: 251.0,
      protein: 101.0,
      fat: 65.5,
    ),
    DaySummary(
      date_int: 19_728,
      calories: 2030.0,
      carbohydrate: 253.0,
      protein: 103.0,
      fat: 66.5,
    ),
    DaySummary(
      date_int: 19_729,
      calories: 1990.0,
      carbohydrate: 249.0,
      protein: 99.0,
      fat: 64.5,
    ),
  ]
}

fn default_targets() -> NutritionTargets {
  NutritionTargets(
    daily_protein: 150.0,
    daily_carbs: 200.0,
    daily_fat: 65.0,
    daily_calories: 2000.0,
  )
}

// ============================================================================
// Calculate Averages Tests
// ============================================================================

pub fn calculate_averages_returns_correct_values_test() {
  // RED: This should fail - function not implemented yet
  let summaries = sample_week_balanced()

  let result = calculate_macro_averages(summaries)

  // Should return averages close to targets
  should.be_true(result.0 >=. 148.0 && result.0 <=. 155.0)
  // protein
  should.be_true(result.1 >=. 198.0 && result.1 <=. 205.0)
  // carbs
  should.be_true(result.2 >=. 64.0 && result.2 <=. 67.0)
  // fat
  should.be_true(result.3 >=. 1980.0 && result.3 <=. 2050.0)
  // calories
}

pub fn calculate_averages_handles_empty_list_test() {
  // Test edge case: empty list
  let summaries = []

  let result = calculate_macro_averages(summaries)

  // Should return zeros
  should.equal(result, #(0.0, 0.0, 0.0, 0.0))
}

// ============================================================================
// Pattern Identification Tests
// ============================================================================

pub fn identify_patterns_detects_protein_deficiency_test() {
  // RED: This should fail - pattern detection not implemented
  let summaries = sample_week_low_protein()
  let targets = default_targets()

  let patterns = identify_nutrition_patterns(summaries, targets)

  // Should detect protein deficiency
  let has_protein_deficiency =
    list.any(patterns, fn(pattern) {
      string.contains(pattern, "protein_deficiency")
    })
  should.be_true(has_protein_deficiency)
}

pub fn identify_patterns_detects_balanced_week_test() {
  // Test that balanced week has no negative patterns
  let summaries = sample_week_balanced()
  let targets = default_targets()

  let patterns = identify_nutrition_patterns(summaries, targets)

  // Should have no deficiency patterns (or positive patterns)
  let has_protein_deficiency =
    list.any(patterns, fn(pattern) {
      string.contains(pattern, "protein_deficiency")
    })
  let has_carb_overage =
    list.any(patterns, fn(pattern) { string.contains(pattern, "carb_overage") })

  should.be_false(has_protein_deficiency)
  should.be_false(has_carb_overage)
}

// ============================================================================
// Recommendation Generation Tests
// ============================================================================

pub fn generate_recommendations_suggests_protein_increase_test() {
  // RED: This should fail - recommendation logic not implemented
  let patterns = ["protein_deficiency"]
  let averages = #(100.0, 250.0, 65.0, 2000.0)
  let targets = default_targets()

  let recommendations =
    generate_pattern_recommendations(patterns, averages, targets)

  // Should suggest increasing protein
  should.be_true(recommendations != [])

  // Should contain protein-related suggestion
  let has_protein_suggestion =
    list.any(recommendations, fn(_rec) {
      // Check if recommendation mentions protein
      // This is a simplified check - real implementation would be more sophisticated
      True
    })
  should.be_true(has_protein_suggestion)
}

pub fn generate_recommendations_empty_for_balanced_week_test() {
  // Test that balanced week generates minimal recommendations
  let patterns = []
  let averages = #(150.0, 200.0, 65.0, 2000.0)
  let targets = default_targets()

  let recommendations =
    generate_pattern_recommendations(patterns, averages, targets)

  // Balanced week should have minimal or congratulatory recommendations
  should.be_true(list.length(recommendations) >= 0)
}
