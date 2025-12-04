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

/// Calculate minimum values across nutrition history
pub fn calculate_min_nutrition(history: List(NutritionState)) -> NutritionData {
  case history {
    [] -> NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)
    [first, ..rest] ->
      list.fold(rest, first.consumed, fn(min_data, state) {
        NutritionData(
          protein: float.min(min_data.protein, state.consumed.protein),
          fat: float.min(min_data.fat, state.consumed.fat),
          carbs: float.min(min_data.carbs, state.consumed.carbs),
          calories: float.min(min_data.calories, state.consumed.calories),
        )
      })
  }
}

/// Calculate maximum values across nutrition history
pub fn calculate_max_nutrition(history: List(NutritionState)) -> NutritionData {
  case history {
    [] -> NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)
    [first, ..rest] ->
      list.fold(rest, first.consumed, fn(max_data, state) {
        NutritionData(
          protein: float.max(max_data.protein, state.consumed.protein),
          fat: float.max(max_data.fat, state.consumed.fat),
          carbs: float.max(max_data.carbs, state.consumed.carbs),
          calories: float.max(max_data.calories, state.consumed.calories),
        )
      })
  }
}

/// Calculate standard deviation for a list of floats
fn calculate_std_dev(values: List(Float), mean: Float) -> Float {
  // Count and calculate variance in one pass
  let #(variance_sum, count) =
    list.fold(values, #(0.0, 0), fn(acc, value) {
      let diff = value -. mean
      #(acc.0 +. { diff *. diff }, acc.1 + 1)
    })

  case count {
    0 -> 0.0
    1 -> 0.0
    n -> {
      let variance = variance_sum /. int_to_float(n)

      case float.square_root(variance) {
        Ok(std_dev) -> std_dev
        Error(_) -> 0.0
      }
    }
  }
}

/// Calculate variability (standard deviation) for each macro in history
pub fn calculate_nutrition_variability(
  history: List(NutritionState),
) -> NutritionData {
  case history {
    [] -> NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0)
    _ -> {
      let avg = average_nutrition_history(history)

      let proteins = list.map(history, fn(s) { s.consumed.protein })
      let fats = list.map(history, fn(s) { s.consumed.fat })
      let carbs_list = list.map(history, fn(s) { s.consumed.carbs })
      let calories_list = list.map(history, fn(s) { s.consumed.calories })

      NutritionData(
        protein: calculate_std_dev(proteins, avg.protein),
        fat: calculate_std_dev(fats, avg.fat),
        carbs: calculate_std_dev(carbs_list, avg.carbs),
        calories: calculate_std_dev(calories_list, avg.calories),
      )
    }
  }
}

/// Analyze trends in nutrition history
/// Compares first half average to second half average to determine trend direction
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
      // Count history length efficiently
      let len = list.fold(history, 0, fn(acc, _) { acc + 1 })
      let mid = len / 2

      // Split into first half and second half
      let first_half = list.take(history, mid)
      let second_half = list.drop(history, mid)

      let first_avg = average_nutrition_history(first_half)
      let second_avg = average_nutrition_history(second_half)

      // Calculate changes (percentage)
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

      // Determine trend direction (threshold: 5%)
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

/// Determine trend direction based on percentage change and threshold
fn determine_trend(pct_change: Float, threshold: Float) -> TrendDirection {
  let neg_threshold = 0.0 -. threshold
  case pct_change {
    change if change >. threshold -> Increasing
    change if change <. neg_threshold -> Decreasing
    _ -> Stable
  }
}

/// Check if nutrition is consistently meeting goals (within tolerance)
/// Returns the percentage of days that met the tolerance
pub fn calculate_consistency_rate(
  history: List(NutritionState),
  goals: NutritionGoals,
  tolerance_pct: Float,
) -> Float {
  case history {
    [] -> 0.0
    _ -> {
      // Count total and within_tolerance in one pass
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
      // Calculate sum and count in one pass
      let #(sum, count) =
        list.fold(history, #(
          NutritionData(protein: 0.0, fat: 0.0, carbs: 0.0, calories: 0.0),
          0,
        ), fn(acc, state) {
          let updated_sum =
            NutritionData(
              protein: acc.0.protein +. state.consumed.protein,
              fat: acc.0.fat +. state.consumed.fat,
              carbs: acc.0.carbs +. state.consumed.carbs,
              calories: acc.0.calories +. state.consumed.calories,
            )
          #(updated_sum, acc.1 + 1)
        })

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

/// Format status output for display - matches Go cli.go FormatStatusOutput
pub fn format_status_output(result: ReconciliationResult) -> String {
  let header =
    "═══════════════════════════════════════════════\n"
    <> "           NCP NUTRITION STATUS REPORT          \n"
    <> "═══════════════════════════════════════════════\n\n"
    <> "Date: "
    <> result.date
    <> "\n\n"

  let summary = format_status_summary(result)

  let macro_header =
    "📊 MACRO COMPARISON\n"
    <> "───────────────────────────────────────────────\n"
    <> "           Goal      Actual    Deviation  Status\n"

  let protein_line =
    "Protein:   "
    <> pad_float(result.goals.daily_protein, 6, 1)
    <> "g   "
    <> pad_float(result.average_consumed.protein, 6, 1)
    <> "g   "
    <> pad_deviation(result.deviation.protein_pct, 9)
    <> "  "
    <> deviation_indicator(result.deviation.protein_pct)
    <> "\n"

  let fat_line =
    "Fat:       "
    <> pad_float(result.goals.daily_fat, 6, 1)
    <> "g   "
    <> pad_float(result.average_consumed.fat, 6, 1)
    <> "g   "
    <> pad_deviation(result.deviation.fat_pct, 9)
    <> "  "
    <> deviation_indicator(result.deviation.fat_pct)
    <> "\n"

  let carbs_line =
    "Carbs:     "
    <> pad_float(result.goals.daily_carbs, 6, 1)
    <> "g   "
    <> pad_float(result.average_consumed.carbs, 6, 1)
    <> "g   "
    <> pad_deviation(result.deviation.carbs_pct, 9)
    <> "  "
    <> deviation_indicator(result.deviation.carbs_pct)
    <> "\n"

  let calories_line =
    "Calories:  "
    <> pad_float(result.goals.daily_calories, 6, 0)
    <> "    "
    <> pad_float(result.average_consumed.calories, 6, 0)
    <> "    "
    <> pad_deviation(result.deviation.calories_pct, 9)
    <> "  "
    <> deviation_indicator(result.deviation.calories_pct)
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
  <> summary
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
    let score_bar = format_score_bar(s.score)
    int.to_string(i + 1)
    <> ". "
    <> s.recipe_name
    <> "\n"
    <> "   Match: "
    <> score_bar
    <> " ("
    <> float_to_string_fixed(s.score *. 100.0, 0)
    <> "%)\n"
    <> "   Why:   "
    <> s.reason
    <> "\n\n"
  })
  |> string.concat
}

/// Format a visual score bar (0.0 to 1.0)
fn format_score_bar(score: Float) -> String {
  let filled_count = float.round(score *. 10.0)
  let empty_count = 10 - filled_count
  string.repeat("█", filled_count) <> string.repeat("░", empty_count)
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

/// Pad deviation string to specified width (right-aligned)
fn pad_deviation(pct: Float, width: Int) -> String {
  let formatted = format_deviation(pct)
  let padding = width - string.length(formatted)
  case padding > 0 {
    True -> string.repeat(" ", padding) <> formatted
    False -> formatted
  }
}

/// Get visual indicator for deviation status
fn deviation_indicator(pct: Float) -> String {
  let abs_pct = float.absolute_value(pct)
  case abs_pct <=. 5.0 {
    True -> "✓ Good"
    False ->
      case abs_pct <=. 10.0 {
        True -> "~ OK"
        False -> "! High"
      }
  }
}

/// Format a quick status summary showing overall compliance
fn format_status_summary(result: ReconciliationResult) -> String {
  let max_dev = deviation_max(result.deviation)
  let status_emoji = case result.within_tolerance {
    True -> "✓"
    False -> "⚠"
  }
  let summary_line =
    status_emoji
    <> " Quick Status: Max deviation "
    <> float_to_string_fixed(max_dev, 1)
    <> "% | "
    <> case result.within_tolerance {
      True -> "On Track"
      False -> "Needs Adjustment"
    }
    <> "\n\n"
  summary_line
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
