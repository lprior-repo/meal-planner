/// Diary formatting functions for display output
///
/// This module provides formatting utilities for displaying food diary entries
/// and nutrition summaries in a consistent, readable format.
import gleam/float
import gleam/string
import meal_planner/cli/domains/diary/types.{type DayNutrition}
import meal_planner/fatsecret/diary/types as fatsecret_types

/// Format a single food entry for display
///
/// Creates a formatted string showing the food name (truncated to 30 chars if needed)
/// followed by calories and macronutrients (protein, carbs, fat).
///
/// Example output:
/// "Chicken Breast               | 165.0 cal | P:31.0g C:0.0g F:3.6g"
pub fn format_food_entry_row(entry: fatsecret_types.FoodEntry) -> String {
  let padded_name = case string.length(entry.food_entry_name) {
    len if len >= 30 -> string.slice(entry.food_entry_name, 0, 27) <> "..."
    len -> entry.food_entry_name <> string.repeat(" ", 30 - len)
  }
  padded_name
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
/// Converts a float value to a string representation.
/// Note: Currently uses Gleam's default float formatting.
fn format_float(value: Float) -> String {
  float.to_string(value)
}
