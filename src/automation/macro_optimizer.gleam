//// Macro Optimizer - Recipe Scoring and Selection Adjustment
////
//// Scores recipes by macro alignment and adjusts selections to hit daily targets
//// within ±10% tolerance. Part of the Autonomous Nutritional Control Plane.
////
//// ## Algorithm
//// 1. Score each recipe by how well its macros align with target ratios
//// 2. Calculate current day's macro totals from selected recipes
//// 3. Identify gaps (protein/fat/carbs over or under target by >10%)
//// 4. Suggest recipe swaps to bring macros within ±10% range
////
//// ## Example
////
//// ```gleam
//// import meal_planner/automation/macro_optimizer
//// import meal_planner/types/macros
//// import meal_planner/types/recipe
////
//// let target = macros.Macros(protein: 150.0, fat: 67.0, carbs: 200.0)
//// let recipes = [recipe1, recipe2, recipe3]
////
//// // Score recipes
//// let scored = macro_optimizer.score_recipes(recipes, target)
////
//// // Check if current selection meets targets
//// let current = [selected1, selected2, selected3]
//// case macro_optimizer.within_tolerance(current, target) {
////   True -> // Good to go
////   False -> {
////     // Get adjustment suggestions
////     let suggestions = macro_optimizer.suggest_adjustments(
////       current: current,
////       available: recipes,
////       target: target,
////     )
////   }
//// }
//// ```

import gleam/list
import gleam/order.{type Order}
import meal_planner/types/macros.{type Macros}
import meal_planner/types/recipe.{type MealPlanRecipe}

// ============================================================================
// Types
// ============================================================================

/// Scored recipe with alignment metrics
pub type ScoredRecipe {
  ScoredRecipe(
    recipe: MealPlanRecipe,
    /// Overall macro alignment score (0.0 to 1.0, higher is better)
    score: Float,
    /// How well protein aligns with target (0.0 to 1.0)
    protein_score: Float,
    /// How well fat aligns with target (0.0 to 1.0)
    fat_score: Float,
    /// How well carbs align with target (0.0 to 1.0)
    carbs_score: Float,
  )
}

/// Macro gap analysis result
pub type MacroGaps {
  MacroGaps(
    /// Protein gap in grams (negative = under, positive = over)
    protein_gap: Float,
    /// Fat gap in grams
    fat_gap: Float,
    /// Carbs gap in grams
    carbs_gap: Float,
    /// Is protein within ±10% of target?
    protein_ok: Bool,
    /// Is fat within ±10% of target?
    fat_ok: Bool,
    /// Is carbs within ±10% of target?
    carbs_ok: Bool,
  )
}

/// Recipe swap suggestion to improve macro alignment
pub type SwapSuggestion {
  SwapSuggestion(
    /// Recipe to remove from current selection
    remove: MealPlanRecipe,
    /// Recipe to add as replacement
    add: MealPlanRecipe,
    /// Expected improvement in macro alignment (0.0 to 1.0)
    improvement_score: Float,
    /// Brief reason for the swap
    reason: String,
  )
}

/// Result of adjustment suggestions
pub type AdjustmentResult {
  AdjustmentResult(
    /// Current macro gaps before adjustments
    current_gaps: MacroGaps,
    /// Suggested recipe swaps (ordered by improvement_score, descending)
    suggestions: List(SwapSuggestion),
    /// Number of macros currently out of tolerance
    macros_out_of_tolerance: Int,
  )
}

// ============================================================================
// Constants
// ============================================================================

/// Tolerance for macro targets (±10%)
const tolerance: Float = 0.1

/// Minimum score improvement to suggest a swap
const min_improvement: Float = 0.05

// ============================================================================
// Public API
// ============================================================================

/// Score a list of recipes by macro alignment to target
///
/// Each recipe gets scored 0.0-1.0 based on how well its macros
/// align with the target macro profile. Higher scores = better match.
///
/// ## Scoring Method
/// Uses Gaussian scoring for each macro component, then averages:
/// - score = exp(-(actual - target)^2 / (2 * sigma^2))
/// - sigma controls tolerance (larger = more forgiving)
pub fn score_recipes(
  recipes: List(MealPlanRecipe),
  target: Macros,
) -> List(ScoredRecipe) {
  list.map(recipes, fn(recipe) { score_recipe(recipe, target) })
}

/// Score a single recipe by macro alignment
fn score_recipe(recipe: MealPlanRecipe, target: Macros) -> ScoredRecipe {
  let recipe_macros = recipe.recipe_macros_per_serving(recipe)

  let protein_score =
    score_macro_component(recipe_macros.protein, target.protein)
  let fat_score = score_macro_component(recipe_macros.fat, target.fat)
  let carbs_score = score_macro_component(recipe_macros.carbs, target.carbs)

  // Overall score is average of component scores
  let total_score = { protein_score +. fat_score +. carbs_score } /. 3.0

  ScoredRecipe(
    recipe: recipe,
    score: total_score,
    protein_score: protein_score,
    fat_score: fat_score,
    carbs_score: carbs_score,
  )
}

/// Score a single macro component (0.0 = poor match, 1.0 = perfect match)
///
/// Uses Gaussian function: exp(-(diff/target)^2 / (2 * sigma^2))
fn score_macro_component(actual: Float, target: Float) -> Float {
  case target <=. 0.0 {
    True -> 0.5
    // No target, neutral score
    False -> {
      let deviation = actual -. target
      let normalized_dev = deviation /. target
      let sigma = 0.5
      // 50% deviation gets ~0.6 score
      let exponent =
        0.0 -. { normalized_dev *. normalized_dev } /. { 2.0 *. sigma *. sigma }
      float_exp(exponent)
    }
  }
}

/// Check if current recipe selection meets target macros within ±10%
///
/// Returns True if all macros (protein, fat, carbs) are within
/// ±10% of their respective targets.
pub fn within_tolerance(current: List(MealPlanRecipe), target: Macros) -> Bool {
  let gaps = calculate_gaps(current, target)
  gaps.protein_ok && gaps.fat_ok && gaps.carbs_ok
}

/// Calculate macro gaps between current selection and target
///
/// Gaps are in grams:
/// - Negative gap = under target
/// - Positive gap = over target
/// - Zero gap = exactly on target
///
/// Also indicates if each macro is within ±10% tolerance.
pub fn calculate_gaps(
  current: List(MealPlanRecipe),
  target: Macros,
) -> MacroGaps {
  let current_macros = sum_recipe_macros(current)

  let protein_gap = current_macros.protein -. target.protein
  let fat_gap = current_macros.fat -. target.fat
  let carbs_gap = current_macros.carbs -. target.carbs

  let protein_ok = is_within_tolerance(current_macros.protein, target.protein)
  let fat_ok = is_within_tolerance(current_macros.fat, target.fat)
  let carbs_ok = is_within_tolerance(current_macros.carbs, target.carbs)

  MacroGaps(
    protein_gap: protein_gap,
    fat_gap: fat_gap,
    carbs_gap: carbs_gap,
    protein_ok: protein_ok,
    fat_ok: fat_ok,
    carbs_ok: carbs_ok,
  )
}

/// Suggest recipe swaps to bring macros within ±10% tolerance
///
/// Analyzes current selection vs target, identifies macros that are
/// out of tolerance, and suggests swaps from available recipes.
///
/// Returns suggestions ordered by expected improvement (best first).
pub fn suggest_adjustments(
  current current: List(MealPlanRecipe),
  available available: List(MealPlanRecipe),
  target target: Macros,
) -> AdjustmentResult {
  let gaps = calculate_gaps(current, target)

  // Count macros out of tolerance
  let out_count = count_macros_out_of_tolerance(gaps)

  // If everything is good, return empty suggestions
  case out_count {
    0 ->
      AdjustmentResult(
        current_gaps: gaps,
        suggestions: [],
        macros_out_of_tolerance: 0,
      )
    _ -> {
      // Generate swap suggestions
      let suggestions =
        generate_swap_suggestions(current, available, gaps, target)

      AdjustmentResult(
        current_gaps: gaps,
        suggestions: suggestions,
        macros_out_of_tolerance: out_count,
      )
    }
  }
}

/// Get the top N recipes by macro alignment score
///
/// Useful for selecting the best recipes from a scored pool.
pub fn select_top_recipes(
  scored: List(ScoredRecipe),
  count: Int,
) -> List(MealPlanRecipe) {
  scored
  |> list.sort(fn(a, b) { compare_scores(b.score, a.score) })
  |> list.take(count)
  |> list.map(fn(sr) { sr.recipe })
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Sum macros from a list of recipes
fn sum_recipe_macros(recipes: List(MealPlanRecipe)) -> Macros {
  recipes
  |> list.map(fn(r) { recipe.recipe_macros_per_serving(r) })
  |> list.fold(macros.zero(), macros.add)
}

/// Check if actual value is within ±10% of target
fn is_within_tolerance(actual: Float, target: Float) -> Bool {
  case target <=. 0.0 {
    True -> True
    // No target, always ok
    False -> {
      let ratio = actual /. target
      ratio >=. { 1.0 -. tolerance } && ratio <=. { 1.0 +. tolerance }
    }
  }
}

/// Count how many macros are out of tolerance
fn count_macros_out_of_tolerance(gaps: MacroGaps) -> Int {
  let protein_count = case gaps.protein_ok {
    True -> 0
    False -> 1
  }
  let fat_count = case gaps.fat_ok {
    True -> 0
    False -> 1
  }
  let carbs_count = case gaps.carbs_ok {
    True -> 0
    False -> 1
  }

  protein_count + fat_count + carbs_count
}

/// Generate swap suggestions to improve macro alignment
fn generate_swap_suggestions(
  current: List(MealPlanRecipe),
  available: List(MealPlanRecipe),
  gaps: MacroGaps,
  target: Macros,
) -> List(SwapSuggestion) {
  // For each recipe in current selection
  let suggestions =
    list.flat_map(current, fn(current_recipe) {
      // Try swapping with each available recipe
      list.filter_map(available, fn(candidate) {
        // Don't suggest swapping with itself
        case recipe.recipe_id(current_recipe) == recipe.recipe_id(candidate) {
          True -> Error(Nil)
          False -> {
            // Calculate improvement if we made this swap
            case
              evaluate_swap(current, current_recipe, candidate, gaps, target)
            {
              Ok(suggestion) -> Ok(suggestion)
              Error(_) -> Error(Nil)
            }
          }
        }
      })
    })

  // Sort by improvement score (best first)
  suggestions
  |> list.sort(fn(a, b) {
    compare_scores(b.improvement_score, a.improvement_score)
  })
}

/// Evaluate a potential recipe swap
fn evaluate_swap(
  current: List(MealPlanRecipe),
  remove: MealPlanRecipe,
  add: MealPlanRecipe,
  current_gaps: MacroGaps,
  target: Macros,
) -> Result(SwapSuggestion, Nil) {
  // Create new selection with the swap
  let new_selection =
    current
    |> list.filter(fn(r) { recipe.recipe_id(r) != recipe.recipe_id(remove) })
    |> list.prepend(add)

  // Calculate new gaps
  let new_gaps = calculate_gaps(new_selection, target)

  // Calculate improvement score
  let current_error = calculate_total_error(current_gaps)
  let new_error = calculate_total_error(new_gaps)
  let improvement = current_error -. new_error

  // Only suggest if improvement is significant
  case improvement >. min_improvement {
    False -> Error(Nil)
    True -> {
      let reason = generate_swap_reason(current_gaps, new_gaps)
      Ok(SwapSuggestion(
        remove: remove,
        add: add,
        improvement_score: improvement,
        reason: reason,
      ))
    }
  }
}

/// Calculate total error from target (sum of absolute gap percentages)
fn calculate_total_error(gaps: MacroGaps) -> Float {
  let protein_error = float_abs(gaps.protein_gap)
  let fat_error = float_abs(gaps.fat_gap)
  let carbs_error = float_abs(gaps.carbs_gap)

  protein_error +. fat_error +. carbs_error
}

/// Generate human-readable reason for swap suggestion
fn generate_swap_reason(current: MacroGaps, new: MacroGaps) -> String {
  let protein_improved =
    float_abs(new.protein_gap) <. float_abs(current.protein_gap)
  let fat_improved = float_abs(new.fat_gap) <. float_abs(current.fat_gap)
  let carbs_improved = float_abs(new.carbs_gap) <. float_abs(current.carbs_gap)

  case protein_improved, fat_improved, carbs_improved {
    True, True, True -> "Improves all macros"
    True, True, False -> "Improves protein and fat"
    True, False, True -> "Improves protein and carbs"
    False, True, True -> "Improves fat and carbs"
    True, False, False -> "Improves protein"
    False, True, False -> "Improves fat"
    False, False, True -> "Improves carbs"
    False, False, False -> "Balances overall macros"
  }
}

/// Compare float scores for sorting
fn compare_scores(a: Float, b: Float) -> Order {
  case a >. b {
    True -> order.Gt
    False ->
      case a <. b {
        True -> order.Lt
        False -> order.Eq
      }
  }
}

/// Absolute value for floats
fn float_abs(x: Float) -> Float {
  case x <. 0.0 {
    True -> 0.0 -. x
    False -> x
  }
}

/// Exponential function approximation for scoring
/// Uses Taylor series for small x: e^x ≈ 1 + x + x²/2 + x³/6
fn float_exp(x: Float) -> Float {
  case x <. -3.0 {
    True -> 0.0
    // Very small
    False ->
      case x >. 3.0 {
        True -> 1.0
        // Cap at 1.0
        False -> {
          let x2 = x *. x
          let x3 = x2 *. x
          let result = 1.0 +. x +. { x2 /. 2.0 } +. { x3 /. 6.0 }
          clamp_float(result, 0.0, 1.0)
        }
      }
  }
}

/// Clamp a float to min/max range
fn clamp_float(x: Float, min: Float, max: Float) -> Float {
  case x <. min {
    True -> min
    False ->
      case x >. max {
        True -> max
        False -> x
      }
  }
}
