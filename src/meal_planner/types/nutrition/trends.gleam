//// Nutrition trend analysis
////
//// Analyzes nutrition trends over time to identify patterns

import gleam/list
import meal_planner/types/nutrition/tracking.{
  type NutritionState, average_nutrition_history,
}

// ============================================================================
// Types
// ============================================================================

/// TrendDirection represents whether a metric is trending up, down, or stable
pub type TrendDirection {
  Increasing
  Decreasing
  Stable
}

/// TrendAnalysis contains trend information for all macros
pub type TrendAnalysis {
  TrendAnalysis(
    protein_trend: TrendDirection,
    fat_trend: TrendDirection,
    carbs_trend: TrendDirection,
    calories_trend: TrendDirection,
    protein_change: Float,
    fat_change: Float,
    carbs_change: Float,
    calories_change: Float,
  )
}

// ============================================================================
// Trend Analysis Functions
// ============================================================================

/// Analyze trends in nutrition history
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
      let len = list.fold(history, 0, fn(acc, _) { acc + 1 })
      let mid = len / 2

      let first_half = list.take(history, mid)
      let second_half = list.drop(history, mid)

      let first_avg = average_nutrition_history(first_half)
      let second_avg = average_nutrition_history(second_half)

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

fn determine_trend(pct_change: Float, threshold: Float) -> TrendDirection {
  let neg_threshold = 0.0 -. threshold
  case pct_change {
    change if change >. threshold -> Increasing
    change if change <. neg_threshold -> Decreasing
    _ -> Stable
  }
}
