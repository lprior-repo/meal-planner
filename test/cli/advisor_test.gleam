//// TDD Tests for CLI advisor command
////
//// RED PHASE: This test validates:
//// 1. Date parsing (today, YYYY-MM-DD format, invalid formats)
//// 2. Macro formatting for display
//// 3. Insight and trend formatting
//// 4. Macro trend calculations

import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/advisor
import meal_planner/advisor/daily_recommendations
import meal_planner/advisor/weekly_trends
import meal_planner/advisor/recommendations

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

fn create_sample_macros(
  calories: Float,
  protein: Float,
  carbs: Float,
  fat: Float,
) -> daily_recommendations.Macros {
  daily_recommendations.Macros(
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
  )
}

fn create_sample_macro_trend(
  avg_calories: Float,
  avg_protein: Float,
  avg_carbs: Float,
  avg_fat: Float,
) -> daily_recommendations.MacroTrend {
  daily_recommendations.MacroTrend(
    avg_calories: avg_calories,
    avg_protein: avg_protein,
    avg_carbs: avg_carbs,
    avg_fat: avg_fat,
  )
}

fn create_sample_weekly_trends(
  days_analyzed: Int,
  avg_calories: Float,
  avg_protein: Float,
  avg_carbs: Float,
  avg_fat: Float,
) -> weekly_trends.WeeklyTrends {
  weekly_trends.WeeklyTrends(
    days_analyzed: days_analyzed,
    avg_calories: avg_calories,
    avg_protein: avg_protein,
    avg_carbs: avg_carbs,
    avg_fat: avg_fat,
    best_day: "Monday",
    worst_day: "Friday",
    patterns: [],
    recommendations: [],
  )
}

// ============================================================================
// Date Parsing Tests
// ============================================================================

/// Test: parse_date_to_int accepts "today"
pub fn parse_date_to_int_today_test() {
  let result = advisor.parse_date_to_int("today")
  result |> should.not_equal(None)
}

/// Test: parse_date_to_int accepts valid YYYY-MM-DD format
pub fn parse_date_to_int_valid_date_test() {
  let result = advisor.parse_date_to_int("2025-12-21")
  result |> should.not_equal(None)
}

/// Test: parse_date_to_int rejects invalid format (MM/DD/YYYY)
pub fn parse_date_to_int_invalid_format_test() {
  let result = advisor.parse_date_to_int("12/21/2025")
  result |> should.equal(None)
}

/// Test: parse_date_to_int rejects empty string
pub fn parse_date_to_int_empty_string_test() {
  let result = advisor.parse_date_to_int("")
  result |> should.equal(None)
}

/// Test: parse_date_to_int rejects invalid month (13)
pub fn parse_date_to_int_invalid_month_test() {
  let result = advisor.parse_date_to_int("2025-13-21")
  result |> should.equal(None)
}

/// Test: parse_date_to_int rejects invalid day (32)
pub fn parse_date_to_int_invalid_day_test() {
  let result = advisor.parse_date_to_int("2025-12-32")
  result |> should.equal(None)
}

/// Test: parse_date_to_int accepts Feb 28
pub fn parse_date_to_int_feb_28_test() {
  let result = advisor.parse_date_to_int("2025-02-28")
  result |> should.not_equal(None)
}

/// Test: parse_date_to_int accepts leap year Feb 29
pub fn parse_date_to_int_feb_29_leap_year_test() {
  let result = advisor.parse_date_to_int("2024-02-29")
  result |> should.not_equal(None)
}

// ============================================================================
// Macro Formatting Tests
// ============================================================================

/// Test: format_macros includes all macro values
pub fn format_macros_includes_all_values_test() {
  let macros = create_sample_macros(2000.0, 150.0, 250.0, 65.0)
  let output = advisor.format_macros(macros)

  string.contains(output, "2000")
  |> should.be_true()

  string.contains(output, "150")
  |> should.be_true()

  string.contains(output, "250")
  |> should.be_true()

  string.contains(output, "65")
  |> should.be_true()
}

/// Test: format_macros uses correct labels
pub fn format_macros_uses_correct_labels_test() {
  let macros = create_sample_macros(2000.0, 150.0, 250.0, 65.0)
  let output = advisor.format_macros(macros)

  string.contains(output, "cal")
  |> should.be_true()

  string.contains(output, "P:")
  |> should.be_true()

  string.contains(output, "C:")
  |> should.be_true()

  string.contains(output, "F:")
  |> should.be_true()
}

/// Test: format_macros handles zero values
pub fn format_macros_handles_zero_values_test() {
  let macros = create_sample_macros(0.0, 0.0, 0.0, 0.0)
  let output = advisor.format_macros(macros)

  string.contains(output, "0")
  |> should.be_true()
}

// ============================================================================
// Insight Formatting Tests
// ============================================================================

/// Test: format_insight adds bullet point prefix
pub fn format_insight_adds_prefix_test() {
  let insight = advisor.format_insight("You are doing great!")

  string.contains(insight, "•")
  |> should.be_true()

  string.contains(insight, "You are doing great!")
  |> should.be_true()
}

/// Test: format_insight handles multiple insights
pub fn format_insight_multiple_test() {
  let insights = [
    "Increase protein intake",
    "Reduce carbohydrate consumption",
  ]

  let formatted = list.map(insights, advisor.format_insight)

  list.length(formatted)
  |> should.equal(2)

  formatted
  |> list.all(string.contains(_, "•"))
  |> should.be_true()
}

// ============================================================================
// Macro Trend Formatting Tests
// ============================================================================

/// Test: format_macro_trend includes all values
pub fn format_macro_trend_includes_all_values_test() {
  let trend = create_sample_macro_trend(2000.0, 150.0, 250.0, 65.0)
  let output = advisor.format_macro_trend(trend)

  string.contains(output, "2000")
  |> should.be_true()

  string.contains(output, "150")
  |> should.be_true()

  string.contains(output, "250")
  |> should.be_true()

  string.contains(output, "65")
  |> should.be_true()
}

/// Test: format_macro_trend mentions 7-day average
pub fn format_macro_trend_mentions_7_day_test() {
  let trend = create_sample_macro_trend(2000.0, 150.0, 250.0, 65.0)
  let output = advisor.format_macro_trend(trend)

  string.contains(output, "7-Day")
  |> should.be_true()
}

// ============================================================================
// Weekly Trends Formatting Tests
// ============================================================================

/// Test: format_weekly_trends includes days analyzed
pub fn format_weekly_trends_includes_days_test() {
  let trends = create_sample_weekly_trends(7, 2000.0, 150.0, 250.0, 65.0)
  let output = advisor.format_weekly_trends(trends)

  string.contains(output, "7")
  |> should.be_true()

  string.contains(output, "days analyzed")
  |> should.be_true()
}

/// Test: format_weekly_trends includes averages
pub fn format_weekly_trends_includes_averages_test() {
  let trends = create_sample_weekly_trends(7, 2000.0, 150.0, 250.0, 65.0)
  let output = advisor.format_weekly_trends(trends)

  string.contains(output, "Averages")
  |> should.be_true()

  string.contains(output, "2000")
  |> should.be_true()
}

/// Test: format_weekly_trends includes best/worst days
pub fn format_weekly_trends_includes_best_worst_test() {
  let trends = create_sample_weekly_trends(7, 2000.0, 150.0, 250.0, 65.0)
  let output = advisor.format_weekly_trends(trends)

  string.contains(output, "Best day")
  |> should.be_true()

  string.contains(output, "Worst day")
  |> should.be_true()

  string.contains(output, "Monday")
  |> should.be_true()

  string.contains(output, "Friday")
  |> should.be_true()
}

// ============================================================================
// Edge Cases
// ============================================================================

/// Test: format_macros handles decimal values
pub fn format_macros_handles_decimals_test() {
  let macros = create_sample_macros(2234.5, 156.7, 253.3, 65.8)
  let output = advisor.format_macros(macros)

  // Should contain at least one decimal value
  string.contains(output, ".")
  |> should.be_true()
}

/// Test: parse_date_to_int handles year 2024
pub fn parse_date_to_int_year_2024_test() {
  let result = advisor.parse_date_to_int("2024-12-21")
  result |> should.not_equal(None)
}

/// Test: parse_date_to_int handles year 2026
pub fn parse_date_to_int_year_2026_test() {
  let result = advisor.parse_date_to_int("2026-01-01")
  result |> should.not_equal(None)
}
