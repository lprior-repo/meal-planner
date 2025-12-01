/// NCP (Nutrition Control Plane) types for nutrition tracking and reconciliation
import gleam/float
import gleam/int
import gleam/list
import gleam/string
import meal_planner/types.{type Macros}

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

/// Get nutrition history for specified number of days
pub fn get_nutrition_history(_days: Int) -> Result(List(NutritionState), String) {
  // For now, return empty list
  // In full implementation, this would query the database
  Ok([])
}

/// Get default nutrition goals
pub fn get_default_goals() -> NutritionGoals {
  NutritionGoals(
    daily_protein: 180.0,
    daily_fat: 60.0,
    daily_carbs: 250.0,
    daily_calories: 2500.0,
  )
}

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
  let avg_consumed = average_nutrition_history(history)

  // Calculate deviation from goals
  let deviation = calculate_deviation(goals, avg_consumed)

  // Check if within tolerance
  let within_tolerance = deviation_is_within_tolerance(deviation, tolerance_pct)

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

/// Calculate average nutrition history - matches Go ncp/history.go AverageNutritionHistory
pub fn average_nutrition_history(history: List(NutritionState)) -> NutritionData {
  case history {
    [] -> NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)
    _ -> {
      let count = int_to_float(list.length(history))
      let sum =
        list.fold(
          history,
          NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0),
          fn(acc, state) {
            NutritionData(
              protein: acc.protein +. state.consumed.protein,
              fat: acc.fat +. state.consumed.fat,
              carbs: acc.carbs +. state.consumed.carbs,
              calories: acc.calories +. state.consumed.calories,
            )
          },
        )

      NutritionData(
        protein: sum.protein /. count,
        fat: sum.fat /. count,
        carbs: sum.carbs /. count,
        calories: sum.calories /. count,
      )
    }
  }
}

/// Format status output for display - matches Go cli.go FormatStatusOutput
pub fn format_status_output(result: ReconciliationResult) -> String {
  let header =
    "═══════════════════════════════════════════════\n"
    <> "           NCP NUTRITION STATUS REPORT          \n"
    <> "═══════════════════════════════════════════════\n\n"
    <> "Date: "
    <> result.date
    <> "\n\n"

  let macro_header =
    "📊 MACRO COMPARISON\n"
    <> "───────────────────────────────────────────────\n"
    <> "           Goal      Actual    Deviation\n"

  let protein_line =
    "Protein:   "
    <> pad_float(result.goals.daily_protein, 6, 1)
    <> "g   "
    <> pad_float(result.average_consumed.protein, 6, 1)
    <> "g   "
    <> format_deviation(result.deviation.protein_pct)
    <> "\n"

  let fat_line =
    "Fat:       "
    <> pad_float(result.goals.daily_fat, 6, 1)
    <> "g   "
    <> pad_float(result.average_consumed.fat, 6, 1)
    <> "g   "
    <> format_deviation(result.deviation.fat_pct)
    <> "\n"

  let carbs_line =
    "Carbs:     "
    <> pad_float(result.goals.daily_carbs, 6, 1)
    <> "g   "
    <> pad_float(result.average_consumed.carbs, 6, 1)
    <> "g   "
    <> format_deviation(result.deviation.carbs_pct)
    <> "\n"

  let calories_line =
    "Calories:  "
    <> pad_float(result.goals.daily_calories, 6, 0)
    <> "    "
    <> pad_float(result.average_consumed.calories, 6, 0)
    <> "    "
    <> format_deviation(result.deviation.calories_pct)
    <> "\n\n"

  let status = case result.within_tolerance {
    True -> "✓ STATUS: Within tolerance - On track!\n\n"
    False -> "⚠ STATUS: Outside tolerance - Adjustments recommended\n\n"
  }

  let suggestions = case
    result.within_tolerance || list.is_empty(result.plan.suggestions)
  {
    True -> ""
    False ->
      "📋 RECOMMENDED RECIPES\n"
      <> "───────────────────────────────────────────────\n"
      <> format_suggestions(result.plan.suggestions)
  }

  let footer = "\n═══════════════════════════════════════════════\n"

  header
  <> macro_header
  <> protein_line
  <> fat_line
  <> carbs_line
  <> calories_line
  <> status
  <> suggestions
  <> footer
}

/// Format suggestions list
fn format_suggestions(suggestions: List(RecipeSuggestion)) -> String {
  list.index_map(suggestions, fn(s, i) {
    int.to_string(i + 1)
    <> ". "
    <> s.recipe_name
    <> " (score: "
    <> float_to_string_fixed(s.score, 2)
    <> ")\n"
    <> "   "
    <> s.reason
    <> "\n"
  })
  |> string.concat
}

/// Format reconciliation output for display - matches Go cli.go FormatReconcileOutput
pub fn format_reconcile_output(result: ReconciliationResult) -> String {
  let base = format_status_output(result)

  case result.within_tolerance || list.is_empty(result.plan.suggestions) {
    True -> base
    False ->
      base
      <> "\n🍽️  ADJUSTMENT PLAN\n"
      <> "───────────────────────────────────────────────\n"
      <> "Add the following meals to get back on track:\n\n"
      <> {
        list.map(result.plan.suggestions, fn(s) {
          "  • " <> s.recipe_name <> "\n"
        })
        |> string.concat
      }
      <> "\n"
  }
}

/// Format deviation percentage with sign
fn format_deviation(pct: Float) -> String {
  let sign = case pct >=. 0.0 {
    True -> "+"
    False -> ""
  }
  sign <> float_to_string_fixed(pct, 1) <> "%"
}

/// Pad a float to specified width with given decimal places
fn pad_float(f: Float, width: Int, decimals: Int) -> String {
  let formatted = float_to_string_fixed(f, decimals)
  let padding = width - string.length(formatted)
  case padding > 0 {
    True -> string.repeat(" ", padding) <> formatted
    False -> formatted
  }
}

/// Convert float to string with fixed decimal places
fn float_to_string_fixed(f: Float, decimals: Int) -> String {
  case decimals {
    0 -> int.to_string(float.round(f))
    1 -> float.to_string(int_to_float(float.round(f *. 10.0)) /. 10.0)
    2 -> float.to_string(int_to_float(float.round(f *. 100.0)) /. 100.0)
    _ -> float.to_string(f)
  }
}

/// Convert int to float
@external(erlang, "erlang", "float")
fn int_to_float(n: Int) -> Float

// ============================================================================
// Recipe Scoring and Selection Functions
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
fn calculate_base_score(_deviation: DeviationResult, _macros: Macros) -> Float {
  0.0
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
      let carbs_score = float.min(macros.carbs /. 50.0, 1.0)
      // Normalize: 50g carbs = max score
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
