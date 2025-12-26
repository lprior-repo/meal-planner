/// Exercise View Helpers
///
/// Utility functions for date handling, formatting, and calculations.
import birl
import gleam/float
import gleam/int
import gleam/list
import gleam/string
import meal_planner/cli/screens/exercise/model.{
  type DailySummary, type ExerciseDisplayEntry, DailySummary,
  ExerciseDisplayEntry,
}
import meal_planner/fatsecret/exercise/types as exercise_types

// ============================================================================
// Date Helpers
// ============================================================================

/// Get today's date as days since epoch
pub fn get_today_date_int() -> Int {
  let now = birl.now()
  let seconds = birl.to_unix(now)
  seconds / 86_400
}

/// Convert date_int to display string
pub fn date_int_to_string(date_int: Int) -> String {
  let seconds = date_int * 86_400
  let date = birl.from_unix(seconds)
  birl.to_iso8601(date)
  |> string.slice(0, 10)
}

/// Parse date string to date_int
pub fn parse_date_string(date_str: String) -> Result(Int, String) {
  case string.split(date_str, "-") {
    [year_str, month_str, day_str] -> {
      case int.parse(year_str), int.parse(month_str), int.parse(day_str) {
        Ok(_), Ok(_), Ok(_) -> {
          case birl.from_naive(date_str <> "T00:00:00") {
            Ok(dt) -> {
              let seconds = birl.to_unix(dt)
              Ok(seconds / 86_400)
            }
            Error(_) -> Error("Invalid date format")
          }
        }
        _, _, _ -> Error("Invalid date components")
      }
    }
    _ -> Error("Expected YYYY-MM-DD format")
  }
}

// ============================================================================
// Formatting Helpers
// ============================================================================

/// Format exercise entry for display
pub fn format_exercise_entry(
  entry: exercise_types.ExerciseEntry,
) -> ExerciseDisplayEntry {
  let duration_str = int.to_string(entry.duration_min) <> " min"
  let calories_str = float_to_string(entry.calories) <> " cal"

  ExerciseDisplayEntry(
    entry: entry,
    name_display: entry.exercise_name,
    duration_display: duration_str,
    calories_display: calories_str,
    summary_line: entry.exercise_name
      <> " - "
      <> duration_str
      <> " - "
      <> calories_str,
  )
}

/// Format float to string with 1 decimal
pub fn float_to_string(value: Float) -> String {
  let rounded = float.truncate(value *. 10.0) |> int.to_float
  float.to_string(rounded /. 10.0)
}

// ============================================================================
// Calculation Helpers
// ============================================================================

/// Calculate daily summary from entries
pub fn calculate_daily_summary(
  entries: List(exercise_types.ExerciseEntry),
) -> DailySummary {
  let total_calories =
    entries
    |> list.fold(0.0, fn(acc, e) { acc +. e.calories })

  let total_duration =
    entries
    |> list.fold(0, fn(acc, e) { acc + e.duration_min })

  let session_count = list.length(entries)

  let avg_calories = case session_count {
    0 -> 0.0
    n -> total_calories /. int.to_float(n)
  }

  DailySummary(
    total_calories: total_calories,
    total_duration: total_duration,
    session_count: session_count,
    avg_calories_per_session: avg_calories,
  )
}
