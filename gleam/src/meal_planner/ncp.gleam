/// NCP (Nutrition Control Plane) types for nutrition tracking and reconciliation

import gleam/float

/// NutritionGoals represents daily macro targets
pub type NutritionGoals {
  NutritionGoals(
    daily_protein: Float,
    daily_fat: Float,
    daily_carbs: Float,
    daily_calories: Float,
  )
}

/// NutritionData represents nutrition values (for a day or meal)
pub type NutritionData {
  NutritionData(protein: Float, fat: Float, carbs: Float, calories: Float)
}

/// DeviationResult represents percentage deviation from goals
pub type DeviationResult {
  DeviationResult(
    protein_pct: Float,
    fat_pct: Float,
    carbs_pct: Float,
    calories_pct: Float,
  )
}

/// RecipeSuggestion represents a recommended recipe to address nutritional deviation
pub type RecipeSuggestion {
  RecipeSuggestion(recipe_name: String, reason: String, score: Float)
}

/// AdjustmentPlan contains recipe suggestions to correct nutritional deviations
pub type AdjustmentPlan {
  AdjustmentPlan(deviation: DeviationResult, suggestions: List(RecipeSuggestion))
}

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
