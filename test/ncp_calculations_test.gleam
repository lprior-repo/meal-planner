/// NCP Calculations Module Tests
/// Tests for basic nutrition calculations, deviation tracking, and statistics
import gleam/float
import gleeunit
import gleeunit/should
import meal_planner/ncp/calculations
import meal_planner/ncp/types.{
  DeviationResult, NutritionData, NutritionGoals, NutritionState,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Validation Tests
// ============================================================================

pub fn nutrition_goals_validate_positive_values_test() {
  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  calculations.nutrition_goals_validate(goals)
  |> should.be_ok
  |> should.equal(goals)
}

pub fn nutrition_goals_validate_zero_protein_test() {
  let goals =
    NutritionGoals(
      daily_protein: 0.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  calculations.nutrition_goals_validate(goals)
  |> should.be_error
  |> should.equal("daily protein must be positive")
}

pub fn nutrition_goals_validate_negative_fat_test() {
  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: -10.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  calculations.nutrition_goals_validate(goals)
  |> should.be_error
  |> should.equal("daily fat cannot be negative")
}

pub fn nutrition_goals_validate_negative_calories_test() {
  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: -100.0,
    )

  calculations.nutrition_goals_validate(goals)
  |> should.be_error
  |> should.equal("daily calories must be positive")
}

// ============================================================================
// Deviation Calculation Tests
// ============================================================================

pub fn calculate_deviation_exact_match_test() {
  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  let actual =
    NutritionData(protein: 180.0, fat: 60.0, carbs: 250.0, calories: 2500.0)

  let deviation = calculations.calculate_deviation(goals, actual)

  deviation.protein_pct |> should.equal(0.0)
  deviation.fat_pct |> should.equal(0.0)
  deviation.carbs_pct |> should.equal(0.0)
  deviation.calories_pct |> should.equal(0.0)
}

pub fn calculate_deviation_deficit_test() {
  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  let actual =
    NutritionData(protein: 90.0, fat: 30.0, carbs: 125.0, calories: 1250.0)

  let deviation = calculations.calculate_deviation(goals, actual)

  // 50% deficit across all macros
  deviation.protein_pct |> float.loosely_equals(-50.0, 0.01) |> should.be_true
  deviation.fat_pct |> float.loosely_equals(-50.0, 0.01) |> should.be_true
  deviation.carbs_pct |> float.loosely_equals(-50.0, 0.01) |> should.be_true
  deviation.calories_pct |> float.loosely_equals(-50.0, 0.01) |> should.be_true
}

pub fn calculate_deviation_excess_test() {
  let goals =
    NutritionGoals(
      daily_protein: 100.0,
      daily_fat: 50.0,
      daily_carbs: 200.0,
      daily_calories: 2000.0,
    )

  let actual =
    NutritionData(protein: 150.0, fat: 75.0, carbs: 300.0, calories: 3000.0)

  let deviation = calculations.calculate_deviation(goals, actual)

  // 50% excess across all macros
  deviation.protein_pct |> float.loosely_equals(50.0, 0.01) |> should.be_true
  deviation.fat_pct |> float.loosely_equals(50.0, 0.01) |> should.be_true
  deviation.carbs_pct |> float.loosely_equals(50.0, 0.01) |> should.be_true
  deviation.calories_pct |> float.loosely_equals(50.0, 0.01) |> should.be_true
}

// ============================================================================
// Deviation Tolerance Tests
// ============================================================================

pub fn deviation_is_within_tolerance_all_zero_test() {
  let dev =
    DeviationResult(
      protein_pct: 0.0,
      fat_pct: 0.0,
      carbs_pct: 0.0,
      calories_pct: 0.0,
    )

  calculations.deviation_is_within_tolerance(dev, 5.0)
  |> should.be_true
}

pub fn deviation_is_within_tolerance_all_within_test() {
  let dev =
    DeviationResult(
      protein_pct: 4.0,
      fat_pct: -3.0,
      carbs_pct: 2.5,
      calories_pct: -1.0,
    )

  calculations.deviation_is_within_tolerance(dev, 5.0)
  |> should.be_true
}

pub fn deviation_is_within_tolerance_one_outside_test() {
  let dev =
    DeviationResult(
      protein_pct: 4.0,
      fat_pct: -3.0,
      carbs_pct: 6.0,
      calories_pct: -1.0,
    )

  calculations.deviation_is_within_tolerance(dev, 5.0)
  |> should.be_false
}

// ============================================================================
// Deviation Max Tests
// ============================================================================

pub fn deviation_max_all_positive_test() {
  let dev =
    DeviationResult(
      protein_pct: 10.0,
      fat_pct: 5.0,
      carbs_pct: 15.0,
      calories_pct: 0.0,
    )

  calculations.deviation_max(dev)
  |> should.equal(15.0)
}

pub fn deviation_max_all_negative_test() {
  let dev =
    DeviationResult(
      protein_pct: -10.0,
      fat_pct: -5.0,
      carbs_pct: -15.0,
      calories_pct: 0.0,
    )

  calculations.deviation_max(dev)
  |> should.equal(15.0)
}

pub fn deviation_max_mixed_test() {
  let dev =
    DeviationResult(
      protein_pct: -20.0,
      fat_pct: 5.0,
      carbs_pct: 10.0,
      calories_pct: 0.0,
    )

  calculations.deviation_max(dev)
  |> should.equal(20.0)
}

// ============================================================================
// Min/Max Nutrition Tests
// ============================================================================

pub fn calculate_min_nutrition_empty_test() {
  let history = []

  let result = calculations.calculate_min_nutrition(history)

  result.protein |> should.equal(0.0)
  result.fat |> should.equal(0.0)
  result.carbs |> should.equal(0.0)
  result.calories |> should.equal(0.0)
}

pub fn calculate_min_nutrition_single_entry_test() {
  let history = [
    NutritionState(
      date: "2025-01-01",
      consumed: NutritionData(
        protein: 100.0,
        fat: 50.0,
        carbs: 200.0,
        calories: 1800.0,
      ),
      synced_at: "2025-01-01T12:00:00Z",
    ),
  ]

  let result = calculations.calculate_min_nutrition(history)

  result.protein |> should.equal(100.0)
  result.fat |> should.equal(50.0)
  result.carbs |> should.equal(200.0)
  result.calories |> should.equal(1800.0)
}

pub fn calculate_min_nutrition_multiple_entries_test() {
  let history = [
    NutritionState(
      date: "2025-01-01",
      consumed: NutritionData(
        protein: 100.0,
        fat: 50.0,
        carbs: 200.0,
        calories: 1800.0,
      ),
      synced_at: "2025-01-01T12:00:00Z",
    ),
    NutritionState(
      date: "2025-01-02",
      consumed: NutritionData(
        protein: 80.0,
        fat: 60.0,
        carbs: 180.0,
        calories: 1700.0,
      ),
      synced_at: "2025-01-02T12:00:00Z",
    ),
    NutritionState(
      date: "2025-01-03",
      consumed: NutritionData(
        protein: 120.0,
        fat: 40.0,
        carbs: 220.0,
        calories: 1900.0,
      ),
      synced_at: "2025-01-03T12:00:00Z",
    ),
  ]

  let result = calculations.calculate_min_nutrition(history)

  result.protein |> should.equal(80.0)
  result.fat |> should.equal(40.0)
  result.carbs |> should.equal(180.0)
  result.calories |> should.equal(1700.0)
}

pub fn calculate_max_nutrition_empty_test() {
  let history = []

  let result = calculations.calculate_max_nutrition(history)

  result.protein |> should.equal(0.0)
  result.fat |> should.equal(0.0)
  result.carbs |> should.equal(0.0)
  result.calories |> should.equal(0.0)
}

pub fn calculate_max_nutrition_multiple_entries_test() {
  let history = [
    NutritionState(
      date: "2025-01-01",
      consumed: NutritionData(
        protein: 100.0,
        fat: 50.0,
        carbs: 200.0,
        calories: 1800.0,
      ),
      synced_at: "2025-01-01T12:00:00Z",
    ),
    NutritionState(
      date: "2025-01-02",
      consumed: NutritionData(
        protein: 80.0,
        fat: 60.0,
        carbs: 180.0,
        calories: 1700.0,
      ),
      synced_at: "2025-01-02T12:00:00Z",
    ),
    NutritionState(
      date: "2025-01-03",
      consumed: NutritionData(
        protein: 120.0,
        fat: 40.0,
        carbs: 220.0,
        calories: 1900.0,
      ),
      synced_at: "2025-01-03T12:00:00Z",
    ),
  ]

  let result = calculations.calculate_max_nutrition(history)

  result.protein |> should.equal(120.0)
  result.fat |> should.equal(60.0)
  result.carbs |> should.equal(220.0)
  result.calories |> should.equal(1900.0)
}

// ============================================================================
// Nutrition Variability Tests
// ============================================================================

pub fn calculate_nutrition_variability_empty_test() {
  let history = []

  let result = calculations.calculate_nutrition_variability(history)

  result.protein |> should.equal(0.0)
  result.fat |> should.equal(0.0)
  result.carbs |> should.equal(0.0)
  result.calories |> should.equal(0.0)
}

pub fn calculate_nutrition_variability_consistent_test() {
  // All days identical - should have zero variability
  let history = [
    NutritionState(
      date: "2025-01-01",
      consumed: NutritionData(
        protein: 100.0,
        fat: 50.0,
        carbs: 200.0,
        calories: 1800.0,
      ),
      synced_at: "2025-01-01T12:00:00Z",
    ),
    NutritionState(
      date: "2025-01-02",
      consumed: NutritionData(
        protein: 100.0,
        fat: 50.0,
        carbs: 200.0,
        calories: 1800.0,
      ),
      synced_at: "2025-01-02T12:00:00Z",
    ),
    NutritionState(
      date: "2025-01-03",
      consumed: NutritionData(
        protein: 100.0,
        fat: 50.0,
        carbs: 200.0,
        calories: 1800.0,
      ),
      synced_at: "2025-01-03T12:00:00Z",
    ),
  ]

  let result = calculations.calculate_nutrition_variability(history)

  result.protein |> should.equal(0.0)
  result.fat |> should.equal(0.0)
  result.carbs |> should.equal(0.0)
  result.calories |> should.equal(0.0)
}

// ============================================================================
// Daily Calculations Tests
// ============================================================================

pub fn calculate_daily_totals_empty_test() {
  let meals = []

  let result = calculations.calculate_daily_totals(meals)

  result.protein |> should.equal(0.0)
  result.fat |> should.equal(0.0)
  result.carbs |> should.equal(0.0)
  result.calories |> should.equal(0.0)
}

pub fn calculate_daily_totals_multiple_meals_test() {
  let meals = [
    NutritionState(
      date: "2025-01-01",
      consumed: NutritionData(
        protein: 30.0,
        fat: 10.0,
        carbs: 40.0,
        calories: 380.0,
      ),
      synced_at: "2025-01-01T08:00:00Z",
    ),
    NutritionState(
      date: "2025-01-01",
      consumed: NutritionData(
        protein: 50.0,
        fat: 20.0,
        carbs: 60.0,
        calories: 600.0,
      ),
      synced_at: "2025-01-01T12:00:00Z",
    ),
    NutritionState(
      date: "2025-01-01",
      consumed: NutritionData(
        protein: 40.0,
        fat: 15.0,
        carbs: 50.0,
        calories: 500.0,
      ),
      synced_at: "2025-01-01T18:00:00Z",
    ),
  ]

  let result = calculations.calculate_daily_totals(meals)

  result.protein |> should.equal(120.0)
  result.fat |> should.equal(45.0)
  result.carbs |> should.equal(150.0)
  result.calories |> should.equal(1480.0)
}

pub fn calculate_macro_percentages_zero_calories_test() {
  let data = NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)

  let #(protein_pct, fat_pct, carbs_pct) =
    calculations.calculate_macro_percentages(data)

  protein_pct |> should.equal(0.0)
  fat_pct |> should.equal(0.0)
  carbs_pct |> should.equal(0.0)
}

pub fn calculate_macro_percentages_balanced_test() {
  // 100g protein = 400 cal, 50g fat = 450 cal, 100g carbs = 400 cal
  // Total = 1250 cal
  // Protein: 32%, Fat: 36%, Carbs: 32%
  let data =
    NutritionData(protein: 100.0, fat: 50.0, carbs: 100.0, calories: 1250.0)

  let #(protein_pct, fat_pct, carbs_pct) =
    calculations.calculate_macro_percentages(data)

  protein_pct |> float.loosely_equals(32.0, 0.1) |> should.be_true
  fat_pct |> float.loosely_equals(36.0, 0.1) |> should.be_true
  carbs_pct |> float.loosely_equals(32.0, 0.1) |> should.be_true
}

pub fn estimate_daily_calories_test() {
  // 100g protein = 400 cal, 50g fat = 450 cal, 100g carbs = 400 cal
  // Total = 1250 cal
  let result = calculations.estimate_daily_calories(100.0, 50.0, 100.0)

  result |> should.equal(1250.0)
}

pub fn estimate_daily_calories_zero_test() {
  let result = calculations.estimate_daily_calories(0.0, 0.0, 0.0)

  result |> should.equal(0.0)
}
