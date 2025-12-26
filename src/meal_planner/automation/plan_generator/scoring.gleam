//// Recipe Scoring Logic
////
//// Implements nutritional alignment scoring:
//// - Protein alignment to daily targets
//// - Calorie alignment to daily targets
//// - Macro balance scoring
//// - Weight validation

import gleam/list
import meal_planner/automation/plan_generator/types.{
  type GenerationError, type NutritionWeights, type ScoredRecipe, InvalidWeights,
  NutritionWeights, ScoredRecipe,
}
import meal_planner/types/macros.{type Macros}
import meal_planner/types/recipe.{type Recipe}

/// Default nutrition scoring weights
pub const default_weights: NutritionWeights = NutritionWeights(
  protein_weight: 0.4,
  calorie_weight: 0.4,
  balance_weight: 0.2,
)

/// Score all recipes by nutritional alignment to target macros
pub fn score_recipes(
  recipes: List(Recipe),
  target: Macros,
  weights: NutritionWeights,
) -> List(ScoredRecipe) {
  list.map(recipes, fn(recipe) { score_recipe(recipe, target, weights) })
}

/// Score a single recipe by nutritional alignment
///
/// ## Scoring Components
/// 1. Protein score: How close to daily protein target (per meal)
/// 2. Calorie score: How close to daily calorie target (per meal)
/// 3. Balance score: How balanced are the macro ratios
///
/// Each component is scored 0.0-1.0 and weighted
pub fn score_recipe(
  recipe: Recipe,
  target: Macros,
  weights: NutritionWeights,
) -> ScoredRecipe {
  let macros = recipe.macros

  // Calculate individual scores
  let protein_score = score_protein_alignment(macros.protein, target.protein)
  let calorie_score =
    score_calorie_alignment(macros.calories(macros), macros.calories(target))
  let balance_score = score_macro_balance(macros)

  // Calculate weighted total score
  let total_score =
    { protein_score *. weights.protein_weight }
    +. { calorie_score *. weights.calorie_weight }
    +. { balance_score *. weights.balance_weight }

  ScoredRecipe(
    recipe: recipe,
    score: total_score,
    protein_score: protein_score,
    calorie_score: calorie_score,
    balance_score: balance_score,
  )
}

/// Score protein alignment (0.0 = far from target, 1.0 = perfect match)
///
/// Uses Gaussian scoring: score = exp(-(diff/target)^2 / (2 * sigma^2))
/// Peaks at 1.0 when protein matches target, decays for deviation
fn score_protein_alignment(actual: Float, target: Float) -> Float {
  case target <=. 0.0 {
    True -> 0.5
    // No target, neutral score
    False -> {
      let per_meal_target = target /. 3.0
      // Assume 3 meals per day
      let deviation = actual -. per_meal_target
      let normalized_dev = deviation /. per_meal_target
      let sigma = 0.5
      // Controls spread (50% deviation = ~0.6 score)
      let exponent =
        0.0 -. { normalized_dev *. normalized_dev } /. { 2.0 *. sigma *. sigma }
      float_exp(exponent)
    }
  }
}

/// Score calorie alignment (0.0 = far from target, 1.0 = perfect match)
fn score_calorie_alignment(actual: Float, target: Float) -> Float {
  case target <=. 0.0 {
    True -> 0.5
    False -> {
      let per_meal_target = target /. 3.0
      let deviation = actual -. per_meal_target
      let normalized_dev = deviation /. per_meal_target
      let sigma = 0.4
      // Slightly stricter than protein
      let exponent =
        0.0 -. { normalized_dev *. normalized_dev } /. { 2.0 *. sigma *. sigma }
      float_exp(exponent)
    }
  }
}

/// Score macro balance (0.0 = unbalanced, 1.0 = perfect ratios)
///
/// Checks if macros follow healthy ratios:
/// - Protein: 25-35% of calories
/// - Fat: 25-35% of calories
/// - Carbs: 35-45% of calories
fn score_macro_balance(macros: Macros) -> Float {
  let total_cals = macros.calories(macros)
  case total_cals <=. 0.0 {
    True -> 0.0
    False -> {
      let protein_ratio = { macros.protein *. 4.0 } /. total_cals
      let fat_ratio = { macros.fat *. 9.0 } /. total_cals
      let carb_ratio = { macros.carbs *. 4.0 } /. total_cals

      let protein_ok = protein_ratio >=. 0.25 && protein_ratio <=. 0.35
      let fat_ok = fat_ratio >=. 0.25 && fat_ratio <=. 0.35
      let carb_ok = carb_ratio >=. 0.35 && carb_ratio <=. 0.45

      case protein_ok, fat_ok, carb_ok {
        True, True, True -> 1.0
        True, True, False | True, False, True | False, True, True -> 0.7
        True, False, False | False, True, False | False, False, True -> 0.4
        False, False, False -> 0.0
      }
    }
  }
}

/// Validate nutrition weights sum to 1.0 (with small tolerance)
pub fn validate_weights(
  weights: NutritionWeights,
) -> Result(Nil, GenerationError) {
  let sum =
    weights.protein_weight +. weights.calorie_weight +. weights.balance_weight
  let tolerance = 0.01

  case float_abs(sum -. 1.0) <. tolerance {
    True -> Ok(Nil)
    False -> Error(InvalidWeights)
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Absolute value for floats
fn float_abs(x: Float) -> Float {
  case x <. 0.0 {
    True -> 0.0 -. x
    False -> x
  }
}

/// Exponential function approximation
/// For scoring purposes, we use a simple polynomial approximation
/// e^x ≈ 1 + x + x²/2 + x³/6 for small x
fn float_exp(x: Float) -> Float {
  case x <. -3.0 {
    True -> 0.0
    // Very small, approximate as 0
    False ->
      case x >. 3.0 {
        True -> 1.0
        // Cap at 1.0 for scoring
        False -> {
          // Taylor series approximation
          let x2 = x *. x
          let x3 = x2 *. x
          let result = 1.0 +. x +. { x2 /. 2.0 } +. { x3 /. 6.0 }
          case result <. 0.0 {
            True -> 0.0
            False ->
              case result >. 1.0 {
                True -> 1.0
                False -> result
              }
          }
        }
      }
  }
}
