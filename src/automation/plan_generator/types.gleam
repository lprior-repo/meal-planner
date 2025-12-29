//// Plan Generator Types
////
//// Type definitions for meal plan generation:
//// - DietaryPreferences: Recipe filtering criteria
//// - ScoredRecipe: Recipe with nutritional alignment scores
//// - RecipePool: Categorized recipes by meal type
//// - NutritionWeights: Scoring weight configuration
//// - GenerationError: Error types for plan generation

import gleam/option.{type Option}
import meal_planner/types/recipe.{type FodmapLevel, type Recipe}

/// Dietary preference filters for recipe selection
pub type DietaryPreferences {
  DietaryPreferences(
    /// Require recipes to be Vertical Diet compliant
    require_vertical_diet: Bool,
    /// Maximum FODMAP level allowed (None = no restriction)
    max_fodmap_level: Option(FodmapLevel),
    /// Minimum protein per serving in grams (None = no minimum)
    min_protein_per_serving: Option(Float),
    /// Maximum calories per serving (None = no maximum)
    max_calories_per_serving: Option(Float),
  )
}

/// Scored recipe with nutritional alignment metrics
pub type ScoredRecipe {
  ScoredRecipe(
    recipe: Recipe,
    /// Overall nutritional score (0.0 to 1.0, higher is better)
    score: Float,
    /// Individual component scores for debugging
    protein_score: Float,
    calorie_score: Float,
    balance_score: Float,
  )
}

/// Recipe pool categorized by meal type
pub type RecipePool {
  RecipePool(
    breakfasts: List(ScoredRecipe),
    lunches: List(ScoredRecipe),
    dinners: List(ScoredRecipe),
  )
}

/// Nutrition scoring weights (must sum to 1.0)
pub type NutritionWeights {
  NutritionWeights(
    /// Weight for protein target alignment (0.0-1.0)
    protein_weight: Float,
    /// Weight for calorie target alignment (0.0-1.0)
    calorie_weight: Float,
    /// Weight for macro balance (0.0-1.0)
    balance_weight: Float,
  )
}

/// Error types for plan generation
pub type GenerationError {
  /// Not enough recipes in one or more categories
  InsufficientRecipes(category: String, required: Int, available: Int)
  /// No recipes pass the dietary preference filters
  NoRecipesMatchPreferences
  /// Invalid nutrition weights (don't sum to 1.0)
  InvalidWeights
}
