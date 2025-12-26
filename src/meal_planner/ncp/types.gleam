/// NCP (Nutrition Control Plane) type definitions
///
/// This module contains all type definitions used across the NCP subsystem
/// for nutrition tracking, reconciliation, and analysis.
import meal_planner/types/macros.{type Macros}

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
