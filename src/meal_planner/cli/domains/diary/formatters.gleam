/// Diary formatting functions for display output
///
/// This module provides formatting utilities for displaying food diary entries
/// and nutrition summaries in a consistent, readable format.
import gleam/float
import gleam/int
import gleam/string
import meal_planner/cli/domains/diary/types.{type DayNutrition}
import meal_planner/fatsecret/diary/types as fatsecret_types

/// Format a single food entry for display
///
/// Creates a formatted string showing the entry ID, food name (truncated to 30 chars if needed)
/// followed by calories and macronutrients (protein, carbs, fat).
///
/// Example output:
/// "entry-123 | Chicken Breast               | 165.0 cal | P:31.0g C:0.0g F:3.6g"
pub fn format_food_entry_row(entry: fatsecret_types.FoodEntry) -> String {
  let id_str = fatsecret_types.food_entry_id_to_string(entry.food_entry_id)
  let padded_name = case string.length(entry.food_entry_name) {
    len if len >= 30 -> string.slice(entry.food_entry_name, 0, 27) <> "..."
    len -> entry.food_entry_name <> string.repeat(" ", 30 - len)
  }
  id_str
  <> " | "
  <> padded_name
  <> " | "
  <> format_float(entry.calories)
  <> " cal | P:"
  <> format_float(entry.protein)
  <> "g C:"
  <> format_float(entry.carbohydrate)
  <> "g F:"
  <> format_float(entry.fat)
  <> "g"
}

/// Format nutrition summary for display
///
/// Creates a formatted string showing total daily calories and macronutrients,
/// preceded by a separator line.
///
/// Example output:
/// "═══════════════════════════════════════════════════════════════════
///  DailyTotal: 2150.0cal | P:180.0g C:200.0g F:65.0g"
pub fn format_nutrition_summary(nutrition: DayNutrition) -> String {
  "═══════════════════════════════════════════════════════════════════"
  <> "\nDailyTotal: "
  <> format_float(nutrition.calories)
  <> "cal | P:"
  <> format_float(nutrition.protein)
  <> "g C:"
  <> format_float(nutrition.carbohydrates)
  <> "g F:"
  <> format_float(nutrition.fat)
  <> "g"
}

/// Format a float to 1 decimal place for display
///
/// Converts a float value to a string representation, rounding to 1 decimal place.
/// Uses int conversion to avoid scientific notation for large values.
fn format_float(value: Float) -> String {
  // Round to 1 decimal place using integer arithmetic
  let rounded_int = float.round(value *. 10.0)
  let int_part = rounded_int / 10
  let decimal_part = rounded_int % 10

  // Check if it's a whole number (no decimal part)
  case decimal_part {
    0 -> int.to_string(int_part)
    _ -> {
      int.to_string(int_part) <> "." <> int.to_string(decimal_part)
    }
  }
}
