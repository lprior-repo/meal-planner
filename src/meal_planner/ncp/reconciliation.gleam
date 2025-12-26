/// NCP Reconciliation Module
///
/// Reconciliation logic, adjustment generation, and recipe scoring:
/// - Run full nutrition reconciliation
/// - Generate adjustment plans
/// - Score recipes for nutritional fit
/// - Select top recipe recommendations
import gleam/float
import gleam/list
import meal_planner/ncp/analysis
import meal_planner/ncp/calculations
import meal_planner/ncp/types.{
  type AdjustmentPlan, type DeviationResult, type NutritionGoals,
  type NutritionState, type RecipeSuggestion, type ReconciliationResult,
  type ScoredRecipe, AdjustmentPlan, NutritionGoals, RecipeSuggestion,
  ReconciliationResult,
}
import meal_planner/nutrition_constants
import meal_planner/types/macros.{type Macros}

// ============================================================================
// Default Goals
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
// Reconciliation Functions
// ============================================================================

/// Run full reconciliation - matches Go ncp/reconcile.go RunReconciliation
/// Performs:
/// 1. Calculates average consumption from history
/// 2. Computes deviation from goals
/// 3. Generates recipe suggestions to address deviations
/// 4. Returns comprehensive result
pub fn run_reconciliation(
  history: List(NutritionState),
  goals: NutritionGoals,
  recipes: List(ScoredRecipe),
  tolerance_pct: Float,
  suggestion_limit: Int,
  date: String,
) -> ReconciliationResult {
  // Calculate average consumption from history
  let avg_consumed = analysis.average_nutrition_history(history)

  // Calculate deviation from goals
  let deviation = calculations.calculate_deviation(goals, avg_consumed)

  // Check if within tolerance
  let within_tolerance =
    calculations.deviation_is_within_tolerance(deviation, tolerance_pct)

  // Generate adjustment plan
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

/// Generate adjustment plan - matches Go ncp/generate.go GenerateAdjustments
pub fn generate_adjustments(
  deviation: DeviationResult,
  recipes: List(ScoredRecipe),
  limit: Int,
) -> AdjustmentPlan {
  let suggestions = select_top_recipes(deviation, recipes, limit)
  AdjustmentPlan(deviation: deviation, suggestions: suggestions)
}

// ============================================================================
// Recipe Scoring Functions
// ============================================================================

/// Score a recipe for how well it addresses a nutritional deviation
/// Returns a score from 0.0 to 1.0, where higher scores indicate better fit
/// Prioritizes protein, then considers overall macro balance
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
      // If over on all macros, adding food is bad
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

          score
          |> float.clamp(0.0, 1.0)
        }
      }
    }
  }
}

/// Calculate base score for recipe against deviation
/// Provides a small baseline score (0.0-0.1) for recipes that provide any macros
/// when there's a deficit, encouraging food additions for overall nutritional needs
fn calculate_base_score(deviation: DeviationResult, macros: Macros) -> Float {
  // Calculate how many macros are in deficit
  let protein_deficit = deviation.protein_pct <. 0.0
  let fat_deficit = deviation.fat_pct <. 0.0
  let carbs_deficit = deviation.carbs_pct <. 0.0

  let deficit_count = case protein_deficit, fat_deficit, carbs_deficit {
    True, True, True -> 3
    True, True, False | True, False, True | False, True, True -> 2
    True, False, False | False, True, False | False, False, True -> 1
    False, False, False -> 0
  }

  // Calculate total macros provided by recipe
  let total_macros = macros.protein +. macros.fat +. macros.carbs

  case deficit_count > 0 && total_macros >. 0.0 {
    True -> {
      // Small base score (max 0.1) for providing any nutrition when in deficit
      let normalized = float.min(total_macros /. 100.0, 1.0)
      0.1 *. normalized
    }
    False -> 0.0
  }
}

/// Apply protein scoring (weight: 0.5)
fn apply_protein_scoring(
  deviation: DeviationResult,
  macros: Macros,
  current_score: Float,
) -> Float {
  case deviation.protein_pct <. 0.0 && macros.protein >. 0.0 {
    True -> {
      // Recipe helps address protein deficit
      let protein_score = float.min(macros.protein /. 40.0, 1.0)
      // Normalize: 40g protein = max score
      current_score +. 0.5 *. protein_score
    }
    False -> current_score
  }
}

/// Apply fat scoring (weight: 0.25)
fn apply_fat_scoring(
  deviation: DeviationResult,
  macros: Macros,
  current_score: Float,
) -> Float {
  case deviation.fat_pct <. 0.0 && macros.fat >. 0.0 {
    True -> {
      let fat_score = float.min(macros.fat /. 25.0, 1.0)
      // Normalize: 25g fat = max score
      current_score +. 0.25 *. fat_score
    }
    False -> {
      // Penalize high fat when already over
      case deviation.fat_pct >. 10.0 && macros.fat >. 20.0 {
        True -> current_score -. 0.1
        False -> current_score
      }
    }
  }
}

/// Apply carb scoring (weight: 0.25)
fn apply_carb_scoring(
  deviation: DeviationResult,
  macros: Macros,
  current_score: Float,
) -> Float {
  case deviation.carbs_pct <. 0.0 && macros.carbs >. 0.0 {
    True -> {
      let carbs_score =
        float.min(macros.carbs /. nutrition_constants.daily_carbs_target, 1.0)
      // Normalize: recommended carbs = max score
      current_score +. 0.25 *. carbs_score
    }
    False -> {
      // Penalize high carbs when already over
      case deviation.carbs_pct >. 10.0 && macros.carbs >. 30.0 {
        True -> current_score -. 0.1
        False -> current_score
      }
    }
  }
}

// ============================================================================
// Recipe Selection Functions
// ============================================================================

/// Select top recipes by score against a deviation
pub fn select_top_recipes(
  deviation: DeviationResult,
  recipes: List(ScoredRecipe),
  limit: Int,
) -> List(RecipeSuggestion) {
  case recipes {
    [] -> []
    _ -> {
      // Score all recipes
      let scored =
        list.map(recipes, fn(r) {
          let score = score_recipe_for_deviation(deviation, r.macros)
          #(r, score)
        })

      // Sort by score descending
      let sorted =
        list.sort(scored, fn(a, b) {
          let #(_, score_a) = a
          let #(_, score_b) = b
          float.compare(score_b, score_a)
          // Descending order
        })

      // Take top N
      let limited = list.take(sorted, limit)

      // Convert to suggestions
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
