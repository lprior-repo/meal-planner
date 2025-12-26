/// NCP Analysis Module
///
/// Trend analysis, averaging, and consistency tracking for nutrition data:
/// - Analyze trends in nutrition history
/// - Calculate averages over time periods
/// - Track consistency against goals
/// - Retrieve historical nutrition data
import gleam/list
import meal_planner/ncp/calculations
import meal_planner/ncp/types.{
  type NutritionData, type NutritionGoals, type NutritionState,
  type TrendAnalysis, type TrendDirection, Decreasing, Increasing, NutritionData,
  Stable, TrendAnalysis,
}

// ============================================================================
// Nutrition History Functions
// ============================================================================

/// Get nutrition history for specified number of days
pub fn get_nutrition_history(_days: Int) -> Result(List(NutritionState), String) {
  // For now, return empty list
  // In full implementation, this would query the database
  Ok([])
}

// ============================================================================
// Average Calculations
// ============================================================================

/// Calculate average nutrition history - matches Go ncp/history.go AverageNutritionHistory
pub fn average_nutrition_history(history: List(NutritionState)) -> NutritionData {
  case history {
    [] -> NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)
    _ -> {
      // Calculate sum and count in one pass
      let #(sum, count) =
        list.fold(
          history,
          #(NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0), 0),
          fn(acc, state) {
            let updated_sum =
              NutritionData(
                protein: { acc.0 }.protein +. state.consumed.protein,
                fat: { acc.0 }.fat +. state.consumed.fat,
                carbs: { acc.0 }.carbs +. state.consumed.carbs,
                calories: { acc.0 }.calories +. state.consumed.calories,
              )
            #(updated_sum, acc.1 + 1)
          },
        )

      let count_float = int_to_float(count)
      NutritionData(
        protein: sum.protein /. count_float,
        fat: sum.fat /. count_float,
        carbs: sum.carbs /. count_float,
        calories: sum.calories /. count_float,
      )
    }
  }
}

// ============================================================================
// Trend Analysis Functions
// ============================================================================

/// Analyze trends in nutrition history
/// Compares first half average to second half average to determine trend direction
pub fn analyze_nutrition_trends(history: List(NutritionState)) -> TrendAnalysis {
  case history {
    [] ->
      TrendAnalysis(
        protein_trend: Stable,
        fat_trend: Stable,
        carbs_trend: Stable,
        calories_trend: Stable,
        protein_change: 0.0,
        fat_change: 0.0,
        carbs_change: 0.0,
        calories_change: 0.0,
      )
    [_] ->
      TrendAnalysis(
        protein_trend: Stable,
        fat_trend: Stable,
        carbs_trend: Stable,
        calories_trend: Stable,
        protein_change: 0.0,
        fat_change: 0.0,
        carbs_change: 0.0,
        calories_change: 0.0,
      )
    _ -> {
      // Count history length efficiently
      let len = list.fold(history, 0, fn(acc, _) { acc + 1 })
      let mid = len / 2

      // Split into first half and second half
      let first_half = list.take(history, mid)
      let second_half = list.drop(history, mid)

      let first_avg = average_nutrition_history(first_half)
      let second_avg = average_nutrition_history(second_half)

      // Calculate changes (percentage)
      let protein_change = case first_avg.protein {
        0.0 -> 0.0
        _ ->
          { second_avg.protein -. first_avg.protein }
          /. first_avg.protein
          *. 100.0
      }

      let fat_change = case first_avg.fat {
        0.0 -> 0.0
        _ -> { second_avg.fat -. first_avg.fat } /. first_avg.fat *. 100.0
      }

      let carbs_change = case first_avg.carbs {
        0.0 -> 0.0
        _ -> { second_avg.carbs -. first_avg.carbs } /. first_avg.carbs *. 100.0
      }

      let calories_change = case first_avg.calories {
        0.0 -> 0.0
        _ ->
          { second_avg.calories -. first_avg.calories }
          /. first_avg.calories
          *. 100.0
      }

      // Determine trend direction (threshold: 5%)
      let threshold = 5.0

      TrendAnalysis(
        protein_trend: determine_trend(protein_change, threshold),
        fat_trend: determine_trend(fat_change, threshold),
        carbs_trend: determine_trend(carbs_change, threshold),
        calories_trend: determine_trend(calories_change, threshold),
        protein_change: protein_change,
        fat_change: fat_change,
        carbs_change: carbs_change,
        calories_change: calories_change,
      )
    }
  }
}

/// Determine trend direction based on percentage change and threshold
fn determine_trend(pct_change: Float, threshold: Float) -> TrendDirection {
  let neg_threshold = 0.0 -. threshold
  case pct_change {
    change if change >. threshold -> Increasing
    change if change <. neg_threshold -> Decreasing
    _ -> Stable
  }
}

// ============================================================================
// Consistency Analysis Functions
// ============================================================================

/// Check if nutrition is consistently meeting goals (within tolerance)
/// Returns the percentage of days that met the tolerance
pub fn calculate_consistency_rate(
  history: List(NutritionState),
  goals: NutritionGoals,
  tolerance_pct: Float,
) -> Float {
  case history {
    [] -> 0.0
    _ -> {
      // Count total and within_tolerance in one pass
      let #(total_count, within_count) =
        list.fold(history, #(0, 0), fn(acc, state) {
          let deviation =
            calculations.calculate_deviation(goals, state.consumed)
          let is_within = case
            calculations.deviation_is_within_tolerance(deviation, tolerance_pct)
          {
            True -> 1
            False -> 0
          }
          #(acc.0 + 1, acc.1 + is_within)
        })

      let total = int_to_float(total_count)
      let within_tolerance_count = int_to_float(within_count)
      { within_tolerance_count /. total } *. 100.0
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Convert int to float
@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float
