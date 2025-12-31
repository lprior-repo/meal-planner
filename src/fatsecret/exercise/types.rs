//! FatSecret SDK Exercise domain types

use crate::fatsecret::core::serde_utils::{
    deserialize_flexible_float, deserialize_flexible_int, deserialize_single_or_vec,
};
use serde::{Deserialize, Serialize};

// ============================================================================
// Opaque ID Types
// ============================================================================

/// Opaque type for FatSecret exercise IDs
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

/// Opaque type for FatSecret exercise entry IDs
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
    /// Unique exercise ID from FatSecret
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

/// Unix epoch date (1970-01-01)
const UNIX_EPOCH_DATE: (i32, u32, u32) = (1970, 1, 1);

/// Convert YYYY-MM-DD to days since epoch (date_int)
pub fn date_to_int(date: &str) -> Result<i32, String> {
    use chrono::NaiveDate;

    let epoch = NaiveDate::from_ymd_opt(UNIX_EPOCH_DATE.0, UNIX_EPOCH_DATE.1, UNIX_EPOCH_DATE.2)
        .ok_or_else(|| "Invalid epoch date".to_string())?;

    NaiveDate::parse_from_str(date, "%Y-%m-%d")
        .map_err(|e| format!("Invalid date format: {}", e))
        .and_then(|d| {
            let days = (d - epoch).num_days();
            i32::try_from(days).map_err(|_| format!("Date out of range: {} days since epoch", days))
        })
}

/// Convert days since epoch to YYYY-MM-DD
pub fn int_to_date(date_int: i32) -> Result<String, String> {
    use chrono::{Duration, NaiveDate};

    let epoch = NaiveDate::from_ymd_opt(UNIX_EPOCH_DATE.0, UNIX_EPOCH_DATE.1, UNIX_EPOCH_DATE.2)
        .ok_or_else(|| "Invalid epoch date".to_string())?;
    let date = epoch
        .checked_add_signed(Duration::days(i64::from(date_int)))
        .ok_or_else(|| format!("Date calculation overflow: {}", date_int))?;
    Ok(date.format("%Y-%m-%d").to_string())
}
