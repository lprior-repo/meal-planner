//// Nutrition reconciliation and recipe scoring
////
//// Scores recipes and generates adjustment plans to address nutritional deviations

import gleam/float
import gleam/list
import meal_planner/types/macros.{type Macros}
import meal_planner/types/nutrition/goals.{
  type DeviationResult, type NutritionData, type NutritionGoals,
  calculate_deviation, deviation_is_within_tolerance,
}
import meal_planner/types/nutrition/tracking.{
  type NutritionState, average_nutrition_history,
}

// ============================================================================
// Types
// ============================================================================

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

// ============================================================================
// Reconciliation Functions
// ============================================================================

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

// ============================================================================
// Recipe Scoring Functions
// ============================================================================

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
      let carbs_score = float.min(macros.carbs /. 200.0, 1.0)
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
