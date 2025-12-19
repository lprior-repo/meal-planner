/// Weekly trend analysis for nutrition advisor
///
/// Analyzes 7-day patterns in FatSecret diary data to generate insights
/// and recommendations for future meal planning.
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import meal_planner/fatsecret/diary/service as diary_service
import meal_planner/fatsecret/diary/types.{type DaySummary}
import pog

// ============================================================================
// Types
// ============================================================================

/// Weekly trend analysis results
pub type WeeklyTrends {
  WeeklyTrends(
    /// Number of days successfully analyzed
    days_analyzed: Int,
    /// Average daily protein (grams)
    avg_protein: Float,
    /// Average daily carbs (grams)
    avg_carbs: Float,
    /// Average daily fat (grams)
    avg_fat: Float,
    /// Average daily calories
    avg_calories: Float,
    /// Identified patterns (protein_deficiency, carb_overage, etc.)
    patterns: List(String),
    /// Best day (YYYY-MM-DD) - closest to targets
    best_day: String,
    /// Worst day (YYYY-MM-DD) - furthest from targets
    worst_day: String,
    /// Actionable recommendations for next week
    recommendations: List(String),
  )
}

/// User nutrition targets
pub type NutritionTargets {
  NutritionTargets(
    daily_protein: Float,
    daily_carbs: Float,
    daily_fat: Float,
    daily_calories: Float,
  )
}

/// Analysis error types
pub type AnalysisError {
  DatabaseError(message: String)
  ServiceError(message: String)
  NoDataAvailable
  InvalidDateRange
}

// ============================================================================
// Main Analysis Function
// ============================================================================

/// Analyze weekly trends from FatSecret diary data
///
/// Fetches past 7 days of diary entries and calculates:
/// - Macro averages (protein, carbs, fat, calories)
/// - Pattern identification (deficiencies, overages)
/// - Best/worst days relative to targets
/// - Actionable recommendations for next week
///
/// Parameters:
/// - conn: Database connection
/// - end_date_int: End date for analysis (days since epoch)
///
/// Returns:
/// - Ok(WeeklyTrends) with complete analysis
/// - Error(AnalysisError) on failure
pub fn analyze_weekly_trends(
  conn: pog.Connection,
  end_date_int: Int,
) -> Result(WeeklyTrends, AnalysisError) {
  // Fetch targets from database
  use targets <- result.try(fetch_nutrition_targets(conn))

  // Fetch 7 days of diary summaries
  use summaries <- result.try(fetch_weekly_summaries(conn, end_date_int))

  // Calculate averages
  let averages = calculate_macro_averages(summaries)

  // Identify patterns based on targets
  let patterns = identify_nutrition_patterns(summaries, targets)

  // Find best/worst days
  let #(best_day, worst_day) = find_best_worst_days(summaries, targets)

  // Generate recommendations
  let recommendations =
    generate_pattern_recommendations(patterns, averages, targets)

  Ok(WeeklyTrends(
    days_analyzed: list.length(summaries),
    avg_protein: averages.0,
    avg_carbs: averages.1,
    avg_fat: averages.2,
    avg_calories: averages.3,
    patterns: patterns,
    best_day: best_day,
    worst_day: worst_day,
    recommendations: recommendations,
  ))
}

// ============================================================================
// Helper Functions - Data Fetching
// ============================================================================

/// Fetch nutrition targets from database
fn fetch_nutrition_targets(
  conn: pog.Connection,
) -> Result(NutritionTargets, AnalysisError) {
  // TODO: Query nutrition_goals table
  // For now, return placeholder targets
  Ok(NutritionTargets(
    daily_protein: 150.0,
    daily_carbs: 200.0,
    daily_fat: 65.0,
    daily_calories: 2000.0,
  ))
}

/// Fetch 7 days of diary summaries from FatSecret
fn fetch_weekly_summaries(
  conn: pog.Connection,
  end_date_int: Int,
) -> Result(List(DaySummary), AnalysisError) {
  // Fetch month summary which contains daily summaries
  let start_date_int = end_date_int - 6
  // 7 days including end date

  // For now, return empty list to make tests fail properly
  // TODO: Implement actual FatSecret API calls
  let summaries = []

  case list.is_empty(summaries) {
    True -> Error(NoDataAvailable)
    False -> Ok(summaries)
  }
}

// ============================================================================
// Helper Functions - Calculations
// ============================================================================

/// Calculate average macros from daily summaries
pub fn calculate_macro_averages(
  summaries: List(DaySummary),
) -> #(Float, Float, Float, Float) {
  let count = list.length(summaries)
  case count {
    0 -> #(0.0, 0.0, 0.0, 0.0)
    _ -> {
      let totals =
        list.fold(summaries, #(0.0, 0.0, 0.0, 0.0), fn(acc, day) {
          let #(p, c, f, cal) = acc
          #(
            p +. day.protein,
            c +. day.carbohydrate,
            f +. day.fat,
            cal +. day.calories,
          )
        })

      let count_float = int.to_float(count)
      #(
        totals.0 /. count_float,
        totals.1 /. count_float,
        totals.2 /. count_float,
        totals.3 /. count_float,
      )
    }
  }
}

// ============================================================================
// Helper Functions - Pattern Identification
// ============================================================================

/// Identify nutrition patterns from weekly data
pub fn identify_nutrition_patterns(
  summaries: List(DaySummary),
  targets: NutritionTargets,
) -> List(String) {
  // TODO: Implement pattern detection logic
  // For now, return empty list
  []
}

// ============================================================================
// Helper Functions - Best/Worst Day Analysis
// ============================================================================

/// Find best and worst days relative to targets
fn find_best_worst_days(
  summaries: List(DaySummary),
  targets: NutritionTargets,
) -> #(String, String) {
  // TODO: Implement best/worst day logic
  // For now, return empty strings
  #("", "")
}

// ============================================================================
// Helper Functions - Recommendation Generation
// ============================================================================

/// Generate actionable recommendations for next week
pub fn generate_pattern_recommendations(
  patterns: List(String),
  averages: #(Float, Float, Float, Float),
  targets: NutritionTargets,
) -> List(String) {
  // TODO: Implement recommendation logic
  // For now, return empty list
  []
}
