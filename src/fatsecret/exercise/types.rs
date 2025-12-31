//! Type definitions for `FatSecret` Exercise domain.
//!
//! This module defines all data structures used in the exercise APIs, including:
//!
//! - Public exercise database types ([`Exercise`])
//! - User diary entry types ([`ExerciseEntry`], [`ExerciseEntryInput`])
//! - Summary types ([`ExerciseMonthSummary`], [`ExerciseDaySummary`])
//! - Opaque ID types ([`ExerciseId`], [`ExerciseEntryId`])
//! - Date conversion utilities ([`date_to_int`], [`int_to_date`])
//!
//! # Key Types
//!
//! ## Core Domain Types
//!
//! - [`Exercise`] - Exercise details from public database (name, calories/hour)
//! - [`ExerciseEntry`] - Complete user diary entry (exercise, duration, calories, date)
//! - [`ExerciseEntryInput`] - Input for creating a new exercise entry
//! - [`ExerciseEntryUpdate`] - Partial update for existing entry
//!
//! ## Summary Types
//!
//! - [`ExerciseMonthSummary`] - Monthly breakdown with daily totals
//! - [`ExerciseDaySummary`] - Single day's exercise total
//!
//! ## ID Types
//!
//! - [`ExerciseId`] - Opaque ID for exercises in the public database
//! - [`ExerciseEntryId`] - Opaque ID for user's diary entries
//!
//! # Date Format
//!
//! `FatSecret` uses `date_int`: days since Unix epoch (1970-01-01).
//!
//! - **Example**: `19723` = 2024-01-01 (19,723 days after 1970-01-01)
//!
//! Use helper functions to convert:
//!
//! - [`date_to_int("2024-01-01")`] → `19723`
//! - [`int_to_date(19723)`] → `"2024-01-01"`
//!
//! # Usage Example
//!
//! ```rust
//! use meal_planner::fatsecret::exercise::types::{
//!     ExerciseId, ExerciseEntryInput, date_to_int, int_to_date,
//! };
//!
//! # fn example() -> Result<(), String> {
//! // Create an exercise entry for today
//! let `date_int` = date_to_int("2024-01-15")?;
//! let input = ExerciseEntryInput {
//!     exercise_id: ExerciseId::new("12345"),
//!     duration_min: 30,
//!     `date_int`,
//! };
//!
//! // Convert `date_int` back to human-readable format
//! let date_str = int_to_date(`date_int`)?;
//! assert_eq!(date_str, "2024-01-15");
//! # Ok(())
//! # }
//! ```
//!
//! # Serialization
//!
//! All types implement `Serialize` and `Deserialize` with special handling for
//! `FatSecret`'s API quirks:
//!
//! - **Flexible numbers**: API sometimes returns strings for numeric fields
//!   (e.g., `"123.45"` instead of `123.45`). Custom deserializers handle both.
//! - **Single-or-array**: API returns single object OR array depending on count
//!   (e.g., one exercise entry vs multiple). Custom deserializers normalize to `Vec<T>`.
//!
//! # API Response Wrappers
//!
//! `FatSecret` wraps responses in container objects:
//!
//! - [`ExerciseResponse`] - Wraps [`Exercise`]
//! - [`ExerciseEntriesResponse`] - Wraps `Vec<ExerciseEntry>`
//! - [`SingleExerciseEntryResponse`] - Wraps single entry (create/edit)
//! - [`ExerciseMonthSummaryResponse`] - Wraps [`ExerciseMonthSummary`]
//!
//! These are internal to the client module - public API returns unwrapped types.

use crate::fatsecret::core::serde_utils::{
    deserialize_flexible_float, deserialize_flexible_int, deserialize_single_or_vec,
};
use serde::{Deserialize, Serialize};

// ============================================================================
// Opaque ID Types
// ============================================================================

/// Opaque type for `FatSecret` exercise IDs
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct ExerciseId(String);

impl ExerciseId {
    /// Creates a new ExerciseId from the given value
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the exercise ID as a string slice
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

/// Opaque type for `FatSecret` exercise entry IDs
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct ExerciseEntryId(String);

impl ExerciseEntryId {
    /// Creates a new ExerciseEntryId from the given value
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the exercise entry ID as a string slice
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

// ============================================================================
// Exercise Information (Public Database)
// ============================================================================

/// Exercise details from exercises.get.v2 API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Exercise {
    /// Unique exercise ID from `FatSecret`
    pub exercise_id: ExerciseId,
    /// Name of the exercise
    pub exercise_name: String,
    /// Calories burned per hour for this exercise
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub calories_per_hour: f64,
}

/// Wrapper for Exercise response
#[derive(Debug, Deserialize)]
pub struct ExerciseResponse {
    /// The exercise data returned from the API
    pub exercise: Exercise,
}

// ============================================================================
// Exercise Entry Types (User Diary)
// ============================================================================

/// Complete exercise diary entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseEntry {
    /// Unique ID for this diary entry
    pub exercise_entry_id: ExerciseEntryId,
    /// Reference to the exercise type
    pub exercise_id: ExerciseId,
    /// Name of the exercise performed
    pub exercise_name: String,
    /// Duration of the exercise in minutes
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub duration_min: i32,
    /// Total calories burned during this exercise session
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub calories: f64,
    /// Date as days since Unix epoch (1970-01-01)
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub date_int: i32,
}

/// Input for creating a new exercise entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseEntryInput {
    /// ID of the exercise to log
    pub exercise_id: ExerciseId,
    /// Duration of the exercise in minutes
    pub duration_min: i32,
    /// Date as days since Unix epoch (1970-01-01)
    pub date_int: i32,
}

/// Update for an existing exercise entry
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ExerciseEntryUpdate {
    /// New exercise ID to change the exercise type (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub exercise_id: Option<ExerciseId>,
    /// New duration in minutes (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub duration_min: Option<i32>,
}

// ============================================================================
// Summary Types
// ============================================================================

/// Daily exercise summary
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseDaySummary {
    /// Date as days since Unix epoch (1970-01-01)
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub date_int: i32,
    /// Total calories burned from exercise on this day
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub exercise_calories: f64,
}

/// Monthly exercise summary
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseMonthSummary {
    /// Daily summaries for days with exercise logged
    #[serde(
        rename = "day",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub days: Vec<ExerciseDaySummary>,
    /// Month number (1-12)
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub month: i32,
    /// Four-digit year
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub year: i32,
}

/// Wrapper for ExerciseEntry response (list)
#[derive(Debug, Deserialize)]
pub struct ExerciseEntriesResponse {
    /// List of exercise entries returned from the API
    #[serde(
        rename = "exercise_entry",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub exercise_entries: Vec<ExerciseEntry>,
}

/// Wrapper for single ExerciseEntry response (used in create/edit)
#[derive(Debug, Deserialize)]
pub struct SingleExerciseEntryResponse {
    /// The created or updated exercise entry
    pub exercise_entry: ExerciseEntryIdOnly,
}

/// Minimal exercise entry response containing only the ID
#[derive(Debug, Deserialize)]
pub struct ExerciseEntryIdOnly {
    /// ID of the exercise entry
    pub exercise_entry_id: ExerciseEntryId,
}

/// Wrapper for ExerciseMonthSummary response
#[derive(Debug, Deserialize)]
pub struct ExerciseMonthSummaryResponse {
    /// The monthly exercise summary data
    pub exercise_month: ExerciseMonthSummary,
}

// ============================================================================
// Date Conversion Functions
// ============================================================================

/// Unix epoch date (1970-01-01) - constant for date calculations
const UNIX_EPOCH_DATE: (i32, u32, u32) = (1970, 1, 1);

/// Convert YYYY-MM-DD to days since epoch (`date_int`)
pub fn date_to_int(date: &str) -> Result<i32, String> {
    use chrono::NaiveDate;

    NaiveDate::parse_from_str(date, "%Y-%m-%d")
        .map_err(|e| format!("Invalid date format: {e}"))
        .and_then(|d| {
            let epoch =
                NaiveDate::from_ymd_opt(UNIX_EPOCH_DATE.0, UNIX_EPOCH_DATE.1, UNIX_EPOCH_DATE.2)
                    .ok_or_else(|| "Invalid epoch date".to_string())?;
            let days = (d - epoch).num_days();
            i32::try_from(days).map_err(|_| format!("Date too far from epoch: {days} days"))
        })
}

/// Convert days since epoch to YYYY-MM-DD
pub fn int_to_date(date_int: i32) -> Result<String, String> {
    use chrono::{Duration, NaiveDate};

    let epoch = NaiveDate::from_ymd_opt(UNIX_EPOCH_DATE.0, UNIX_EPOCH_DATE.1, UNIX_EPOCH_DATE.2)
        .ok_or_else(|| "Invalid epoch date".to_string())?;
    let date = epoch
        .checked_add_signed(Duration::days(i64::from(date_int)))
        .ok_or_else(|| format!("Date calculation overflow: {date_int}"))?;
    Ok(date.format("%Y-%m-%d").to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    // ============================================================================
    // ExerciseId tests
    // ============================================================================

    #[test]
    fn test_exercise_id_new() {
        let id = ExerciseId::new("12345");
        assert_eq!(id.as_str(), "12345");
    }

    #[test]
    fn test_exercise_id_equality() {
        let id1 = ExerciseId::new("same");
        let id2 = ExerciseId::new("same");
        let id3 = ExerciseId::new("different");
        assert_eq!(id1, id2);
        assert_ne!(id1, id3);
    }

    #[test]
    fn test_exercise_id_hash() {
        use std::collections::HashSet;
        let mut set = HashSet::new();
        set.insert(ExerciseId::new("id1"));
        set.insert(ExerciseId::new("id2"));
        set.insert(ExerciseId::new("id1")); // duplicate
        assert_eq!(set.len(), 2);
    }

    #[test]
    fn test_exercise_id_serde() {
        let id = ExerciseId::new("serde-test");
        let json = serde_json::to_string(&id).unwrap();
        assert_eq!(json, "\"serde-test\"");
        let parsed: ExerciseId = serde_json::from_str(&json).unwrap();
        assert_eq!(id, parsed);
    }

    // ============================================================================
    // ExerciseEntryId tests
    // ============================================================================

    #[test]
    fn test_exercise_entry_id_new() {
        let id = ExerciseEntryId::new("entry123");
        assert_eq!(id.as_str(), "entry123");
    }

    #[test]
    fn test_exercise_entry_id_equality() {
        let id1 = ExerciseEntryId::new("same");
        let id2 = ExerciseEntryId::new("same");
        assert_eq!(id1, id2);
    }

    // ============================================================================
    // Exercise tests
    // ============================================================================

    #[test]
    fn test_exercise_deserialize() {
        let json = r#"{
            "exercise_id": "123",
            "exercise_name": "Running",
            "calories_per_hour": "600"
        }"#;
        let exercise: Exercise = serde_json::from_str(json).unwrap();
        assert_eq!(exercise.exercise_id.as_str(), "123");
        assert_eq!(exercise.exercise_name, "Running");
        assert!((exercise.calories_per_hour - 600.0).abs() < 0.01);
    }

    #[test]
    fn test_exercise_deserialize_numeric() {
        let json = r#"{
            "exercise_id": "456",
            "exercise_name": "Swimming",
            "calories_per_hour": 500.5
        }"#;
        let exercise: Exercise = serde_json::from_str(json).unwrap();
        assert!((exercise.calories_per_hour - 500.5).abs() < 0.01);
    }

    // ============================================================================
    // ExerciseEntry tests
    // ============================================================================

    #[test]
    fn test_exercise_entry_deserialize() {
        let json = r#"{
            "exercise_entry_id": "entry1",
            "exercise_id": "123",
            "exercise_name": "Running",
            "duration_min": "30",
            "calories": "300",
            "date_int": "19723"
        }"#;
        let entry: ExerciseEntry = serde_json::from_str(json).unwrap();
        assert_eq!(entry.exercise_entry_id.as_str(), "entry1");
        assert_eq!(entry.exercise_id.as_str(), "123");
        assert_eq!(entry.duration_min, 30);
        assert!((entry.calories - 300.0).abs() < 0.01);
        assert_eq!(entry.date_int, 19723);
    }

    #[test]
    fn test_exercise_entry_deserialize_numeric() {
        let json = r#"{
            "exercise_entry_id": "entry2",
            "exercise_id": "456",
            "exercise_name": "Cycling",
            "duration_min": 45,
            "calories": 450.5,
            "date_int": 19724
        }"#;
        let entry: ExerciseEntry = serde_json::from_str(json).unwrap();
        assert_eq!(entry.duration_min, 45);
        assert!((entry.calories - 450.5).abs() < 0.01);
    }

    // ============================================================================
    // ExerciseEntryInput tests
    // ============================================================================

    #[test]
    fn test_exercise_entry_input() {
        let input = ExerciseEntryInput {
            exercise_id: ExerciseId::new("123"),
            duration_min: 30,
            date_int: 19723,
        };
        let json = serde_json::to_string(&input).unwrap();
        assert!(json.contains("123"));
        assert!(json.contains("30"));
    }

    // ============================================================================
    // ExerciseEntryUpdate tests
    // ============================================================================

    #[test]
    fn test_exercise_entry_update_default() {
        let update = ExerciseEntryUpdate::default();
        assert!(update.exercise_id.is_none());
        assert!(update.duration_min.is_none());
    }

    #[test]
    fn test_exercise_entry_update_partial() {
        let update = ExerciseEntryUpdate {
            exercise_id: None,
            duration_min: Some(45),
        };
        let json = serde_json::to_string(&update).unwrap();
        assert!(json.contains("45"));
        assert!(!json.contains("exercise_id"));
    }

    // ============================================================================
    // ExerciseDaySummary tests
    // ============================================================================

    #[test]
    fn test_exercise_day_summary_deserialize() {
        let json = r#"{
            "date_int": "19723",
            "exercise_calories": "500"
        }"#;
        let summary: ExerciseDaySummary = serde_json::from_str(json).unwrap();
        assert_eq!(summary.date_int, 19723);
        assert!((summary.exercise_calories - 500.0).abs() < 0.01);
    }

    // ============================================================================
    // ExerciseMonthSummary tests
    // ============================================================================

    #[test]
    fn test_exercise_month_summary_single_day() {
        let json = r#"{
            "day": {
                "date_int": "19723",
                "exercise_calories": "300"
            },
            "month": "1",
            "year": "2024"
        }"#;
        let summary: ExerciseMonthSummary = serde_json::from_str(json).unwrap();
        assert_eq!(summary.days.len(), 1);
        assert_eq!(summary.month, 1);
        assert_eq!(summary.year, 2024);
    }

    #[test]
    fn test_exercise_month_summary_multiple_days() {
        let json = r#"{
            "day": [
                {"date_int": "19723", "exercise_calories": "300"},
                {"date_int": "19724", "exercise_calories": "400"}
            ],
            "month": "1",
            "year": "2024"
        }"#;
        let summary: ExerciseMonthSummary = serde_json::from_str(json).unwrap();
        assert_eq!(summary.days.len(), 2);
    }

    #[test]
    fn test_exercise_month_summary_empty() {
        let json = r#"{
            "month": "1",
            "year": "2024"
        }"#;
        let summary: ExerciseMonthSummary = serde_json::from_str(json).unwrap();
        assert!(summary.days.is_empty());
    }

    // ============================================================================
    // Response wrapper tests
    // ============================================================================

    #[test]
    fn test_exercise_response() {
        let json = r#"{
            "exercise": {
                "exercise_id": "123",
                "exercise_name": "Running",
                "calories_per_hour": "600"
            }
        }"#;
        let response: ExerciseResponse = serde_json::from_str(json).unwrap();
        assert_eq!(response.exercise.exercise_name, "Running");
    }

    #[test]
    fn test_exercise_entries_response_single() {
        let json = r#"{
            "exercise_entry": {
                "exercise_entry_id": "entry1",
                "exercise_id": "123",
                "exercise_name": "Running",
                "duration_min": "30",
                "calories": "300",
                "date_int": "19723"
            }
        }"#;
        let response: ExerciseEntriesResponse = serde_json::from_str(json).unwrap();
        assert_eq!(response.exercise_entries.len(), 1);
    }

    #[test]
    fn test_exercise_entries_response_multiple() {
        let json = r#"{
            "exercise_entry": [
                {
                    "exercise_entry_id": "entry1",
                    "exercise_id": "123",
                    "exercise_name": "Running",
                    "duration_min": "30",
                    "calories": "300",
                    "date_int": "19723"
                },
                {
                    "exercise_entry_id": "entry2",
                    "exercise_id": "456",
                    "exercise_name": "Cycling",
                    "duration_min": "45",
                    "calories": "450",
                    "date_int": "19723"
                }
            ]
        }"#;
        let response: ExerciseEntriesResponse = serde_json::from_str(json).unwrap();
        assert_eq!(response.exercise_entries.len(), 2);
    }

    #[test]
    fn test_single_exercise_entry_response() {
        let json = r#"{
            "exercise_entry": {
                "exercise_entry_id": "new-entry"
            }
        }"#;
        let response: SingleExerciseEntryResponse = serde_json::from_str(json).unwrap();
        assert_eq!(response.exercise_entry.exercise_entry_id.as_str(), "new-entry");
    }

    #[test]
    fn test_exercise_month_summary_response() {
        let json = r#"{
            "exercise_month": {
                "day": [],
                "month": "6",
                "year": "2024"
            }
        }"#;
        let response: ExerciseMonthSummaryResponse = serde_json::from_str(json).unwrap();
        assert_eq!(response.exercise_month.month, 6);
        assert_eq!(response.exercise_month.year, 2024);
    }

    // ============================================================================
    // Date conversion tests
    // ============================================================================

    #[test]
    fn test_date_to_int_epoch() {
        assert_eq!(date_to_int("1970-01-01").unwrap(), 0);
    }

    #[test]
    fn test_date_to_int_modern() {
        assert_eq!(date_to_int("2024-01-01").unwrap(), 19723);
    }

    #[test]
    fn test_date_to_int_invalid() {
        assert!(date_to_int("invalid").is_err());
        assert!(date_to_int("2024/01/01").is_err());
    }

    #[test]
    fn test_int_to_date_epoch() {
        assert_eq!(int_to_date(0).unwrap(), "1970-01-01");
    }

    #[test]
    fn test_int_to_date_modern() {
        assert_eq!(int_to_date(19723).unwrap(), "2024-01-01");
    }

    #[test]
    fn test_date_roundtrip() {
        let date = "2024-06-15";
        let int = date_to_int(date).unwrap();
        let back = int_to_date(int).unwrap();
        assert_eq!(date, back);
    }
}
