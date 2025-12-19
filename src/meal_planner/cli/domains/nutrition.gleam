/// Nutrition CLI domain - handles nutrition analysis, goals, trends, and compliance
///
/// This module provides CLI commands for:
/// - Setting and viewing nutrition goals
/// - Analyzing daily nutrition data
/// - Viewing nutrition trends over time
/// - Checking compliance with goals
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import glint
import meal_planner/config.{type Config}
import meal_planner/ncp.{
  type DeviationResult, type NutritionData, type NutritionGoals,
  type TrendDirection, Decreasing, Increasing, Stable, get_default_goals,
}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Nutrition domain command for Glint CLI
pub fn cmd(_config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("View and manage nutrition goals and analysis")
  use date <- glint.flag(
    glint.string_flag("date")
    |> glint.flag_help("Date for nutrition report (YYYY-MM-DD)")
    |> glint.flag_default("today"),
  )
  use days <- glint.flag(
    glint.int_flag("days")
    |> glint.flag_help("Number of days for trends")
    |> glint.flag_default(7),
  )
  use tolerance <- glint.flag(
    glint.float_flag("tolerance")
    |> glint.flag_help("Tolerance percentage for compliance check")
    |> glint.flag_default(10.0),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["report"] -> {
      let report_date = date(flags) |> result.unwrap("today")
      io.println("Nutrition report for: " <> report_date)
      Ok(Nil)
    }
    ["goals"] -> {
      io.println("Current nutrition goals:")
      io.println(format_goals(get_default_goals()))
      Ok(Nil)
    }
    ["trends"] -> {
      let trend_days = days(flags) |> result.unwrap(7)
      io.println("Trends for last " <> int.to_string(trend_days) <> " days")
      Ok(Nil)
    }
    ["compliance"] -> {
      let comp_date = date(flags) |> result.unwrap("today")
      let tol = tolerance(flags) |> result.unwrap(10.0)
      io.println(
        "Compliance check for "
        <> comp_date
        <> " (tolerance: "
        <> float.to_string(tol)
        <> "%)",
      )
      Ok(Nil)
    }
    _ -> {
      io.println("Nutrition commands:")
      io.println("  mp nutrition report --date 2025-12-19")
      io.println("  mp nutrition goals")
      io.println("  mp nutrition trends --days 7")
      io.println("  mp nutrition compliance --date 2025-12-19 --tolerance 10")
      Ok(Nil)
    }
  }
}

// ============================================================================
// Formatting Functions
// ============================================================================

/// Format nutrition goals as a readable string
pub fn format_goals(goals: NutritionGoals) -> String {
  "Protein: "
  <> float_to_string(goals.daily_protein)
  <> "g | Fat: "
  <> float_to_string(goals.daily_fat)
  <> "g | Carbs: "
  <> float_to_string(goals.daily_carbs)
  <> "g | Calories: "
  <> float_to_string(goals.daily_calories)
}

/// Format nutrition data as a readable string
pub fn format_nutrition_data(data: NutritionData) -> String {
  "Protein: "
  <> float_to_string(data.protein)
  <> "g | Fat: "
  <> float_to_string(data.fat)
  <> "g | Carbs: "
  <> float_to_string(data.carbs)
  <> "g | Calories: "
  <> float_to_string(data.calories)
}

/// Format deviation result with percentage signs
pub fn format_deviation(deviation: DeviationResult) -> String {
  "Protein: "
  <> format_percentage(deviation.protein_pct)
  <> " | Fat: "
  <> format_percentage(deviation.fat_pct)
  <> " | Carbs: "
  <> format_percentage(deviation.carbs_pct)
  <> " | Calories: "
  <> format_percentage(deviation.calories_pct)
}

/// Format a trend direction with an arrow
pub fn format_trend_direction(trend: TrendDirection) -> String {
  case trend {
    Increasing -> "↑ Increasing"
    Decreasing -> "↓ Decreasing"
    Stable -> "→ Stable"
  }
}

// ============================================================================
// Table Building Functions
// ============================================================================

/// Build a formatted table for nutrition goals
pub fn build_goals_table(goals: NutritionGoals) -> String {
  let header =
    "┌─────────────┬──────────┐\n│ Nutrient    │ Goal     │\n├─────────────┼──────────┤"
  let protein_row =
    "\n│ Protein     │ "
    <> pad_right(float_to_string(goals.daily_protein) <> "g", 8)
    <> " │"
  let fat_row =
    "\n│ Fat         │ "
    <> pad_right(float_to_string(goals.daily_fat) <> "g", 8)
    <> " │"
  let carbs_row =
    "\n│ Carbs       │ "
    <> pad_right(float_to_string(goals.daily_carbs) <> "g", 8)
    <> " │"
  let calories_row =
    "\n│ Calories    │ "
    <> pad_right(float_to_string(goals.daily_calories), 8)
    <> " │"
  let footer = "\n└─────────────┴──────────┘"

  header <> protein_row <> fat_row <> carbs_row <> calories_row <> footer
}

/// Build a compliance summary showing if within tolerance
pub fn build_compliance_summary(
  deviation: DeviationResult,
  tolerance: Float,
) -> String {
  let is_compliant = ncp.deviation_is_within_tolerance(deviation, tolerance)
  let status = case is_compliant {
    True -> "✓ ON TRACK"
    False -> "✗ OFF TRACK"
  }

  let protein_status = compliance_indicator(deviation.protein_pct, tolerance)
  let fat_status = compliance_indicator(deviation.fat_pct, tolerance)
  let carbs_status = compliance_indicator(deviation.carbs_pct, tolerance)
  let calories_status = compliance_indicator(deviation.calories_pct, tolerance)

  "Compliance Status: "
  <> status
  <> "\n\nProtein:  "
  <> protein_status
  <> " "
  <> format_percentage(deviation.protein_pct)
  <> "\nFat:      "
  <> fat_status
  <> " "
  <> format_percentage(deviation.fat_pct)
  <> "\nCarbs:    "
  <> carbs_status
  <> " "
  <> format_percentage(deviation.carbs_pct)
  <> "\nCalories: "
  <> calories_status
  <> " "
  <> format_percentage(deviation.calories_pct)
}

// ============================================================================
// Helper Functions
// ============================================================================

fn float_to_string(f: Float) -> String {
  float.to_string(f)
  |> string.split(".")
  |> fn(parts) {
    case parts {
      [whole, decimal] -> {
        let trimmed_decimal = string.slice(decimal, 0, 1)
        whole <> "." <> trimmed_decimal
      }
      [whole] -> whole <> ".0"
      _ -> float.to_string(f)
    }
  }
}

fn format_percentage(pct: Float) -> String {
  let sign = case pct >=. 0.0 {
    True -> "+"
    False -> ""
  }
  sign <> float_to_string(pct) <> "%"
}

fn compliance_indicator(pct: Float, tolerance: Float) -> String {
  let abs_pct = float.absolute_value(pct)
  case abs_pct <=. tolerance {
    True -> "✓"
    False -> "✗"
  }
}

fn pad_right(s: String, width: Int) -> String {
  let current_length = string.length(s)
  let padding_needed = width - current_length
  case padding_needed > 0 {
    True -> s <> string.repeat(" ", padding_needed)
    False -> s
  }
}
