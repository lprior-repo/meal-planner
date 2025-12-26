/// Nutrition report formatting and table building
///
/// This module contains all functions related to formatting nutrition data,
/// building tables, and generating formatted reports for CLI output.
import gleam/float
import gleam/int
import gleam/string
import meal_planner/ncp
import meal_planner/ncp/types.{
  type DeviationResult, type NutritionData, type NutritionGoals,
  type TrendAnalysis, type TrendDirection, Decreasing, Increasing, Stable,
}

// ============================================================================
// Formatting Functions
// ============================================================================

/// Format a single float value for nutrition display
pub fn format_float_value(f: Float) -> String {
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
// Report Building Functions
// ============================================================================

/// Build report when no meals are logged
pub fn build_no_meals_report(date_str: String, goals: NutritionGoals) -> String {
  let header =
    "═══════════════════════════════════════════════\n"
    <> "        NUTRITION REPORT - "
    <> date_str
    <> "\n"
    <> "═══════════════════════════════════════════════\n\n"

  let message = "No meals logged for this date.\n\n"

  let goals_section =
    "Your nutrition goals:\n" <> build_goals_table(goals) <> "\n"

  header <> message <> goals_section
}

/// Build formatted nutrition report
pub fn build_nutrition_report(
  date_str: String,
  actual: NutritionData,
  goals: NutritionGoals,
  deviation: DeviationResult,
) -> String {
  let header =
    "═══════════════════════════════════════════════\n"
    <> "        NUTRITION REPORT - "
    <> date_str
    <> "\n"
    <> "═══════════════════════════════════════════════\n\n"

  let table_header =
    "┌─────────────┬──────────┬──────────┬──────────┐\n"
    <> "│ Nutrient    │ Goal     │ Actual   │ Diff     │\n"
    <> "├─────────────┼──────────┼──────────┼──────────┤"

  let protein_row =
    "\n│ Protein     │ "
    <> pad_right(float_to_string(goals.daily_protein) <> "g", 8)
    <> " │ "
    <> pad_right(float_to_string(actual.protein) <> "g", 8)
    <> " │ "
    <> pad_right(format_percentage(deviation.protein_pct), 8)
    <> " │"

  let fat_row =
    "\n│ Fat         │ "
    <> pad_right(float_to_string(goals.daily_fat) <> "g", 8)
    <> " │ "
    <> pad_right(float_to_string(actual.fat) <> "g", 8)
    <> " │ "
    <> pad_right(format_percentage(deviation.fat_pct), 8)
    <> " │"

  let carbs_row =
    "\n│ Carbs       │ "
    <> pad_right(float_to_string(goals.daily_carbs) <> "g", 8)
    <> " │ "
    <> pad_right(float_to_string(actual.carbs) <> "g", 8)
    <> " │ "
    <> pad_right(format_percentage(deviation.carbs_pct), 8)
    <> " │"

  let calories_row =
    "\n│ Calories    │ "
    <> pad_right(float_to_string(goals.daily_calories), 8)
    <> " │ "
    <> pad_right(float_to_string(actual.calories), 8)
    <> " │ "
    <> pad_right(format_percentage(deviation.calories_pct), 8)
    <> " │"

  let footer = "\n└─────────────┴──────────┴──────────┴──────────┘\n"

  header
  <> table_header
  <> protein_row
  <> fat_row
  <> carbs_row
  <> calories_row
  <> footer
}

/// Build formatted trends report
pub fn build_trends_report(
  days_count: Int,
  avg: NutritionData,
  analysis: TrendAnalysis,
  goals: NutritionGoals,
) -> String {
  let header =
    "═══════════════════════════════════════════════\n"
    <> "     NUTRITION TRENDS - Last "
    <> int.to_string(days_count)
    <> " Days\n"
    <> "═══════════════════════════════════════════════\n\n"

  let avg_section =
    "Average Daily Intake:\n"
    <> "  Protein:  "
    <> float_to_string(avg.protein)
    <> "g (Goal: "
    <> float_to_string(goals.daily_protein)
    <> "g)\n"
    <> "  Fat:      "
    <> float_to_string(avg.fat)
    <> "g (Goal: "
    <> float_to_string(goals.daily_fat)
    <> "g)\n"
    <> "  Carbs:    "
    <> float_to_string(avg.carbs)
    <> "g (Goal: "
    <> float_to_string(goals.daily_carbs)
    <> "g)\n"
    <> "  Calories: "
    <> float_to_string(avg.calories)
    <> "  (Goal: "
    <> float_to_string(goals.daily_calories)
    <> ")\n\n"

  let trends_section =
    "Trend Directions:\n"
    <> "  Protein:  "
    <> format_trend_direction(analysis.protein_trend)
    <> " ("
    <> format_percentage(analysis.protein_change)
    <> ")\n"
    <> "  Fat:      "
    <> format_trend_direction(analysis.fat_trend)
    <> " ("
    <> format_percentage(analysis.fat_change)
    <> ")\n"
    <> "  Carbs:    "
    <> format_trend_direction(analysis.carbs_trend)
    <> " ("
    <> format_percentage(analysis.carbs_change)
    <> ")\n"
    <> "  Calories: "
    <> format_trend_direction(analysis.calories_trend)
    <> " ("
    <> format_percentage(analysis.calories_change)
    <> ")\n\n"

  let footer = "═══════════════════════════════════════════════\n"

  header <> avg_section <> trends_section <> footer
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
