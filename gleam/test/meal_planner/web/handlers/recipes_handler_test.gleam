/// Tests for the recipe scoring handler
///
/// Tests the POST /api/ai/score-recipe endpoint which scores recipes based on:
/// - Macro target alignment (protein/fat/carb percentages)
/// - Diet compliance (vertical diet, FODMAP level)
/// - Scoring weights

import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/types
import meal_planner/web/handlers/recipes

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Create a basic Macros value for testing
fn macros(protein: Float, fat: Float, carbs: Float) -> types.Macros {
  types.Macros(protein: protein, fat: fat, carbs: carbs)
}

// ============================================================================
// Macro Matching Tests
// ============================================================================

/// Test: Perfect macro match (within 5% tolerance) should score 100
/// Example: Target 30% protein, actual 30% protein -> score 100
pub fn test_perfect_macro_match_scores_100() {
  // Perfect match should give 100
  let score = recipes.calculate_macro_match(0.30, 0.30)
  should.equal(score, 100.0)
}

/// Test: Exact tolerance boundary (5%) should score 100
pub fn test_tolerance_boundary_scores_100() {
  let score = recipes.calculate_macro_match(0.35, 0.30)
  should.equal(score, 100.0)
}

/// Test: Half tolerance (2.5% difference) should score 100
pub fn test_half_tolerance_scores_100() {
  let score = recipes.calculate_macro_match(0.325, 0.30)
  should.equal(score, 100.0)
}

/// Test: Just outside tolerance (7.5% difference) should score between 50-100
pub fn test_outside_tolerance_scores_less_than_100() {
  let score = recipes.calculate_macro_match(0.375, 0.30)
  should.be_true(score < 100.0)
  should.be_true(score > 50.0)
}

/// Test: 10% difference should score approximately 50
pub fn test_10_percent_difference_scores_around_50() {
  let score = recipes.calculate_macro_match(0.40, 0.30)
  should.be_true(score >= 45.0)
  should.be_true(score <= 55.0)
}

/// Test: 20% difference should score 0
pub fn test_20_percent_difference_scores_0() {
  let score = recipes.calculate_macro_match(0.50, 0.30)
  should.equal(score, 0.0)
}

/// Test: Large difference (50%) should score 0
pub fn test_large_difference_scores_0() {
  let score = recipes.calculate_macro_match(0.80, 0.30)
  should.equal(score, 0.0)
}

// ============================================================================
// Compliance Scoring Tests
// ============================================================================

/// Test: Vertical compliant + Low FODMAP -> max score (100)
pub fn test_vertical_compliant_low_fodmap_scores_100() {
  let score = recipes.calculate_compliance_score(True, "low")
  should.equal(score, 100.0)
}

/// Test: Vertical compliant + Medium FODMAP -> above 50
pub fn test_vertical_compliant_medium_fodmap_scores_above_50() {
  let score = recipes.calculate_compliance_score(True, "medium")
  should.equal(score, 75.0)
}

/// Test: Vertical compliant + High FODMAP -> 50
pub fn test_vertical_compliant_high_fodmap_scores_50() {
  let score = recipes.calculate_compliance_score(True, "high")
  should.equal(score, 50.0)
}

/// Test: Not vertical compliant + Low FODMAP -> 75
pub fn test_not_vertical_compliant_low_fodmap_scores_75() {
  let score = recipes.calculate_compliance_score(False, "low")
  should.equal(score, 75.0)
}

/// Test: Not vertical compliant + Medium FODMAP -> 50
pub fn test_not_vertical_compliant_medium_fodmap_scores_50() {
  let score = recipes.calculate_compliance_score(False, "medium")
  should.equal(score, 50.0)
}

/// Test: Not vertical compliant + High FODMAP -> min score (25)
pub fn test_not_vertical_compliant_high_fodmap_scores_25() {
  let score = recipes.calculate_compliance_score(False, "high")
  should.equal(score, 25.0)
}

/// Test: Vertical compliant + unknown FODMAP level -> 62.5 (50 + 75 / 2)
pub fn test_vertical_compliant_unknown_fodmap_scores_62_5() {
  let score = recipes.calculate_compliance_score(True, "unknown")
  should.equal(score, 62.5)
}

// ============================================================================
// Calories and Macros Integration Tests
// ============================================================================

/// Test: Macros calories calculation
pub fn test_macros_calories_calculation() {
  let m = macros(50.0, 30.0, 100.0)
  let calories = types.macros_calories(m)
  // 50*4 + 30*9 + 100*4 = 200 + 270 + 400 = 870
  should.equal(calories, 870.0)
}

/// Test: Empty macros have zero calories
pub fn test_empty_macros_zero_calories() {
  let m = macros(0.0, 0.0, 0.0)
  let calories = types.macros_calories(m)
  should.equal(calories, 0.0)
}

/// Test: Macros with high protein
pub fn test_macros_high_protein() {
  let m = macros(100.0, 20.0, 50.0)
  let calories = types.macros_calories(m)
  // 100*4 + 20*9 + 50*4 = 400 + 180 + 200 = 780
  should.equal(calories, 780.0)
}

// ============================================================================
// Macro Percentage Tests
// ============================================================================

/// Test: Protein percentage calculation
pub fn test_protein_percentage_calculation() {
  let m = macros(100.0, 0.0, 0.0)
  // 100g protein = 400 calories
  let ratio = types.protein_ratio(m)
  should.equal(ratio, 1.0)
}

/// Test: Fat percentage calculation
pub fn test_fat_percentage_calculation() {
  let m = macros(0.0, 100.0, 0.0)
  // 100g fat = 900 calories
  let ratio = types.fat_ratio(m)
  should.equal(ratio, 1.0)
}

/// Test: Carbs percentage calculation
pub fn test_carbs_percentage_calculation() {
  let m = macros(0.0, 0.0, 100.0)
  // 100g carbs = 400 calories
  let ratio = types.carb_ratio(m)
  should.equal(ratio, 1.0)
}

/// Test: Balanced macros percentages
pub fn test_balanced_macros_percentages() {
  let m = macros(40.0, 25.0, 80.0)
  // Total: 40*4 + 25*9 + 80*4 = 160 + 225 + 320 = 705 cals
  // Protein: 160/705 = 0.227 (22.7%)
  // Fat: 225/705 = 0.319 (31.9%)
  // Carbs: 320/705 = 0.454 (45.4%)
  let p_ratio = types.protein_ratio(m)
  let f_ratio = types.fat_ratio(m)
  let c_ratio = types.carb_ratio(m)

  should.be_true(p_ratio > 0.22)
  should.be_true(p_ratio < 0.23)
  should.be_true(f_ratio > 0.31)
  should.be_true(f_ratio < 0.32)
  should.be_true(c_ratio > 0.45)
  should.be_true(c_ratio < 0.46)
}

// ============================================================================
// Edge Cases
// ============================================================================

/// Test: Score calculation with zero target percentage (edge case protection)
pub fn test_macro_match_with_zero_actual_and_target() {
  let score = recipes.calculate_macro_match(0.0, 0.0)
  should.equal(score, 100.0)
}

/// Test: Large positive difference
pub fn test_macro_match_large_difference_positive() {
  let score = recipes.calculate_macro_match(0.95, 0.05)
  should.equal(score, 0.0)
}

/// Test: Large negative difference
pub fn test_macro_match_large_difference_negative() {
  let score = recipes.calculate_macro_match(0.05, 0.95)
  should.equal(score, 0.0)
}

// ============================================================================
// Integration Tests
// ============================================================================

/// Test: Compliance score is always between 0-100
pub fn test_compliance_score_always_valid_range() {
  let test_cases = [
    #(True, "low"),
    #(True, "medium"),
    #(True, "high"),
    #(True, "unknown"),
    #(False, "low"),
    #(False, "medium"),
    #(False, "high"),
    #(False, "unknown"),
  ]

  list.each(test_cases, fn(test_case) {
    let score = recipes.calculate_compliance_score(test_case.0, test_case.1)
    should.be_true(score >= 0.0)
    should.be_true(score <= 100.0)
  })
}

/// Test: Macro match score is always between 0-100
pub fn test_macro_match_score_always_valid_range() {
  let test_cases = [
    #(0.0, 0.0),
    #(0.1, 0.1),
    #(0.3, 0.3),
    #(0.5, 0.5),
    #(1.0, 1.0),
    #(0.0, 0.5),
    #(0.5, 0.0),
    #(0.2, 0.8),
  ]

  list.each(test_cases, fn(test_case) {
    let score = recipes.calculate_macro_match(test_case.0, test_case.1)
    should.be_true(score >= 0.0)
    should.be_true(score <= 100.0)
  })
}
