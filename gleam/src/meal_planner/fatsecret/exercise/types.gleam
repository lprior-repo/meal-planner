/// FatSecret SDK Exercise domain types
///
/// This module defines the core types for the FatSecret Exercise API.
/// These types are independent from the Tandoor domain and represent
/// FatSecret's data structures for exercise tracking.
///
/// Opaque types are used for IDs to ensure type safety and prevent
/// accidental mixing of different ID types.
import gleam/int
import gleam/option.{type Option}
import gleam/result
import gleam/string

// ============================================================================
// Opaque ID Types
// ============================================================================

/// Opaque type for FatSecret exercise IDs
pub opaque type ExerciseId {
  ExerciseId(String)
}

/// Create an ExerciseId from a string
pub fn exercise_id(id: String) -> ExerciseId {
  ExerciseId(id)
}

/// Convert ExerciseId to string (for API calls)
pub fn exercise_id_to_string(id: ExerciseId) -> String {
  case id {
    ExerciseId(s) -> s
  }
}

/// Opaque type for FatSecret exercise entry IDs
pub opaque type ExerciseEntryId {
  ExerciseEntryId(String)
}

/// Create an ExerciseEntryId from a string
pub fn exercise_entry_id(id: String) -> ExerciseEntryId {
  ExerciseEntryId(id)
}

/// Convert ExerciseEntryId to string (for API calls)
pub fn exercise_entry_id_to_string(id: ExerciseEntryId) -> String {
  case id {
    ExerciseEntryId(s) -> s
  }
}

// ============================================================================
// Exercise Information (Public Database)
// ============================================================================

/// Exercise details from exercises.get.v2 API
///
/// Contains information about a specific exercise type from the
/// FatSecret public exercise database (2-legged OAuth).
pub type Exercise {
  Exercise(
    /// Unique exercise identifier
    exercise_id: ExerciseId,
    /// Exercise name (e.g., "Running", "Cycling", "Swimming")
    exercise_name: String,
    /// Estimated calories burned per hour
    calories_per_hour: Float,
  )
}

// ============================================================================
// Exercise Entry Types (User Diary)
// ============================================================================

/// Complete exercise diary entry from exercise_entries.get.v2
///
/// Represents a single exercise logged to the user's diary (3-legged OAuth).
/// All nutrition values are stored as returned from the API.
pub type ExerciseEntry {
  ExerciseEntry(
    /// Unique entry ID from FatSecret
    exercise_entry_id: ExerciseEntryId,
    /// Exercise ID (references Exercise in public database)
    exercise_id: ExerciseId,
    /// Exercise display name
    exercise_name: String,
    /// Duration in minutes
    duration_min: Int,
    /// Calories burned for this duration
    calories: Float,
    /// Date as days since Unix epoch (0 = 1970-01-01)
    date_int: Int,
  )
}

/// Input for creating or editing an exercise entry
///
/// Used with exercise_entry.create and exercise_entry.edit endpoints.
pub type ExerciseEntryInput {
  ExerciseEntryInput(
    /// Exercise ID from public database
    exercise_id: ExerciseId,
    /// Duration in minutes
    duration_min: Int,
    /// Date as days since Unix epoch
    date_int: Int,
  )
}

/// Update for an existing exercise entry
///
/// Used with exercise_entry.edit endpoint.
/// Allows updating exercise type and/or duration.
pub type ExerciseEntryUpdate {
  ExerciseEntryUpdate(
    exercise_id: Option(ExerciseId),
    duration_min: Option(Int),
  )
}

// ============================================================================
// Summary Types
// ============================================================================

/// Daily exercise summary
///
/// Aggregated totals for a single day's exercise entries.
pub type ExerciseDaySummary {
  ExerciseDaySummary(date_int: Int, exercise_calories: Float)
}

/// Monthly exercise summary
///
/// Contains a summary for each day in the month with exercise logged.
pub type ExerciseMonthSummary {
  ExerciseMonthSummary(days: List(ExerciseDaySummary), month: Int, year: Int)
}

// ============================================================================
// Date Conversion Functions (Re-use from diary module)
// ============================================================================

/// Convert YYYY-MM-DD to days since epoch (date_int)
///
/// FatSecret API uses date_int which is the number of days since 1970-01-01.
/// Examples:
/// - "1970-01-01" -> 0
/// - "1970-01-02" -> 1
/// - "2024-01-01" -> 19723
///
/// Returns Error if date format is invalid.
pub fn date_to_int(date: String) -> Result(Int, Nil) {
  case string.split(date, "-") {
    [year_str, month_str, day_str] -> {
      use year <- result.try(int.parse(year_str))
      use month <- result.try(int.parse(month_str))
      use day <- result.try(int.parse(day_str))

      // Validate ranges
      case
        year >= 1970
        && year <= 2100
        && month >= 1
        && month <= 12
        && day >= 1
        && day <= 31
      {
        True -> Ok(days_since_epoch(year, month, day))
        False -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}

/// Convert days since epoch to YYYY-MM-DD
///
/// Inverse of date_to_int. Always returns a valid date string.
/// Examples:
/// - 0 -> "1970-01-01"
/// - 1 -> "1970-01-02"
/// - 19723 -> "2024-01-01"
pub fn int_to_date(date_int: Int) -> String {
  let #(year, month, day) = epoch_to_date(date_int)

  // Format with zero padding
  let year_str = int.to_string(year)
  let month_str = pad_zero(month)
  let day_str = pad_zero(day)

  year_str <> "-" <> month_str <> "-" <> day_str
}

// ============================================================================
// Internal Date Calculation Helpers
// ============================================================================

/// Calculate days since 1970-01-01
fn days_since_epoch(year: Int, month: Int, day: Int) -> Int {
  let years_since_epoch = year - 1970
  let days_from_years = years_since_epoch * 365

  // Account for leap years (simplified)
  let leap_days = years_since_epoch / 4

  // Days from months (simplified - assumes 30.4 days per month average)
  let days_from_months = case month {
    1 -> 0
    2 -> 31
    3 -> 59
    4 -> 90
    5 -> 120
    6 -> 151
    7 -> 181
    8 -> 212
    9 -> 243
    10 -> 273
    11 -> 304
    12 -> 334
    _ -> 0
  }

  // Add leap day if after Feb in a leap year
  let leap_day_adjustment = case is_leap_year(year) && month > 2 {
    True -> 1
    False -> 0
  }

  days_from_years + leap_days + days_from_months + leap_day_adjustment + day - 1
}

/// Convert days since epoch back to (year, month, day)
fn epoch_to_date(days: Int) -> #(Int, Int, Int) {
  // Estimate year (365.25 days per year average)
  let year_estimate = 1970 + days / 365
  let year = find_year(days, year_estimate)

  // Calculate days into the year
  let days_at_year_start = days_since_epoch(year, 1, 1)
  let day_of_year = days - days_at_year_start + 1

  // Find month and day
  let #(month, day) = day_of_year_to_month_day(day_of_year, year)

  #(year, month, day)
}

/// Find the correct year for a given number of days
fn find_year(days: Int, estimate: Int) -> Int {
  let days_at_estimate = days_since_epoch(estimate, 1, 1)
  case days >= days_at_estimate {
    True -> {
      let next_year_days = days_since_epoch(estimate + 1, 1, 1)
      case days < next_year_days {
        True -> estimate
        False -> find_year(days, estimate + 1)
      }
    }
    False -> find_year(days, estimate - 1)
  }
}

/// Convert day of year to (month, day)
fn day_of_year_to_month_day(day_of_year: Int, year: Int) -> #(Int, Int) {
  let days_in_month = case is_leap_year(year) {
    True -> [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    False -> [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  }

  find_month_day(day_of_year, days_in_month, 1, 0)
}

/// Recursively find month and day from day of year
fn find_month_day(
  remaining: Int,
  days_in_months: List(Int),
  current_month: Int,
  accumulated: Int,
) -> #(Int, Int) {
  case days_in_months {
    [] -> #(12, 31)
    // Fallback
    [days_in_month, ..rest] -> {
      case remaining <= accumulated + days_in_month {
        True -> #(current_month, remaining - accumulated)
        False ->
          find_month_day(
            remaining,
            rest,
            current_month + 1,
            accumulated + days_in_month,
          )
      }
    }
  }
}

/// Check if a year is a leap year
fn is_leap_year(year: Int) -> Bool {
  case year % 4 {
    0 ->
      case year % 100 {
        0 ->
          case year % 400 {
            0 -> True
            _ -> False
          }
        _ -> True
      }
    _ -> False
  }
}

/// Pad single digit numbers with leading zero
fn pad_zero(n: Int) -> String {
  case n < 10 {
    True -> "0" <> int.to_string(n)
    False -> int.to_string(n)
  }
}
