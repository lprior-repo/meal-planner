//// Tests for the nutrition types module

import gleeunit
import gleeunit/should
import meal_planner/types/macros
import meal_planner/types/nutrition.{
  Decreasing, DeviationResult, Increasing, NutritionData, NutritionGoals,
  NutritionState, ScoredRecipe, Stable, TrendDirection, analyze_nutrition_trends,
  average_nutrition_history, calculate_consistency_rate, calculate_daily_totals,
  calculate_deviation, calculate_macro_percentages, check_macro_targets,
  deviation_is_within_tolerance, deviation_max, estimate_daily_calories,
  get_default_goals, nutrition_goals_validate, suggest_macro_adjustments,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Validation Tests
// ============================================================================

pub fn nutrition_goals_validate_success_test() {
  let goals =
    NutritionGoals(
      daily_protein: 150.0,
      daily_fat: 50.0,
      daily_carbs: 200.0,
      daily_calories: 2000.0,
    )

  nutrition_goals_validate(goals)
  |> should.be_ok()
}

pub fn nutrition_goals_validate_zero_protein_test() {
  let goals =
    NutritionGoals(
      daily_protein: 0.0,
      daily_fat: 50.0,
      daily_carbs: 200.0,
      daily_calories: 2000.0,
    )

  nutrition_goals_validate(goals)
  |> should.be_error()
}

pub fn nutrition_goals_validate_negative_calories_test() {
  let goals =
    NutritionGoals(
      daily_protein: 150.0,
      daily_fat: 50.0,
      daily_carbs: 200.0,
      daily_calories: -500.0,
    )

  nutrition_goals_validate(goals)
  |> should.be_error()
}

// ============================================================================
// Deviation Calculation Tests
// ============================================================================

pub fn calculate_deviation_over_test() {
  let goals =
    NutritionGoals(
      daily_protein: 100.0,
      daily_fat: 50.0,
      daily_carbs: 200.0,
      daily_calories: 2000.0,
    )

  let actual =
    NutritionData(protein: 150.0, fat: 50.0, carbs: 200.0, calories: 2000.0)

  let deviation = calculate_deviation(goals, actual)

  deviation.protein_pct
  |> should.equal(50.0)
}

pub fn calculate_deviation_under_test() {
  let goals =
    NutritionGoals(
      daily_protein: 100.0,
      daily_fat: 50.0,
      daily_carbs: 200.0,
      daily_calories: 2000.0,
    )

  let actual =
    NutritionData(protein: 50.0, fat: 50.0, carbs: 200.0, calories: 2000.0)

  let deviation = calculate_deviation(goals, actual)

  deviation.protein_pct
  |> should.equal(-50.0)
}

pub fn deviation_is_within_tolerance_true_test() {
  let deviation =
    DeviationResult(
      protein_pct: 5.0,
      fat_pct: 3.0,
      carbs_pct: -2.0,
      calories_pct: 0.0,
    )

  deviation_is_within_tolerance(deviation, 10.0)
  |> should.be_true()
}

pub fn deviation_is_within_tolerance_false_test() {
  let deviation =
    DeviationResult(
      protein_pct: 15.0,
      fat_pct: 3.0,
      carbs_pct: -2.0,
      calories_pct: 0.0,
    )

  deviation_is_within_tolerance(deviation, 10.0)
  |> should.be_false()
}

pub fn deviation_max_test() {
  let deviation =
    DeviationResult(
      protein_pct: 5.0,
      fat_pct: 12.0,
      carbs_pct: -8.0,
      calories_pct: 0.0,
    )

  deviation_max(deviation)
  |> should.equal(12.0)
}

// ============================================================================
// History and Statistics Tests
// ============================================================================

pub fn average_nutrition_history_empty_test() {
  let history: List(NutritionState) = []

  let avg = average_nutrition_history(history)

  avg.protein
  |> should.equal(0.0)
}

pub fn average_nutrition_history_single_test() {
  let history = [
    NutritionState(
      date: "2025-12-24",
      consumed: NutritionData(
        protein: 100.0,
        fat: 50.0,
        carbs: 200.0,
        calories: 1800.0,
      ),
      synced_at: "2025-12-24T12:00:00Z",
    ),
  ]

  let avg = average_nutrition_history(history)

  avg.protein
  |> should.equal(100.0)
}

pub fn average_nutrition_history_multiple_test() {
  let history = [
    NutritionState(
      date: "2025-12-24",
      consumed: NutritionData(
        protein: 100.0,
        fat: 50.0,
        carbs: 200.0,
        calories: 1800.0,
      ),
      synced_at: "2025-12-24T12:00:00Z",
    ),
    NutritionState(
      date: "2025-12-25",
      consumed: NutritionData(
        protein: 200.0,
        fat: 60.0,
        carbs: 300.0,
        calories: 2400.0,
      ),
      synced_at: "2025-12-25T12:00:00Z",
    ),
  ]

  let avg = average_nutrition_history(history)

  avg.protein
  |> should.equal(150.0)

  avg.fat
  |> should.equal(55.0)
}

// ============================================================================
// Calculation Tests
// ============================================================================

pub fn calculate_daily_totals_empty_test() {
  let meals: List(NutritionState) = []

  let total = calculate_daily_totals(meals)

  total.protein
  |> should.equal(0.0)
}

pub fn calculate_daily_totals_test() {
  let meals = [
    NutritionState(
      date: "2025-12-24",
      consumed: NutritionData(
        protein: 30.0,
        fat: 15.0,
        carbs: 50.0,
        calories: 600.0,
      ),
      synced_at: "2025-12-24T12:00:00Z",
    ),
    NutritionState(
      date: "2025-12-24",
      consumed: NutritionData(
        protein: 40.0,
        fat: 20.0,
        carbs: 70.0,
        calories: 800.0,
      ),
      synced_at: "2025-12-24T13:00:00Z",
    ),
  ]

  let total = calculate_daily_totals(meals)

  total.protein
  |> should.equal(70.0)

  total.fat
  |> should.equal(35.0)
}

pub fn calculate_macro_percentages_test() {
  let data =
    NutritionData(protein: 150.0, fat: 50.0, carbs: 250.0, calories: 2000.0)

  let #(protein_pct, fat_pct, carbs_pct) = calculate_macro_percentages(data)

  protein_pct
  |> should.be_close(to: 30.0, within: 0.1)

  fat_pct
  |> should.be_close(to: 22.5, within: 0.1)
}

pub fn check_macro_targets_true_test() {
  let consumed =
    NutritionData(protein: 150.0, fat: 50.0, carbs: 200.0, calories: 1900.0)

  let goals =
    NutritionGoals(
      daily_protein: 150.0,
      daily_fat: 50.0,
      daily_carbs: 200.0,
      daily_calories: 2000.0,
    )

  check_macro_targets(consumed, goals)
  |> should.be_true()
}

pub fn check_macro_targets_false_test() {
  let consumed =
    NutritionData(protein: 250.0, fat: 50.0, carbs: 200.0, calories: 2400.0)

  let goals =
    NutritionGoals(
      daily_protein: 150.0,
      daily_fat: 50.0,
      daily_carbs: 200.0,
      daily_calories: 2000.0,
    )

  check_macro_targets(consumed, goals)
  |> should.be_false()
}

pub fn estimate_daily_calories_test() {
  let calories = estimate_daily_calories(150.0, 50.0, 200.0)

  calories
  |> should.equal(1800.0)
}

// ============================================================================
// Default Values Tests
// ============================================================================

pub fn get_default_goals_test() {
  let goals = get_default_goals()

  goals.daily_protein
  |> should.equal(180.0)

  goals.daily_fat
  |> should.equal(60.0)

  goals.daily_calories
  |> should.equal(2500.0)
}

// ============================================================================
// Trend Analysis Tests
// ============================================================================

pub fn analyze_nutrition_trends_empty_test() {
  let history: List(NutritionState) = []

  let analysis = analyze_nutrition_trends(history)

  analysis.protein_trend
  |> should.equal(Stable)
}

pub fn analyze_nutrition_trends_single_test() {
  let history = [
    NutritionState(
      date: "2025-12-24",
      consumed: NutritionData(
        protein: 100.0,
        fat: 50.0,
        carbs: 200.0,
        calories: 1800.0,
      ),
      synced_at: "2025-12-24T12:00:00Z",
    ),
  ]

  let analysis = analyze_nutrition_trends(history)

  analysis.protein_trend
  |> should.equal(Stable)
}

// ============================================================================
// Consistency Rate Tests
// ============================================================================

pub fn calculate_consistency_rate_empty_test() {
  let history: List(NutritionState) = []
  let goals = get_default_goals()

  let rate = calculate_consistency_rate(history, goals, 10.0)

  rate
  |> should.equal(0.0)
}
