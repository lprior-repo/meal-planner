/// NCP Calculations Module
///
/// Core nutrition calculations including:
/// - Validation of nutrition goals
/// - Deviation calculations (actual vs goals)
/// - Tolerance checks and statistics
/// - Min/max/variability calculations
/// - Daily totals and macro percentages
import gleam/float
import gleam/list
import meal_planner/ncp/types.{
  type DeviationResult, type NutritionData, type NutritionGoals,
  type NutritionState, DeviationResult, NutritionData, NutritionGoals,
}

// ============================================================================
// Validation Functions
// ============================================================================

/// Validate ensures goals are within reasonable ranges
pub fn nutrition_goals_validate(
  goals: NutritionGoals,
) -> Result(NutritionGoals, String) {
  case goals {
    NutritionGoals(protein, _, _, _) if protein <=. 0.0 ->
      Error("daily protein must be positive")
    NutritionGoals(_, fat, _, _) if fat <. 0.0 ->
      Error("daily fat cannot be negative")
    NutritionGoals(_, _, carbs, _) if carbs <. 0.0 ->
      Error("daily carbs cannot be negative")
    NutritionGoals(_, _, _, calories) if calories <=. 0.0 ->
      Error("daily calories must be positive")
    _ -> Ok(goals)
  }
}

// ============================================================================
// Deviation Calculations
// ============================================================================

/// Calculate percentage deviation between actual and goals
/// Returns positive values for over, negative for under
pub fn calculate_deviation(
  goals: NutritionGoals,
  actual: NutritionData,
) -> DeviationResult {
  DeviationResult(
    protein_pct: calc_pct_deviation(goals.daily_protein, actual.protein),
    fat_pct: calc_pct_deviation(goals.daily_fat, actual.fat),
    carbs_pct: calc_pct_deviation(goals.daily_carbs, actual.carbs),
    calories_pct: calc_pct_deviation(goals.daily_calories, actual.calories),
  )
}

/// Calculate (actual - goal) / goal * 100
fn calc_pct_deviation(goal: Float, actual: Float) -> Float {
  case goal {
    0.0 -> 0.0
    _ -> { actual -. goal } /. goal *. 100.0
  }
}

/// Check if all macro deviations are within the given tolerance
pub fn deviation_is_within_tolerance(
  dev: DeviationResult,
  tolerance_pct: Float,
) -> Bool {
  float.absolute_value(dev.protein_pct) <=. tolerance_pct
  && float.absolute_value(dev.fat_pct) <=. tolerance_pct
  && float.absolute_value(dev.carbs_pct) <=. tolerance_pct
}

/// Returns the maximum absolute deviation across all macros
pub fn deviation_max(dev: DeviationResult) -> Float {
  let protein_abs = float.absolute_value(dev.protein_pct)
  let fat_abs = float.absolute_value(dev.fat_pct)
  let carbs_abs = float.absolute_value(dev.carbs_pct)

  protein_abs
  |> float.max(fat_abs)
  |> float.max(carbs_abs)
}

// ============================================================================
// Min/Max Calculations
// ============================================================================

/// Calculate minimum values across nutrition history
pub fn calculate_min_nutrition(history: List(NutritionState)) -> NutritionData {
  case history {
    [] -> NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)
    [first, ..rest] ->
      list.fold(rest, first.consumed, fn(min_data, state) {
        NutritionData(
          protein: float.min(min_data.protein, state.consumed.protein),
          fat: float.min(min_data.fat, state.consumed.fat),
          carbs: float.min(min_data.carbs, state.consumed.carbs),
          calories: float.min(min_data.calories, state.consumed.calories),
        )
      })
  }
}

/// Calculate maximum values across nutrition history
pub fn calculate_max_nutrition(history: List(NutritionState)) -> NutritionData {
  case history {
    [] -> NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)
    [first, ..rest] ->
      list.fold(rest, first.consumed, fn(max_data, state) {
        NutritionData(
          protein: float.max(max_data.protein, state.consumed.protein),
          fat: float.max(max_data.fat, state.consumed.fat),
          carbs: float.max(max_data.carbs, state.consumed.carbs),
          calories: float.max(max_data.calories, state.consumed.calories),
        )
      })
  }
}

// ============================================================================
// Variability Calculations
// ============================================================================

/// Calculate standard deviation for a list of floats
fn calculate_std_dev(values: List(Float), mean: Float) -> Float {
  // Count and calculate variance in one pass
  let #(variance_sum, count) =
    list.fold(values, #(0.0, 0), fn(acc, value) {
      let diff = value -. mean
      #(acc.0 +. { diff *. diff }, acc.1 + 1)
    })

  case count {
    0 -> 0.0
    1 -> 0.0
    n -> {
      let variance = variance_sum /. int_to_float(n)

      case float.square_root(variance) {
        Ok(std_dev) -> std_dev
        Error(_) -> 0.0
      }
    }
  }
}

/// Calculate variability (standard deviation) for each macro in history
pub fn calculate_nutrition_variability(
  history: List(NutritionState),
) -> NutritionData {
  case history {
    [] -> NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)
    _ -> {
      let avg = average_nutrition_history(history)

      let proteins = list.map(history, fn(s) { s.consumed.protein })
      let fats = list.map(history, fn(s) { s.consumed.fat })
      let carbs_list = list.map(history, fn(s) { s.consumed.carbs })
      let calories_list = list.map(history, fn(s) { s.consumed.calories })

      NutritionData(
        protein: calculate_std_dev(proteins, avg.protein),
        fat: calculate_std_dev(fats, avg.fat),
        carbs: calculate_std_dev(carbs_list, avg.carbs),
        calories: calculate_std_dev(calories_list, avg.calories),
      )
    }
  }
}

/// Calculate average nutrition history (helper for variability)
fn average_nutrition_history(history: List(NutritionState)) -> NutritionData {
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
// Daily Calculation Functions
// ============================================================================

/// Calculate daily totals from a list of nutrition states (sums all meals for the day)
/// Returns total nutrition data by summing all meals consumed
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
/// Returns tuple of (protein_pct, fat_pct, carbs_pct) based on calorie contribution
/// Formula: (macro_grams * calories_per_gram) / total_calories * 100
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

/// Estimate daily calories from macronutrients
/// Uses standard calorie values: 4 cal/g protein, 9 cal/g fat, 4 cal/g carbs
pub fn estimate_daily_calories(
  protein: Float,
  fat: Float,
  carbs: Float,
) -> Float {
  { protein *. 4.0 } +. { fat *. 9.0 } +. { carbs *. 4.0 }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Convert int to float
@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float
