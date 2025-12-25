//// Nutrition types for tracking, goals, and calculations
////
//// This module provides comprehensive nutrition tracking types and calculations

import gleam/float
import gleam/int
import gleam/list
import gleam/string
import meal_planner/nutrition_constants
import meal_planner/types/macros.{type Macros}

// ============================================================================
// Core Nutrition Types
// ============================================================================

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
  AdjustmentPlan(
    deviation: DeviationResult,
    suggestions: List(RecipeSuggestion),
  )
}

/// ReconciliationResult represents the full result of a nutrition reconciliation
pub type ReconciliationResult {
  ReconciliationResult(
    date: String,
    average_consumed: NutritionData,
    goals: NutritionGoals,
    deviation: DeviationResult,
    plan: AdjustmentPlan,
    within_tolerance: Bool,
  )
}

/// ScoredRecipe represents a recipe with its nutritional macros for scoring
pub type ScoredRecipe {
  ScoredRecipe(name: String, macros: Macros)
}

/// NutritionState represents a day's nutrition tracking state
pub type NutritionState {
  NutritionState(date: String, consumed: NutritionData, synced_at: String)
}

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
// Default Values
// ============================================================================

/// Get default nutrition goals
pub fn get_default_goals() -> NutritionGoals {
  NutritionGoals(
    daily_protein: 180.0,
    daily_fat: 60.0,
    daily_carbs: 250.0,
    daily_calories: 2500.0,
  )
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

/// Generate adjustment plan
pub fn generate_adjustments(
  deviation: DeviationResult,
  recipes: List(ScoredRecipe),
  limit: Int,
) -> AdjustmentPlan {
  let suggestions = select_top_recipes(deviation, recipes, limit)
  AdjustmentPlan(deviation: deviation, suggestions: suggestions)
}

/// Run full reconciliation
pub fn run_reconciliation(
  history: List(NutritionState),
  goals: NutritionGoals,
  recipes: List(ScoredRecipe),
  tolerance_pct: Float,
  suggestion_limit: Int,
  date: String,
) -> ReconciliationResult {
  let avg_consumed = average_nutrition_history(history)
  let deviation = calculate_deviation(goals, avg_consumed)
  let within_tolerance = deviation_is_within_tolerance(deviation, tolerance_pct)
  let plan = generate_adjustments(deviation, recipes, suggestion_limit)

  ReconciliationResult(
    date: date,
    average_consumed: avg_consumed,
    goals: goals,
    deviation: deviation,
    plan: plan,
    within_tolerance: within_tolerance,
  )
}

/// Score a recipe for how well it addresses a nutritional deviation
pub fn score_recipe_for_deviation(
  deviation: DeviationResult,
  macros: Macros,
) -> Float {
  let total_deviation =
    float.absolute_value(deviation.protein_pct)
    +. float.absolute_value(deviation.fat_pct)
    +. float.absolute_value(deviation.carbs_pct)

  case total_deviation <. 5.0 {
    True -> 0.1
    False -> {
      case
        deviation.protein_pct >. 0.0
        && deviation.fat_pct >. 0.0
        && deviation.carbs_pct >. 0.0
      {
        True -> 0.1
        False -> {
          let score = calculate_base_score(deviation, macros)
          let score = apply_protein_scoring(deviation, macros, score)
          let score = apply_fat_scoring(deviation, macros, score)
          let score = apply_carb_scoring(deviation, macros, score)
          score |> float.clamp(0.0, 1.0)
        }
      }
    }
  }
}

fn calculate_base_score(deviation: DeviationResult, macros: Macros) -> Float {
  let protein_deficit = deviation.protein_pct <. 0.0
  let fat_deficit = deviation.fat_pct <. 0.0
  let carbs_deficit = deviation.carbs_pct <. 0.0

  let deficit_count = case protein_deficit, fat_deficit, carbs_deficit {
    True, True, True -> 3
    True, True, False | True, False, True | False, True, True -> 2
    True, False, False | False, True, False | False, False, True -> 1
    False, False, False -> 0
  }

  let total_macros = macros.protein +. macros.fat +. macros.carbs

  case deficit_count > 0 && total_macros >. 0.0 {
    True -> {
      let normalized = float.min(total_macros /. 100.0, 1.0)
      0.1 *. normalized
    }
    False -> 0.0
  }
}

fn apply_protein_scoring(
  deviation: DeviationResult,
  macros: Macros,
  current_score: Float,
) -> Float {
  case deviation.protein_pct <. 0.0 && macros.protein >. 0.0 {
    True -> {
      let protein_score = float.min(macros.protein /. 40.0, 1.0)
      current_score +. 0.5 *. protein_score
    }
    False -> current_score
  }
}

fn apply_fat_scoring(
  deviation: DeviationResult,
  macros: Macros,
  current_score: Float,
) -> Float {
  case deviation.fat_pct <. 0.0 && macros.fat >. 0.0 {
    True -> {
      let fat_score = float.min(macros.fat /. 25.0, 1.0)
      current_score +. 0.25 *. fat_score
    }
    False -> {
      case deviation.fat_pct >. 10.0 && macros.fat >. 20.0 {
        True -> current_score -. 0.1
        False -> current_score
      }
    }
  }
}

fn apply_carb_scoring(
  deviation: DeviationResult,
  macros: Macros,
  current_score: Float,
) -> Float {
  case deviation.carbs_pct <. 0.0 && macros.carbs >. 0.0 {
    True -> {
      let carbs_score =
        float.min(macros.carbs /. nutrition_constants.daily_carbs_target, 1.0)
      current_score +. 0.25 *. carbs_score
    }
    False -> {
      case deviation.carbs_pct >. 10.0 && macros.carbs >. 30.0 {
        True -> current_score -. 0.1
        False -> current_score
      }
    }
  }
}

/// Select top recipes by score against a deviation
pub fn select_top_recipes(
  deviation: DeviationResult,
  recipes: List(ScoredRecipe),
  limit: Int,
) -> List(RecipeSuggestion) {
  case recipes {
    [] -> []
    _ -> {
      let scored =
        list.map(recipes, fn(r) {
          let score = score_recipe_for_deviation(deviation, r.macros)
          #(r, score)
        })

      let sorted =
        list.sort(scored, fn(a, b) {
          let #(_, score_a) = a
          let #(_, score_b) = b
          float.compare(score_b, score_a)
        })

      let limited = list.take(sorted, limit)

      list.map(limited, fn(item) {
        let #(recipe, score) = item
        RecipeSuggestion(
          recipe_name: recipe.name,
          reason: generate_reason(deviation, recipe.macros),
          score: score,
        )
      })
    }
  }
}

/// Generate a human-readable reason for recipe suggestion
pub fn generate_reason(deviation: DeviationResult, macros: Macros) -> String {
  case deviation.protein_pct <. -10.0 && macros.protein >. 20.0 {
    True -> "High protein to address deficit"
    False -> {
      case deviation.carbs_pct <. -10.0 && macros.carbs >. 30.0 {
        True -> "Good carbs to address deficit"
        False -> {
          case deviation.fat_pct <. -10.0 && macros.fat >. 15.0 {
            True -> "Healthy fats to address deficit"
            False -> "Balanced macros"
          }
        }
      }
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float
