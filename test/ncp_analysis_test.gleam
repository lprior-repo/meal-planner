/// NCP Analysis Module Tests
/// Tests for nutrition trend analysis, averaging, and consistency tracking
import gleam/float
import gleeunit
import gleeunit/should
import meal_planner/ncp/analysis
import meal_planner/ncp/types.{
  Decreasing, Increasing, NutritionData, NutritionGoals, NutritionState, Stable,
}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Nutrition History Tests
// ============================================================================

pub fn get_nutrition_history_returns_empty_test() {
  let result = analysis.get_nutrition_history(7)

  result
  |> should.be_ok
  |> should.equal([])
}

// ============================================================================
// Average Nutrition History Tests
// ============================================================================

pub fn average_nutrition_history_empty_test() {
  let history = []

  let result = analysis.average_nutrition_history(history)

  result.protein |> should.equal(0.0)
  result.fat |> should.equal(0.0)
  result.carbs |> should.equal(0.0)
  result.calories |> should.equal(0.0)
}

pub fn average_nutrition_history_single_entry_test() {
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

  let result = analysis.average_nutrition_history(history)

  result.protein |> should.equal(100.0)
  result.fat |> should.equal(50.0)
  result.carbs |> should.equal(200.0)
  result.calories |> should.equal(1800.0)
}

pub fn average_nutrition_history_multiple_entries_test() {
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

  let result = analysis.average_nutrition_history(history)

  result.protein |> should.equal(100.0)
  result.fat |> should.equal(50.0)
  result.carbs |> should.equal(200.0)
  result.calories |> float.loosely_equals(1800.0, 0.1) |> should.be_true
}

// ============================================================================
// Trend Analysis Tests
// ============================================================================

pub fn analyze_nutrition_trends_empty_history_test() {
  let history = []

  let result = analysis.analyze_nutrition_trends(history)

  result.protein_trend |> should.equal(Stable)
  result.fat_trend |> should.equal(Stable)
  result.carbs_trend |> should.equal(Stable)
  result.calories_trend |> should.equal(Stable)
  result.protein_change |> should.equal(0.0)
  result.fat_change |> should.equal(0.0)
  result.carbs_change |> should.equal(0.0)
  result.calories_change |> should.equal(0.0)
}

pub fn analyze_nutrition_trends_single_entry_test() {
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

  let result = analysis.analyze_nutrition_trends(history)

  result.protein_trend |> should.equal(Stable)
  result.fat_trend |> should.equal(Stable)
  result.carbs_trend |> should.equal(Stable)
  result.calories_trend |> should.equal(Stable)
}

pub fn analyze_nutrition_trends_increasing_protein_test() {
  let history = [
    NutritionState(
      date: "2025-01-01",
      consumed: NutritionData(
        protein: 80.0,
        fat: 50.0,
        carbs: 200.0,
        calories: 1700.0,
      ),
      synced_at: "2025-01-01T12:00:00Z",
    ),
    NutritionState(
      date: "2025-01-02",
      consumed: NutritionData(
        protein: 85.0,
        fat: 50.0,
        carbs: 200.0,
        calories: 1750.0,
      ),
      synced_at: "2025-01-02T12:00:00Z",
    ),
    NutritionState(
      date: "2025-01-03",
      consumed: NutritionData(
        protein: 100.0,
        fat: 50.0,
        carbs: 200.0,
        calories: 1850.0,
      ),
      synced_at: "2025-01-03T12:00:00Z",
    ),
    NutritionState(
      date: "2025-01-04",
      consumed: NutritionData(
        protein: 110.0,
        fat: 50.0,
        carbs: 200.0,
        calories: 1950.0,
      ),
      synced_at: "2025-01-04T12:00:00Z",
    ),
  ]

  let result = analysis.analyze_nutrition_trends(history)

  // First half avg: (80 + 85) / 2 = 82.5
  // Second half avg: (100 + 110) / 2 = 105
  // Change: (105 - 82.5) / 82.5 * 100 = 27.27% (> 5% threshold)
  result.protein_trend |> should.equal(Increasing)
}

pub fn analyze_nutrition_trends_decreasing_carbs_test() {
  let history = [
    NutritionState(
      date: "2025-01-01",
      consumed: NutritionData(
        protein: 100.0,
        fat: 50.0,
        carbs: 250.0,
        calories: 2000.0,
      ),
      synced_at: "2025-01-01T12:00:00Z",
    ),
    NutritionState(
      date: "2025-01-02",
      consumed: NutritionData(
        protein: 100.0,
        fat: 50.0,
        carbs: 240.0,
        calories: 1950.0,
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
    NutritionState(
      date: "2025-01-04",
      consumed: NutritionData(
        protein: 100.0,
        fat: 50.0,
        carbs: 180.0,
        calories: 1700.0,
      ),
      synced_at: "2025-01-04T12:00:00Z",
    ),
  ]

  let result = analysis.analyze_nutrition_trends(history)

  // First half avg: (250 + 240) / 2 = 245
  // Second half avg: (200 + 180) / 2 = 190
  // Change: (190 - 245) / 245 * 100 = -22.45% (< -5% threshold)
  result.carbs_trend |> should.equal(Decreasing)
}

pub fn analyze_nutrition_trends_stable_fat_test() {
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
        fat: 51.0,
        carbs: 200.0,
        calories: 1810.0,
      ),
      synced_at: "2025-01-02T12:00:00Z",
    ),
  ]

  let result = analysis.analyze_nutrition_trends(history)

  // Change: (51 - 50) / 50 * 100 = 2% (within ±5% threshold)
  result.fat_trend |> should.equal(Stable)
}

// ============================================================================
// Consistency Rate Tests
// ============================================================================

pub fn calculate_consistency_rate_empty_history_test() {
  let history = []
  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  let result = analysis.calculate_consistency_rate(history, goals, 10.0)

  result |> should.equal(0.0)
}

pub fn calculate_consistency_rate_all_within_tolerance_test() {
  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  let history = [
    NutritionState(
      date: "2025-01-01",
      consumed: NutritionData(
        protein: 180.0,
        fat: 60.0,
        carbs: 250.0,
        calories: 2500.0,
      ),
      synced_at: "2025-01-01T12:00:00Z",
    ),
    NutritionState(
      date: "2025-01-02",
      consumed: NutritionData(
        protein: 185.0,
        fat: 62.0,
        carbs: 255.0,
        calories: 2550.0,
      ),
      synced_at: "2025-01-02T12:00:00Z",
    ),
  ]

  let result = analysis.calculate_consistency_rate(history, goals, 10.0)

  result |> should.equal(100.0)
}

pub fn calculate_consistency_rate_partial_within_tolerance_test() {
  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  let history = [
    // Within tolerance
    NutritionState(
      date: "2025-01-01",
      consumed: NutritionData(
        protein: 180.0,
        fat: 60.0,
        carbs: 250.0,
        calories: 2500.0,
      ),
      synced_at: "2025-01-01T12:00:00Z",
    ),
    // Outside tolerance (50% under)
    NutritionState(
      date: "2025-01-02",
      consumed: NutritionData(
        protein: 90.0,
        fat: 30.0,
        carbs: 125.0,
        calories: 1250.0,
      ),
      synced_at: "2025-01-02T12:00:00Z",
    ),
  ]

  let result = analysis.calculate_consistency_rate(history, goals, 10.0)

  result |> should.equal(50.0)
}

pub fn calculate_consistency_rate_none_within_tolerance_test() {
  let goals =
    NutritionGoals(
      daily_protein: 180.0,
      daily_fat: 60.0,
      daily_carbs: 250.0,
      daily_calories: 2500.0,
    )

  let history = [
    // 50% under (outside 10% tolerance)
    NutritionState(
      date: "2025-01-01",
      consumed: NutritionData(
        protein: 90.0,
        fat: 30.0,
        carbs: 125.0,
        calories: 1250.0,
      ),
      synced_at: "2025-01-01T12:00:00Z",
    ),
    // 50% over (outside 10% tolerance)
    NutritionState(
      date: "2025-01-02",
      consumed: NutritionData(
        protein: 270.0,
        fat: 90.0,
        carbs: 375.0,
        calories: 3750.0,
      ),
      synced_at: "2025-01-02T12:00:00Z",
    ),
  ]

  let result = analysis.calculate_consistency_rate(history, goals, 10.0)

  result |> should.equal(0.0)
}
