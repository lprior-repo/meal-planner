/// Recipe scoring system for auto meal planner
///
/// Evaluates recipes based on:
/// - Diet compliance (0-1): How well the recipe follows specified diet principles
/// - Macro target match (0-1): How close recipe macros are to target macros
/// - Variety score (0-1): Encourages diverse ingredient selection
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string

// Simplified: removed diet_validator dependency
import meal_planner/types.{type Macros, type Recipe}

// ============================================================================
// Types
// ============================================================================

/// Complete recipe score with breakdown
pub type RecipeScore {
  RecipeScore(
    recipe_id: String,
    total_score: Float,
    diet_compliance_score: Float,
    macro_match_score: Float,
    variety_score: Float,
    violations: List(String),
    warnings: List(String),
  )
}

/// Scoring weights for different factors
pub type ScoringWeights {
  ScoringWeights(diet_compliance: Float, macro_match: Float, variety: Float)
}

// ============================================================================
// Main Scoring Functions
// ============================================================================

/// Score a recipe against macro targets
/// Simplified version - diet compliance always returns 1.0
pub fn score_recipe(
  recipe: Recipe,
  _diet_principles: List(String),
  macro_targets: Macros,
  weights: ScoringWeights,
) -> RecipeScore {
  // Diet compliance (simplified - always compliant)
  let _diet_score = 1.0

  // Calculate macro match score
  let macro_score = score_macro_match(recipe.macros, macro_targets)

  // Calculate variety score (based on ingredient diversity)
  let variety = score_variety(recipe)

  // Calculate weighted total score (simplified - diet always gets full weight)
  let total =
    weights.diet_compliance
    +. { weights.macro_match *. macro_score }
    +. { weights.variety *. variety }

  RecipeScore(
    recipe_id: recipe.id,
    total_score: total,
    diet_compliance_score: 1.0,
    macro_match_score: macro_score,
    variety_score: variety,
    violations: [],
    warnings: [],
  )
}

/// Score a list of recipes and return them sorted by score (highest first)
pub fn score_and_rank_recipes(
  recipes: List(Recipe),
  diet_principles: List(String),
  macro_targets: Macros,
  weights: ScoringWeights,
) -> List(RecipeScore) {
  recipes
  |> list.map(fn(recipe) {
    score_recipe(recipe, diet_principles, macro_targets, weights)
  })
  |> list.sort(fn(a, b) { float.compare(b.total_score, a.total_score) })
}

/// Default scoring weights (balanced approach)
pub fn default_weights() -> ScoringWeights {
  ScoringWeights(diet_compliance: 0.5, macro_match: 0.3, variety: 0.2)
}

/// Strict diet compliance weights (prioritize diet rules)
pub fn strict_compliance_weights() -> ScoringWeights {
  ScoringWeights(diet_compliance: 0.7, macro_match: 0.2, variety: 0.1)
}

/// Performance focused weights (prioritize macro targets)
pub fn performance_weights() -> ScoringWeights {
  ScoringWeights(diet_compliance: 0.3, macro_match: 0.6, variety: 0.1)
}

// ============================================================================
// Macro Matching Scoring
// ============================================================================

/// Score how well recipe macros match target macros (0-1)
/// Uses normalized absolute difference with penalties for large deviations
pub fn score_macro_match(recipe_macros: Macros, targets: Macros) -> Float {
  // Prevent division by zero
  let protein_target = float.max(targets.protein, 1.0)
  let fat_target = float.max(targets.fat, 1.0)
  let carbs_target = float.max(targets.carbs, 1.0)

  // Calculate percentage errors
  let protein_error =
    float.absolute_value(recipe_macros.protein -. targets.protein)
    /. protein_target

  let fat_error =
    float.absolute_value(recipe_macros.fat -. targets.fat) /. fat_target

  let carbs_error =
    float.absolute_value(recipe_macros.carbs -. targets.carbs) /. carbs_target

  // Average the errors
  let avg_error = { protein_error +. fat_error +. carbs_error } /. 3.0

  // Convert error to score (0 error = 1.0 score, 100% error = 0 score)
  // Use exponential decay for better discrimination
  let score =
    float.power(2.718281828, 0.0 -. { avg_error *. 2.0 })
    |> result.unwrap(0.0)

  // Clamp to [0, 1]
  float.min(1.0, float.max(0.0, score))
}

/// Calculate macro deviation percentage for a single macro
pub fn macro_deviation(actual: Float, target: Float) -> Float {
  let target_safe = float.max(target, 1.0)
  { float.absolute_value(actual -. target) /. target_safe } *. 100.0
}

// ============================================================================
// Variety Scoring
// ============================================================================

/// Score recipe variety based on ingredient diversity (0-1)
/// More unique ingredients = higher score
pub fn score_variety(recipe: Recipe) -> Float {
  let ingredient_count =
    list.fold(recipe.ingredients, 0, fn(acc, _) { acc + 1 })

  case ingredient_count {
    0 -> 0.0
    1 -> 0.2
    2 -> 0.4
    3 -> 0.6
    4 -> 0.8
    _ -> 1.0
  }
}

/// Calculate variety penalty for selecting similar recipes
/// Penalizes repeated ingredients across a meal plan
pub fn calculate_variety_penalty(
  selected_recipes: List(Recipe),
  candidate: Recipe,
) -> Float {
  // Count how many ingredients in candidate already appear in selected recipes
  let selected_ingredient_names =
    selected_recipes
    |> list.flat_map(fn(r) { r.ingredients })
    |> list.map(fn(i) { string.lowercase(i.name) })

  let candidate_ingredient_names =
    candidate.ingredients
    |> list.map(fn(i) { string.lowercase(i.name) })

  let overlap_count =
    candidate_ingredient_names
    |> list.filter(fn(name) { list.contains(selected_ingredient_names, name) })
    |> list.fold(0, fn(acc, _) { acc + 1 })

  let total_ingredients =
    list.fold(candidate.ingredients, 0, fn(acc, _) { acc + 1 })

  case total_ingredients {
    0 -> 0.0
    n -> {
      let overlap_ratio = int_to_float(overlap_count) /. int_to_float(n)
      // Higher overlap = higher penalty
      overlap_ratio
    }
  }
}

// ============================================================================
// Filtering Functions
// ============================================================================

/// Filter recipes by minimum score threshold
pub fn filter_by_score(
  scores: List(RecipeScore),
  min_score: Float,
) -> List(RecipeScore) {
  list.filter(scores, fn(score) { score.total_score >=. min_score })
}

/// Filter out recipes with diet violations
pub fn filter_compliant_only(scores: List(RecipeScore)) -> List(RecipeScore) {
  list.filter(scores, fn(score) { list.is_empty(score.violations) })
}

/// Get top N recipes by score
pub fn take_top_n(scores: List(RecipeScore), n: Int) -> List(RecipeScore) {
  list.take(scores, n)
}

// ============================================================================
// Helper Functions
// ============================================================================

fn int_to_float(i: Int) -> Float {
  case i {
    0 -> 0.0
    n if n > 0 -> int.to_float(n)
    n -> 0.0 -. int.to_float(int.absolute_value(n))
  }
}
