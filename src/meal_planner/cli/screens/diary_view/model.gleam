/// Diary View Model - Helper Functions
///
/// This module contains helper functions for working with the diary view model,
/// including date conversion utilities and cache validation.
///
/// Re-exports core types from fatsecret_diary.gleam for convenience.
import birl
import gleam/int
import gleam/string
import meal_planner/cli/screens/fatsecret_diary.{type DiaryModel}

// ============================================================================
// Re-exports
// ============================================================================

/// Re-export DiaryModel for external use
pub type DiaryModel =
  fatsecret_diary.DiaryModel

/// Re-export init function for model creation
pub fn init(today_date_int: Int) -> DiaryModel {
  fatsecret_diary.init(today_date_int)
}

// ============================================================================
// Constants
// ============================================================================

/// Number of days to cache food details
const food_cache_ttl_days = 7

// ============================================================================
// Date Utilities
// ============================================================================

/// Get current date as days since Unix epoch
pub fn today_as_date_int() -> Int {
  let now = birl.now()
  let seconds = birl.to_unix(now)
  seconds / 86_400
}

/// Convert date_int to displayable date string
pub fn date_int_to_string(date_int: Int) -> String {
  // Calculate date from days since epoch
  let seconds = date_int * 86_400
  let date = birl.from_unix(seconds)
  birl.to_iso8601(date)
  |> string.slice(0, 10)
}

/// Parse date string (YYYY-MM-DD) to date_int
pub fn parse_date_string(date_str: String) -> Result(Int, String) {
  case string.split(date_str, "-") {
    [year_str, month_str, day_str] -> {
      case int.parse(year_str), int.parse(month_str), int.parse(day_str) {
        Ok(_year), Ok(_month), Ok(_day) -> {
          case birl.from_naive(date_str <> "T00:00:00") {
            Ok(dt) -> {
              let seconds = birl.to_unix(dt)
              Ok(seconds / 86_400)
            }
            Error(_) -> Error("Invalid ISO date format")
          }
        }
        _, _, _ -> Error("Invalid date components")
      }
    }
    _ -> Error("Expected format: YYYY-MM-DD")
  }
}

// ============================================================================
// Cache Utilities
// ============================================================================

/// Check if cached food is still valid
pub fn is_cache_valid(cached_at: Int, current_time: Int) -> Bool {
  let ttl_seconds = food_cache_ttl_days * 86_400
  current_time - cached_at < ttl_seconds
}
