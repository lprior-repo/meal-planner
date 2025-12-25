//// Nutrition tracking state and calculations
////
//// Handles nutrition state tracking, history, and daily calculations

import gleam/float
import gleam/list
import gleam/string
import meal_planner/types/nutrition/goals.{
  type NutritionData, type NutritionGoals, NutritionData, calculate_deviation,
  deviation_is_within_tolerance,
}

// ============================================================================
// Types
// ============================================================================

/// NutritionState represents a day's nutrition tracking state
pub type NutritionState {
  NutritionState(date: String, consumed: NutritionData, synced_at: String)
}

// ============================================================================
// History and Statistics
// ============================================================================

/// Get nutrition history for specified number of days
pub fn get_nutrition_history(_days: Int) -> Result(List(NutritionState), String) {
  Ok([])
}

/// Calculate average nutrition history
pub fn average_nutrition_history(history: List(NutritionState)) -> NutritionData {
  case history {
    [] -> NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)
    _ -> {
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
// Calculation Functions
// ============================================================================

/// Calculate daily totals from a list of nutrition states
pub fn calculate_daily_totals(meals: List(NutritionState)) -> NutritionData {
  case meals {
    [] -> NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)
    _ -> {
      list.fold(
        meals,
        NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0),
        fn(acc, meal) {
          NutritionData(
            protein: acc.protein +. meal.consumed.protein,
            fat: acc.fat +. meal.consumed.fat,
            carbs: acc.carbs +. meal.consumed.carbs,
            calories: acc.calories +. meal.consumed.calories,
          )
        },
      )
    }
  }
}

/// Calculate macro percentages from nutrition data
pub fn calculate_macro_percentages(
  data: NutritionData,
) -> #(Float, Float, Float) {
  case data.calories {
    0.0 -> #(0.0, 0.0, 0.0)
    _ -> {
      let protein_pct = { data.protein *. 4.0 } /. data.calories *. 100.0
      let fat_pct = { data.fat *. 9.0 } /. data.calories *. 100.0
      let carbs_pct = { data.carbs *. 4.0 } /. data.calories *. 100.0
      #(protein_pct, fat_pct, carbs_pct)
    }
  }
}

/// Check if consumed macros meet daily targets
pub fn check_macro_targets(
  consumed: NutritionData,
  goals: NutritionGoals,
) -> Bool {
  let deviation = calculate_deviation(goals, consumed)
  let tolerance = 10.0

  float.absolute_value(deviation.protein_pct) <=. tolerance
  && float.absolute_value(deviation.fat_pct) <=. tolerance
  && float.absolute_value(deviation.carbs_pct) <=. tolerance
  && float.absolute_value(deviation.calories_pct) <=. tolerance
}

/// Suggest macro adjustments needed to reach daily goals
pub fn suggest_macro_adjustments(
  consumed: NutritionData,
  goals: NutritionGoals,
) -> String {
  let deviation = calculate_deviation(goals, consumed)
  let tolerance = 5.0

  let is_on_target =
    float.absolute_value(deviation.protein_pct) <=. tolerance
    && float.absolute_value(deviation.fat_pct) <=. tolerance
    && float.absolute_value(deviation.carbs_pct) <=. tolerance

  case is_on_target {
    True -> "Perfect macros - you're on target! Excellent nutrition balance."
    False -> {
      let suggestions = []

      let suggestions = case deviation.protein_pct <. -5.0 {
        True -> list.append(suggestions, ["Add more protein"])
        False -> suggestions
      }

      let suggestions = case deviation.fat_pct <. -5.0 {
        True -> list.append(suggestions, ["Add more healthy fats"])
        False -> suggestions
      }

      let suggestions = case deviation.carbs_pct <. -5.0 {
        True -> list.append(suggestions, ["Add more carbs"])
        False -> suggestions
      }

      let suggestions = case deviation.protein_pct >. 15.0 {
        True -> list.append(suggestions, ["Reduce protein intake"])
        False -> suggestions
      }

      let suggestions = case deviation.fat_pct >. 15.0 {
        True -> list.append(suggestions, ["Reduce fat intake"])
        False -> suggestions
      }

      let suggestions = case deviation.carbs_pct >. 15.0 {
        True -> list.append(suggestions, ["Reduce carbs intake"])
        False -> suggestions
      }

      case suggestions {
        [] -> "Close to target. Keep monitoring your intake."
        _ ->
          "Adjustments needed: "
          <> string.concat(list.intersperse(suggestions, ", "))
      }
    }
  }
}

/// Estimate daily calories from macronutrients
pub fn estimate_daily_calories(
  protein: Float,
  fat: Float,
  carbs: Float,
) -> Float {
  { protein *. 4.0 } +. { fat *. 9.0 } +. { carbs *. 4.0 }
}

/// Calculate consistency rate
pub fn calculate_consistency_rate(
  history: List(NutritionState),
  goals: NutritionGoals,
  tolerance_pct: Float,
) -> Float {
  case history {
    [] -> 0.0
    _ -> {
      let #(total_count, within_count) =
        list.fold(history, #(0, 0), fn(acc, state) {
          let deviation = calculate_deviation(goals, state.consumed)
          let is_within = case
            deviation_is_within_tolerance(deviation, tolerance_pct)
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

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float
