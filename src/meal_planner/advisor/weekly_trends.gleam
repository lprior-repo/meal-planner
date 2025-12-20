/// Weekly trend analysis for nutrition advisor
///
/// Analyzes 7-day patterns in FatSecret diary data to generate insights
/// and recommendations for future meal planning.
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import meal_planner/fatsecret/diary/service as diary_service
import meal_planner/fatsecret/diary/types.{type DaySummary} as diary_types
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
  _conn: pog.Connection,
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
  // Calculate start date (6 days before end date, for 7 days total)
  let start_date_int = end_date_int - 6

  // Fetch the month summary which contains all daily summaries
  use month_summary <- result.try(
    diary_service.get_month_summary(conn, end_date_int)
    |> result.map_error(fn(e) {
      ServiceError(diary_service.error_to_message(e))
    }),
  )

  // Filter the days to only include our 7-day range
  let summaries =
    month_summary.days
    |> list.filter(fn(day) {
      day.date_int >= start_date_int && day.date_int <= end_date_int
    })

  // Ensure we have data
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
  let averages = calculate_macro_averages(summaries)
  let #(avg_protein, avg_carbs, avg_fat, avg_calories) = averages

  let patterns = []

  // Protein patterns
  let patterns = case avg_protein <. targets.daily_protein *. 0.85 {
    True ->
      list.append(patterns, [
        "protein_deficiency: averaging "
          <> float.to_string(avg_protein)
          <> "g vs "
          <> float.to_string(targets.daily_protein)
          <> "g target",
      ])
    False ->
      case avg_protein >. targets.daily_protein *. 1.15 {
        True ->
          list.append(patterns, [
            "protein_overage: averaging "
              <> float.to_string(avg_protein)
              <> "g vs "
              <> float.to_string(targets.daily_protein)
              <> "g target",
          ])
        False -> patterns
      }
  }

  // Carb patterns
  let patterns = case avg_carbs <. targets.daily_carbs *. 0.85 {
    True ->
      list.append(patterns, [
        "carb_deficiency: averaging "
          <> float.to_string(avg_carbs)
          <> "g vs "
          <> float.to_string(targets.daily_carbs)
          <> "g target",
      ])
    False ->
      case avg_carbs >. targets.daily_carbs *. 1.15 {
        True ->
          list.append(patterns, [
            "carb_overage: averaging "
              <> float.to_string(avg_carbs)
              <> "g vs "
              <> float.to_string(targets.daily_carbs)
              <> "g target",
          ])
        False -> patterns
      }
  }

  // Fat patterns
  let patterns = case avg_fat <. targets.daily_fat *. 0.85 {
    True ->
      list.append(patterns, [
        "fat_deficiency: averaging "
          <> float.to_string(avg_fat)
          <> "g vs "
          <> float.to_string(targets.daily_fat)
          <> "g target",
      ])
    False ->
      case avg_fat >. targets.daily_fat *. 1.15 {
        True ->
          list.append(patterns, [
            "fat_overage: averaging "
              <> float.to_string(avg_fat)
              <> "g vs "
              <> float.to_string(targets.daily_fat)
              <> "g target",
          ])
        False -> patterns
      }
  }

  // Calorie patterns
  let patterns = case avg_calories <. targets.daily_calories *. 0.85 {
    True ->
      list.append(patterns, [
        "calorie_deficit: averaging "
          <> float.to_string(avg_calories)
          <> " vs "
          <> float.to_string(targets.daily_calories)
          <> " target",
      ])
    False ->
      case avg_calories >. targets.daily_calories *. 1.15 {
        True ->
          list.append(patterns, [
            "calorie_surplus: averaging "
              <> float.to_string(avg_calories)
              <> " vs "
              <> float.to_string(targets.daily_calories)
              <> " target",
          ])
        False -> patterns
      }
  }

  patterns
}

// ============================================================================
// Helper Functions - Best/Worst Day Analysis
// ============================================================================

/// Find best and worst days relative to targets
fn find_best_worst_days(
  summaries: List(DaySummary),
  targets: NutritionTargets,
) -> #(String, String) {
  case summaries {
    [] -> #("", "")
    _ -> {
      // Calculate distance from targets for each day
      let scored_days =
        summaries
        |> list.map(fn(day) {
          let protein_diff =
            float.absolute_value(day.protein -. targets.daily_protein)
          let carb_diff =
            float.absolute_value(day.carbohydrate -. targets.daily_carbs)
          let fat_diff = float.absolute_value(day.fat -. targets.daily_fat)
          let calorie_diff =
            float.absolute_value(day.calories -. targets.daily_calories)

          // Total deviation score (lower is better)
          let score = protein_diff +. carb_diff +. fat_diff +. calorie_diff

          #(day, score)
        })

      // Find minimum and maximum scores
      let assert Ok(#(best_day, _best_score)) =
        scored_days
        |> list.reduce(fn(acc, curr) {
          case curr.1 <. acc.1 {
            True -> curr
            False -> acc
          }
        })

      let assert Ok(#(worst_day, _worst_score)) =
        scored_days
        |> list.reduce(fn(acc, curr) {
          case curr.1 >. acc.1 {
            True -> curr
            False -> acc
          }
        })

      #(
        diary_types.int_to_date(best_day.date_int),
        diary_types.int_to_date(worst_day.date_int),
      )
    }
  }
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
  let #(avg_protein, avg_carbs, avg_fat, avg_calories) = averages

  patterns
  |> list.map(fn(pattern) {
    // Use string.contains to check pattern type
    case
      string.contains(pattern, "protein_deficiency"),
      string.contains(pattern, "protein_overage"),
      string.contains(pattern, "carb_deficiency"),
      string.contains(pattern, "carb_overage"),
      string.contains(pattern, "fat_deficiency"),
      string.contains(pattern, "fat_overage"),
      string.contains(pattern, "calorie_deficit"),
      string.contains(pattern, "calorie_surplus")
    {
      // Protein deficiency
      True, False, False, False, False, False, False, False -> {
        let deficit = targets.daily_protein -. avg_protein
        "Increase protein intake by "
        <> float.to_string(deficit)
        <> "g per day. Consider adding lean meats, eggs, or protein shakes."
      }
      // Protein overage
      False, True, False, False, False, False, False, False ->
        "Protein intake is above target. This is generally fine for active individuals."

      // Carb deficiency
      False, False, True, False, False, False, False, False -> {
        let deficit = targets.daily_carbs -. avg_carbs
        "Increase carb intake by "
        <> float.to_string(deficit)
        <> "g per day. Add whole grains, fruits, or starchy vegetables."
      }
      // Carb overage
      False, False, False, True, False, False, False, False -> {
        let excess = avg_carbs -. targets.daily_carbs
        "Reduce carb intake by "
        <> float.to_string(excess)
        <> "g per day. Focus on reducing refined carbs and sugars."
      }

      // Fat deficiency
      False, False, False, False, True, False, False, False -> {
        let deficit = targets.daily_fat -. avg_fat
        "Increase healthy fat intake by "
        <> float.to_string(deficit)
        <> "g per day. Add nuts, avocados, or olive oil."
      }
      // Fat overage
      False, False, False, False, False, True, False, False -> {
        let excess = avg_fat -. targets.daily_fat
        "Reduce fat intake by "
        <> float.to_string(excess)
        <> "g per day. Limit fried foods and high-fat dairy."
      }

      // Calorie deficit
      False, False, False, False, False, False, True, False -> {
        let deficit = targets.daily_calories -. avg_calories
        "Increase calorie intake by "
        <> float.to_string(deficit)
        <> " per day to meet your goals."
      }
      // Calorie surplus
      False, False, False, False, False, False, False, True -> {
        let excess = avg_calories -. targets.daily_calories
        "Reduce calorie intake by "
        <> float.to_string(excess)
        <> " per day to meet your goals."
      }

      // Default case
      _, _, _, _, _, _, _, _ -> "Continue monitoring your nutrition patterns."
    }
  })
}
