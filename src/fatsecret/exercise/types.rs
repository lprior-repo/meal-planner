//! FatSecret SDK Exercise domain types

use serde::{Deserialize, Serialize};
use crate::fatsecret::core::serde_utils::{
    deserialize_flexible_float,
    deserialize_flexible_int,
    deserialize_single_or_vec,
};

// ============================================================================
// Opaque ID Types
// ============================================================================

/// Opaque type for FatSecret exercise IDs
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct ExerciseId(String);

impl ExerciseId {
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

/// Opaque type for FatSecret exercise entry IDs
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct ExerciseEntryId(String);

impl ExerciseEntryId {
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

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
    pub exercise_id: ExerciseId,
    pub exercise_name: String,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub calories_per_hour: f64,
}

/// Wrapper for Exercise response
#[derive(Debug, Deserialize)]
pub struct ExerciseResponse {
    pub exercise: Exercise,
}

// ============================================================================
// Exercise Entry Types (User Diary)
// ============================================================================

/// Complete exercise diary entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseEntry {
    pub exercise_entry_id: ExerciseEntryId,
    pub exercise_id: ExerciseId,
    pub exercise_name: String,
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub duration_min: i32,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub calories: f64,
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub date_int: i32,
}

/// Input for creating a new exercise entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseEntryInput {
    pub exercise_id: ExerciseId,
    pub duration_min: i32,
    pub date_int: i32,
}

/// Update for an existing exercise entry
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ExerciseEntryUpdate {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub exercise_id: Option<ExerciseId>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub duration_min: Option<i32>,
}

// ============================================================================
// Summary Types
// ============================================================================

/// Daily exercise summary
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseDaySummary {
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub date_int: i32,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub exercise_calories: f64,
}

/// Monthly exercise summary
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseMonthSummary {
    #[serde(rename = "day", default, deserialize_with = "deserialize_single_or_vec")]
    pub days: Vec<ExerciseDaySummary>,
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub month: i32,
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub year: i32,
}

/// Wrapper for ExerciseEntry response (list)
#[derive(Debug, Deserialize)]
pub struct ExerciseEntriesResponse {
    #[serde(rename = "exercise_entry", default, deserialize_with = "deserialize_single_or_vec")]
    pub exercise_entries: Vec<ExerciseEntry>,
}

/// Wrapper for single ExerciseEntry response (used in create/edit)
#[derive(Debug, Deserialize)]
pub struct SingleExerciseEntryResponse {
    pub exercise_entry: ExerciseEntryIdOnly,
}

#[derive(Debug, Deserialize)]
pub struct ExerciseEntryIdOnly {
    pub exercise_entry_id: ExerciseEntryId,
}

/// Wrapper for ExerciseMonthSummary response
// ============================================================================
// Date Conversion Functions
// ============================================================================

/// Convert YYYY-MM-DD to days since epoch (date_int)
pub fn date_to_int(date: &str) -> Result<i32, String> {
    use chrono::NaiveDate;
    
    NaiveDate::parse_from_str(date, "%Y-%m-%d")
        .map_err(|e| format!("Invalid date format: {}", e))
        .map(|d| {
            let epoch = NaiveDate::from_ymd_opt(1970, 1, 1).unwrap();
            (d - epoch).num_days() as i32
        })
}

/// Convert days since epoch to YYYY-MM-DD
pub fn int_to_date(date_int: i32) -> Result<String, String> {
    use chrono::{Duration, NaiveDate};
    
    let epoch = NaiveDate::from_ymd_opt(1970, 1, 1).unwrap();
    let date = epoch.checked_add_signed(Duration::days(date_int as i64))
        .ok_or_else(|| format!("Date calculation overflow: {}", date_int))?;
    Ok(date.format("%Y-%m-%d").to_string())
}

#[derive(Debug, Deserialize)]
pub struct ExerciseMonthSummaryResponse {
    pub exercise_month: ExerciseMonthSummary,
}
