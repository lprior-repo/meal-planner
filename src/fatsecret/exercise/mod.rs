//! FatSecret SDK Exercise domain types
//!
//! This module defines the core types for the FatSecret Exercise API.
//! These types are independent from the Tandoor domain and represent
//! FatSecret's data structures for exercise tracking.
//!
//! Opaque types are used for IDs to ensure type safety and prevent
//! accidental mixing of different ID types.

use chrono::NaiveDate;
use serde::{Deserialize, Serialize};
use std::fmt;

// ============================================================================
// Opaque ID Types
// ============================================================================

/// Opaque type for FatSecret exercise IDs
///
/// Represents an exercise type in the FatSecret public database.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct ExerciseId(String);

impl ExerciseId {
    /// Create an ExerciseId from a string
    pub fn new(id: impl Into<String>) -> Self {
        ExerciseId(id.into())
    }

    /// Get the underlying string value
    pub fn as_str(&self) -> &str {
        &self.0
    }

    /// Convert to owned String
    pub fn into_string(self) -> String {
        self.0
    }
}

impl fmt::Display for ExerciseId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl From<String> for ExerciseId {
    fn from(s: String) -> Self {
        ExerciseId(s)
    }
}

impl From<&str> for ExerciseId {
    fn from(s: &str) -> Self {
        ExerciseId(s.to_string())
    }
}

/// Opaque type for FatSecret exercise entry IDs
///
/// Represents a specific exercise entry in a user's diary.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct ExerciseEntryId(String);

impl ExerciseEntryId {
    /// Create an ExerciseEntryId from a string
    pub fn new(id: impl Into<String>) -> Self {
        ExerciseEntryId(id.into())
    }

    /// Get the underlying string value
    pub fn as_str(&self) -> &str {
        &self.0
    }

    /// Convert to owned String
    pub fn into_string(self) -> String {
        self.0
    }
}

impl fmt::Display for ExerciseEntryId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl From<String> for ExerciseEntryId {
    fn from(s: String) -> Self {
        ExerciseEntryId(s)
    }
}

impl From<&str> for ExerciseEntryId {
    fn from(s: &str) -> Self {
        ExerciseEntryId(s.to_string())
    }
}

// ============================================================================
// Exercise Information (Public Database)
// ============================================================================

/// Exercise details from exercises.get.v2 API
///
/// Contains information about a specific exercise type from the
/// FatSecret public exercise database (2-legged OAuth).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Exercise {
    /// Unique exercise identifier
    pub exercise_id: ExerciseId,
    /// Exercise name (e.g., "Running", "Cycling", "Swimming")
    pub exercise_name: String,
    /// Estimated calories burned per hour
    pub calories_per_hour: f64,
}

// ============================================================================
// Exercise Entry Types (User Diary)
// ============================================================================

/// Complete exercise diary entry from exercise_entries.get.v2
///
/// Represents a single exercise logged to the user's diary (3-legged OAuth).
/// All nutrition values are stored as returned from the API.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseEntry {
    /// Unique entry ID from FatSecret
    pub exercise_entry_id: ExerciseEntryId,
    /// Exercise ID (references Exercise in public database)
    pub exercise_id: ExerciseId,
    /// Exercise display name
    pub exercise_name: String,
    /// Duration in minutes
    pub duration_min: i32,
    /// Calories burned for this duration
    pub calories: f64,
    /// Date as days since Unix epoch (0 = 1970-01-01)
    pub date_int: i64,
}

/// Input for creating or editing an exercise entry
///
/// Used with exercise_entry.create and exercise_entry.edit endpoints.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseEntryInput {
    /// Exercise ID from public database
    pub exercise_id: ExerciseId,
    /// Duration in minutes
    pub duration_min: i32,
    /// Date as days since Unix epoch
    pub date_int: i64,
}

/// Update for an existing exercise entry
///
/// Used with exercise_entry.edit endpoint.
/// Allows updating exercise type and/or duration.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseEntryUpdate {
    /// New exercise ID (optional)
    pub exercise_id: Option<ExerciseId>,
    /// New duration in minutes (optional)
    pub duration_min: Option<i32>,
}

// ============================================================================
// Summary Types
// ============================================================================

/// Daily exercise summary
///
/// Aggregated totals for a single day's exercise entries.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseDaySummary {
    /// Date as days since Unix epoch
    pub date_int: i64,
    /// Total calories burned from exercise
    pub exercise_calories: f64,
}

/// Monthly exercise summary
///
/// Contains a summary for each day in the month with exercise logged.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseMonthSummary {
    /// List of daily exercise summaries
    pub days: Vec<ExerciseDaySummary>,
    /// Month (1-12)
    pub month: u32,
    /// Year
    pub year: i32,
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
/// Returns None if date format is invalid.
pub fn date_to_int(date: &str) -> Option<i64> {
    let parsed = NaiveDate::parse_from_str(date, "%Y-%m-%d").ok()?;
    let epoch = NaiveDate::from_ymd_opt(1970, 1, 1)?;
    Some(parsed.signed_duration_since(epoch).num_days())
}

/// Convert days since epoch to YYYY-MM-DD
///
/// Inverse of date_to_int. Returns None if the date would be invalid.
/// Examples:
/// - 0 -> "1970-01-01"
/// - 1 -> "1970-01-02"
/// - 19723 -> "2024-01-01"
pub fn int_to_date(date_int: i64) -> Option<String> {
    let epoch = NaiveDate::from_ymd_opt(1970, 1, 1)?;
    let date = epoch.checked_add_signed(chrono::Duration::days(date_int))?;
    Some(date.format("%Y-%m-%d").to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_exercise_id_creation() {
        let id = ExerciseId::new("running_123");
        assert_eq!(id.as_str(), "running_123");
    }

    #[test]
    fn test_exercise_entry_id_creation() {
        let id = ExerciseEntryId::new("entry_456");
        assert_eq!(id.as_str(), "entry_456");
    }

    #[test]
    fn test_exercise_serialization() {
        let exercise = Exercise {
            exercise_id: ExerciseId::new("1"),
            exercise_name: "Running".to_string(),
            calories_per_hour: 600.0,
        };

        let json = serde_json::to_string(&exercise).unwrap();
        let deserialized: Exercise = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.exercise_name, "Running");
    }

    #[test]
    fn test_date_conversions() {
        // Test epoch
        assert_eq!(date_to_int("1970-01-01"), Some(0));

        // Test day after epoch
        assert_eq!(date_to_int("1970-01-02"), Some(1));

        // Test a known date (2024-01-01)
        let date_int = date_to_int("2024-01-01").unwrap();
        assert_eq!(int_to_date(date_int), Some("2024-01-01".to_string()));

        // Round-trip test
        let original = "2024-06-15";
        let as_int = date_to_int(original).unwrap();
        let back = int_to_date(as_int).unwrap();
        assert_eq!(back, original);
    }

    #[test]
    fn test_invalid_date() {
        assert_eq!(date_to_int("invalid"), None);
        assert_eq!(date_to_int("2024-13-01"), None);
    }
}
