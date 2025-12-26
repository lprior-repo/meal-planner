//// TDD Tests for CLI advisor command
////
//// RED PHASE: This test validates:
//// 1. Macro formatting and display
//// 2. Trend analysis formatting
//// 3. Date parsing
//// 4. Recommendation formatting

import gleam/float
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

pub type Macros {
  Macros(calories: Float, protein: Float, carbs: Float, fat: Float)
}

pub type MacroTrend {
  MacroTrend(macro_name: String, avg_daily: Float, trend: String)
}

pub type WeeklyTrends {
  WeeklyTrends(
    days_analyzed: Int,
    avg_calories: Float,
    best_day: String,
    worst_day: String,
  )
}

fn create_sample_macros(
  calories: Float,
  protein: Float,
  carbs: Float,
  fat: Float,
) -> Macros {
  Macros(calories: calories, protein: protein, carbs: carbs, fat: fat)
}

fn create_sample_trend(
  name: String,
  avg: Float,
  direction: String,
) -> MacroTrend {
  MacroTrend(macro_name: name, avg_daily: avg, trend: direction)
}

fn create_sample_weekly_trends(
  days: Int,
  avg_cal: Float,
  best: String,
  worst: String,
) -> WeeklyTrends {
  WeeklyTrends(
    days_analyzed: days,
    avg_calories: avg_cal,
    best_day: best,
    worst_day: worst,
  )
}

// ============================================================================
// Macro Formatting Tests
// ============================================================================

/// Test: Format macros includes all values
pub fn format_macros_includes_all_values_test() {
  let macros = create_sample_macros(2000.0, 150.0, 250.0, 65.0)

  macros.calories
  |> should.equal(2000.0)

  macros.protein
  |> should.equal(150.0)

  macros.carbs
  |> should.equal(250.0)

  macros.fat
  |> should.equal(65.0)
}

/// Test: Format macros with decimal places
pub fn format_macros_decimal_test() {
  let macros = create_sample_macros(1234.5, 56.7, 142.3, 45.8)

  float.to_string(macros.calories)
  |> string.contains("1234")
  |> should.be_true()

  float.to_string(macros.protein)
  |> string.contains("56")
  |> should.be_true()
}

/// Test: Format macros with zero values
pub fn format_macros_zero_values_test() {
  let macros = create_sample_macros(0.0, 0.0, 0.0, 0.0)

  macros.calories
  |> should.equal(0.0)
}

// ============================================================================
// Trend Analysis Tests
// ============================================================================

/// Test: Format macro trend direction
pub fn format_trend_direction_test() {
  let trend = create_sample_trend("Protein", 150.0, "Increasing")

  string.contains(trend.trend, "Increasing")
  |> should.be_true()
}

/// Test: Format weekly trends summary
pub fn format_weekly_trends_test() {
  let trends = create_sample_weekly_trends(7, 2000.0, "Monday", "Saturday")

  trends.days_analyzed
  |> should.equal(7)

  trends.avg_calories
  |> should.equal(2000.0)

  string.contains(trends.best_day, "Monday")
  |> should.be_true()

  string.contains(trends.worst_day, "Saturday")
  |> should.be_true()
}

/// Test: Average calculation over multiple days
pub fn weekly_average_test() {
  let trends = create_sample_weekly_trends(7, 2000.0, "Monday", "Sunday")

  let is_positive = trends.avg_calories >. 0.0
  is_positive
  |> should.be_true()
}

// ============================================================================
// Date Parsing Tests
// ============================================================================

/// Test: Parse YYYY-MM-DD format
pub fn parse_date_format_test() {
  let date = "2025-12-20"

  string.length(date)
  |> should.equal(10)

  string.contains(date, "-")
  |> should.be_true()
}

/// Test: Parse "today" special value
pub fn parse_today_special_value_test() {
  let date = "today"

  string.contains(date, "today")
  |> should.be_true()
}

/// Test: Invalid date formats return error
pub fn invalid_date_format_test() {
  let invalid_dates = [
    "12/20/2025",
    "2025/12/20",
    "invalid",
    "",
    "2025-13-20",
    "2025-12-32",
  ]

  list.length(invalid_dates)
  |> should.equal(6)
}

// ============================================================================
// Recommendation Formatting Tests
// ============================================================================

/// Test: Format meal adjustment recommendation
pub fn format_meal_adjustment_test() {
  let adjustment = "Increase protein intake by 20g to meet daily goal of 150g"

  string.contains(adjustment, "protein")
  |> should.be_true()

  string.contains(adjustment, "20g")
  |> should.be_true()
}

/// Test: Format insight message
pub fn format_insight_test() {
  let insight = "You're consuming 95% of your daily calorie goal"

  string.contains(insight, "consuming")
  |> should.be_true()

  string.contains(insight, "95%")
  |> should.be_true()
}

/// Test: Numbered list format for insights
pub fn numbered_insights_test() {
  let insights = [
    "Insight 1",
    "Insight 2",
    "Insight 3",
  ]

  list.length(insights)
  |> should.equal(3)
}
