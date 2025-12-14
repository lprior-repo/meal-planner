/// FatSecret SDK Exercise domain types
///
/// This module defines the core types for the FatSecret Exercise API.
/// These types are independent from the Tandoor domain and represent
/// FatSecret's data structures for exercise tracking.
///
/// Opaque types are used for IDs to ensure type safety and prevent
/// accidental mixing of different ID types.
import birl
import gleam/option.{type Option}
import gleam/result

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
// Date Conversion Functions
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
  // Use birl to parse the date string (assumes UTC at midnight)
  use time <- result.try(birl.from_naive(date <> "T00:00:00"))

  // Convert to days since Unix epoch
  // birl.to_unix returns seconds, divide by 86400 to get days
  let seconds = birl.to_unix(time)
  Ok(seconds / 86_400)
}

/// Convert days since epoch to YYYY-MM-DD
///
/// Inverse of date_to_int. Always returns a valid date string.
/// Examples:
/// - 0 -> "1970-01-01"
/// - 1 -> "1970-01-02"
/// - 19723 -> "2024-01-01"
pub fn int_to_date(date_int: Int) -> String {
  // Convert days to seconds (Unix timestamp)
  let unix_seconds = date_int * 86_400

  // Create a birl Time from Unix seconds
  let time = birl.from_unix(unix_seconds)

  // Extract the date string (YYYY-MM-DD)
  birl.to_naive_date_string(time)
}
