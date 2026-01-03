//! Unit tests for the `FatSecret` Exercise domain
//!
//! Test coverage:
//! - Type deserialization (flexible numeric fields, single-or-vec)
//! - Date conversion utilities (date_to_int, int_to_date)
//! - Summary type handling (monthly/daily summaries)
//! - Error cases (invalid dates, malformed JSON, boundary conditions)
//! - Opaque ID types (ExerciseId, ExerciseEntryId)

// =============================================================================
// TEST-ONLY LINT OVERRIDES
// =============================================================================
#![allow(clippy::unwrap_used)]
#![allow(clippy::expect_used)]
#![allow(clippy::panic)]

use super::types::*;
use serde_json;

// =============================================================================
// Test Fixtures
// =============================================================================

mod fixtures {
    /// Exercise response with numeric fields as numbers
    pub const EXERCISE_NUMERIC: &str = r#"{
        "exercise_id": "12345",
        "exercise_name": "Running",
        "calories_per_hour": 600.5
    }"#;

    /// Exercise response with numeric fields as strings (API quirk)
    pub const EXERCISE_STRING_NUMBERS: &str = r#"{
        "exercise_id": "12345",
        "exercise_name": "Running",
        "calories_per_hour": "600.5"
    }"#;

    /// Exercise entry with all numeric fields
    pub const EXERCISE_ENTRY_NUMERIC: &str = r#"{
        "exercise_entry_id": "67890",
        "exercise_id": "12345",
        "exercise_name": "Running",
        "duration_min": 30,
        "calories": 300.25,
        "date_int": 19723
    }"#;

    /// Exercise entry with numeric fields as strings
    pub const EXERCISE_ENTRY_STRING_NUMBERS: &str = r#"{
        "exercise_entry_id": "67890",
        "exercise_id": "12345",
        "exercise_name": "Running",
        "duration_min": "30",
        "calories": "300.25",
        "date_int": "19723"
    }"#;

    /// Single exercise entry in array wrapper
    pub const SINGLE_ENTRY_RESPONSE: &str = r#"{
        "exercise_entry": {
            "exercise_entry_id": "67890",
            "exercise_id": "12345",
            "exercise_name": "Running",
            "duration_min": 30,
            "calories": 300.25,
            "date_int": 19723
        }
    }"#;

    /// Multiple exercise entries in array wrapper
    pub const MULTIPLE_ENTRIES_RESPONSE: &str = r#"{
        "exercise_entry": [
            {
                "exercise_entry_id": "67890",
                "exercise_id": "12345",
                "exercise_name": "Running",
                "duration_min": 30,
                "calories": 300.25,
                "date_int": 19723
            },
            {
                "exercise_entry_id": "67891",
                "exercise_id": "12346",
                "exercise_name": "Cycling",
                "duration_min": 45,
                "calories": 450.5,
                "date_int": 19723
            }
        ]
    }"#;

    /// Empty exercise entries response
    pub const EMPTY_ENTRIES_RESPONSE: &str = r#"{}"#;

    /// Single day summary
    pub const SINGLE_DAY_SUMMARY: &str = r#"{
        "day": {
            "date_int": 19723,
            "exercise_calories": 750.5
        },
        "month": 1,
        "year": 2024
    }"#;

    /// Multiple days summary
    pub const MULTIPLE_DAYS_SUMMARY: &str = r#"{
        "day": [
            {
                "date_int": 19723,
                "exercise_calories": 750.5
            },
            {
                "date_int": 19724,
                "exercise_calories": 500.25
            }
        ],
        "month": 1,
        "year": 2024
    }"#;

    /// Month summary with string numbers
    pub const MONTH_SUMMARY_STRING_NUMBERS: &str = r#"{
        "day": {
            "date_int": "19723",
            "exercise_calories": "750.5"
        },
        "month": "1",
        "year": "2024"
    }"#;
}

// =============================================================================
// Opaque ID Type Tests
// =============================================================================

#[test]
fn test_exercise_id_new() {
    let id = ExerciseId::new("12345");
    assert_eq!(id.as_str(), "12345");
}

#[test]
fn test_exercise_id_from_string() {
    let id = ExerciseId::new(String::from("12345"));
    assert_eq!(id.as_str(), "12345");
}

#[test]
fn test_exercise_id_serialize() {
    let id = ExerciseId::new("12345");
    let json = serde_json::to_string(&id).expect("should serialize");
    assert_eq!(json, r#""12345""#);
}

#[test]
fn test_exercise_id_deserialize() {
    let json = r#""12345""#;
    let id: ExerciseId = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(id.as_str(), "12345");
}

#[test]
fn test_exercise_id_equality() {
    let id1 = ExerciseId::new("12345");
    let id2 = ExerciseId::new("12345");
    let id3 = ExerciseId::new("67890");

    assert_eq!(id1, id2);
    assert_ne!(id1, id3);
}

#[test]
fn test_exercise_id_clone() {
    let id1 = ExerciseId::new("12345");
    let id2 = id1.clone();
    assert_eq!(id1, id2);
}

#[test]
fn test_exercise_entry_id_new() {
    let id = ExerciseEntryId::new("67890");
    assert_eq!(id.as_str(), "67890");
}

#[test]
fn test_exercise_entry_id_serialize() {
    let id = ExerciseEntryId::new("67890");
    let json = serde_json::to_string(&id).expect("should serialize");
    assert_eq!(json, r#""67890""#);
}

#[test]
fn test_exercise_entry_id_deserialize() {
    let json = r#""67890""#;
    let id: ExerciseEntryId = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(id.as_str(), "67890");
}

// =============================================================================
// Exercise Type Deserialization Tests
// =============================================================================

#[test]
fn test_exercise_deserialize_numeric_fields() {
    let exercise: Exercise =
        serde_json::from_str(fixtures::EXERCISE_NUMERIC).expect("should deserialize");

    assert_eq!(exercise.exercise_id.as_str(), "12345");
    assert_eq!(exercise.exercise_name, "Running");
    assert!((exercise.calories_per_hour - 600.5).abs() < f64::EPSILON);
}

#[test]
fn test_exercise_deserialize_string_numbers() {
    let exercise: Exercise =
        serde_json::from_str(fixtures::EXERCISE_STRING_NUMBERS).expect("should deserialize");

    assert_eq!(exercise.exercise_id.as_str(), "12345");
    assert_eq!(exercise.exercise_name, "Running");
    assert!((exercise.calories_per_hour - 600.5).abs() < f64::EPSILON);
}

#[test]
fn test_exercise_serialize() {
    let exercise = Exercise {
        exercise_id: ExerciseId::new("12345"),
        exercise_name: "Running".to_string(),
        calories_per_hour: 600.5,
    };

    let json = serde_json::to_string(&exercise).expect("should serialize");
    let deserialized: Exercise = serde_json::from_str(&json).expect("should deserialize");

    assert_eq!(deserialized.exercise_id, exercise.exercise_id);
    assert_eq!(deserialized.exercise_name, exercise.exercise_name);
    assert!((deserialized.calories_per_hour - exercise.calories_per_hour).abs() < f64::EPSILON);
}

// =============================================================================
// Exercise Entry Type Deserialization Tests
// =============================================================================

#[test]
fn test_exercise_entry_deserialize_numeric_fields() {
    let entry: ExerciseEntry =
        serde_json::from_str(fixtures::EXERCISE_ENTRY_NUMERIC).expect("should deserialize");

    assert_eq!(entry.exercise_entry_id.as_str(), "67890");
    assert_eq!(entry.exercise_id.as_str(), "12345");
    assert_eq!(entry.exercise_name, "Running");
    assert_eq!(entry.duration_min, 30);
    assert!((entry.calories - 300.25).abs() < f64::EPSILON);
    assert_eq!(entry.date_int, 19723);
}

#[test]
fn test_exercise_entry_deserialize_string_numbers() {
    let entry: ExerciseEntry =
        serde_json::from_str(fixtures::EXERCISE_ENTRY_STRING_NUMBERS).expect("should deserialize");

    assert_eq!(entry.exercise_entry_id.as_str(), "67890");
    assert_eq!(entry.exercise_id.as_str(), "12345");
    assert_eq!(entry.exercise_name, "Running");
    assert_eq!(entry.duration_min, 30);
    assert!((entry.calories - 300.25).abs() < f64::EPSILON);
    assert_eq!(entry.date_int, 19723);
}

#[test]
fn test_exercise_entry_serialize() {
    let entry = ExerciseEntry {
        exercise_entry_id: ExerciseEntryId::new("67890"),
        exercise_id: ExerciseId::new("12345"),
        exercise_name: "Running".to_string(),
        duration_min: 30,
        calories: 300.25,
        date_int: 19723,
    };

    let json = serde_json::to_string(&entry).expect("should serialize");
    let deserialized: ExerciseEntry = serde_json::from_str(&json).expect("should deserialize");

    assert_eq!(deserialized.exercise_entry_id, entry.exercise_entry_id);
    assert_eq!(deserialized.duration_min, entry.duration_min);
    assert!((deserialized.calories - entry.calories).abs() < f64::EPSILON);
}

// =============================================================================
// Exercise Entry Input/Update Tests
// =============================================================================

#[test]
fn test_exercise_entry_input_serialize() {
    let input = ExerciseEntryInput {
        exercise_id: ExerciseId::new("12345"),
        duration_min: 30,
        date_int: 19723,
    };

    let json = serde_json::to_string(&input).expect("should serialize");
    assert!(json.contains("12345"));
    assert!(json.contains("30"));
    assert!(json.contains("19723"));
}

#[test]
fn test_exercise_entry_update_empty() {
    let update = ExerciseEntryUpdate::default();
    let json = serde_json::to_string(&update).expect("should serialize");

    // Should be empty object when all fields are None
    assert_eq!(json, "{}");
}

#[test]
fn test_exercise_entry_update_partial() {
    let update = ExerciseEntryUpdate {
        exercise_id: None,
        duration_min: Some(45),
    };

    let json = serde_json::to_string(&update).expect("should serialize");
    assert!(json.contains("duration_min"));
    assert!(json.contains("45"));
    assert!(!json.contains("exercise_id"));
}

#[test]
fn test_exercise_entry_update_full() {
    let update = ExerciseEntryUpdate {
        exercise_id: Some(ExerciseId::new("99999")),
        duration_min: Some(60),
    };

    let json = serde_json::to_string(&update).expect("should serialize");
    assert!(json.contains("exercise_id"));
    assert!(json.contains("99999"));
    assert!(json.contains("duration_min"));
    assert!(json.contains("60"));
}

// =============================================================================
// Single-or-Vec Deserialization Tests
// =============================================================================

#[test]
fn test_exercise_entries_response_single_entry() {
    let response: ExerciseEntriesResponse =
        serde_json::from_str(fixtures::SINGLE_ENTRY_RESPONSE).expect("should deserialize");

    assert_eq!(response.exercise_entries.len(), 1);
    assert_eq!(
        response
            .exercise_entries
            .first()
            .expect("should have entry")
            .exercise_entry_id
            .as_str(),
        "67890"
    );
}

#[test]
fn test_exercise_entries_response_multiple_entries() {
    let response: ExerciseEntriesResponse =
        serde_json::from_str(fixtures::MULTIPLE_ENTRIES_RESPONSE).expect("should deserialize");

    assert_eq!(response.exercise_entries.len(), 2);
    assert_eq!(
        response
            .exercise_entries
            .first()
            .expect("should have first entry")
            .exercise_entry_id
            .as_str(),
        "67890"
    );
    assert_eq!(
        response
            .exercise_entries
            .get(1)
            .expect("should have second entry")
            .exercise_entry_id
            .as_str(),
        "67891"
    );
}

#[test]
fn test_exercise_entries_response_empty() {
    let response: ExerciseEntriesResponse =
        serde_json::from_str(fixtures::EMPTY_ENTRIES_RESPONSE).expect("should deserialize");

    assert_eq!(response.exercise_entries.len(), 0);
}

// =============================================================================
// Summary Type Tests
// =============================================================================

#[test]
fn test_exercise_day_summary_deserialize() {
    let json = r#"{"date_int": 19723, "exercise_calories": 750.5}"#;
    let summary: ExerciseDaySummary = serde_json::from_str(json).expect("should deserialize");

    assert_eq!(summary.date_int, 19723);
    assert!((summary.exercise_calories - 750.5).abs() < f64::EPSILON);
}

#[test]
fn test_exercise_day_summary_deserialize_string_numbers() {
    let json = r#"{"date_int": "19723", "exercise_calories": "750.5"}"#;
    let summary: ExerciseDaySummary = serde_json::from_str(json).expect("should deserialize");

    assert_eq!(summary.date_int, 19723);
    assert!((summary.exercise_calories - 750.5).abs() < f64::EPSILON);
}

#[test]
fn test_exercise_month_summary_single_day() {
    let summary: ExerciseMonthSummary =
        serde_json::from_str(fixtures::SINGLE_DAY_SUMMARY).expect("should deserialize");

    assert_eq!(summary.days.len(), 1);
    let day = summary.days.first().expect("should have day");
    assert_eq!(day.date_int, 19723);
    assert!((day.exercise_calories - 750.5).abs() < f64::EPSILON);
    assert_eq!(summary.month, 1);
    assert_eq!(summary.year, 2024);
}

#[test]
fn test_exercise_month_summary_multiple_days() {
    let summary: ExerciseMonthSummary =
        serde_json::from_str(fixtures::MULTIPLE_DAYS_SUMMARY).expect("should deserialize");

    assert_eq!(summary.days.len(), 2);
    assert_eq!(
        summary
            .days
            .first()
            .expect("should have first day")
            .date_int,
        19723
    );
    assert_eq!(
        summary
            .days
            .get(1)
            .expect("should have second day")
            .date_int,
        19724
    );
    assert_eq!(summary.month, 1);
    assert_eq!(summary.year, 2024);
}

#[test]
fn test_exercise_month_summary_string_numbers() {
    let summary: ExerciseMonthSummary =
        serde_json::from_str(fixtures::MONTH_SUMMARY_STRING_NUMBERS).expect("should deserialize");

    assert_eq!(summary.days.len(), 1);
    let day = summary.days.first().expect("should have day");
    assert_eq!(day.date_int, 19723);
    assert!((day.exercise_calories - 750.5).abs() < f64::EPSILON);
    assert_eq!(summary.month, 1);
    assert_eq!(summary.year, 2024);
}

#[test]
fn test_exercise_month_summary_calculate_total_calories() {
    let summary: ExerciseMonthSummary =
        serde_json::from_str(fixtures::MULTIPLE_DAYS_SUMMARY).expect("should deserialize");

    let total: f64 = summary.days.iter().map(|d| d.exercise_calories).sum();

    assert!((total - 1250.75).abs() < f64::EPSILON); // 750.5 + 500.25
}

// =============================================================================
// Date Conversion Tests
// =============================================================================

#[test]
fn test_date_to_int_epoch() {
    let result = date_to_int("1970-01-01").expect("should convert");
    assert_eq!(result, 0);
}

#[test]
fn test_date_to_int_known_date() {
    // 2024-01-01 is 19723 days after 1970-01-01
    let result = date_to_int("2024-01-01").expect("should convert");
    assert_eq!(result, 19723);
}

#[test]
fn test_date_to_int_leap_year() {
    // 2024 is a leap year, Feb 29 exists
    let result = date_to_int("2024-02-29").expect("should convert");
    assert_eq!(result, 19782); // 19723 + 59 days
}

#[test]
fn test_int_to_date_epoch() {
    let result = int_to_date(0).expect("should convert");
    assert_eq!(result, "1970-01-01");
}

#[test]
fn test_int_to_date_known_date() {
    let result = int_to_date(19723).expect("should convert");
    assert_eq!(result, "2024-01-01");
}

#[test]
fn test_date_conversion_roundtrip() {
    let dates = ["1970-01-01", "2000-01-01", "2024-01-15", "2024-02-29"];

    for date in dates {
        let date_int = date_to_int(date).expect("should convert to int");
        let back = int_to_date(date_int).expect("should convert back");
        assert_eq!(back, date);
    }
}

#[test]
fn test_int_to_date_roundtrip() {
    let ints = [0, 1000, 10000, 19723, 20000];

    for int in ints {
        let date = int_to_date(int).expect("should convert to date");
        let back = date_to_int(&date).expect("should convert back");
        assert_eq!(back, int);
    }
}

// =============================================================================
// Date Conversion Error Cases
// =============================================================================

#[test]
fn test_date_to_int_invalid_format() {
    let result = date_to_int("2024/01/01");
    assert!(result.is_err());
    assert!(result.unwrap_err().contains("Invalid date format"));
}

#[test]
fn test_date_to_int_invalid_date() {
    let result = date_to_int("2024-02-30"); // Feb 30 doesn't exist
    assert!(result.is_err());
}

#[test]
fn test_date_to_int_invalid_month() {
    let result = date_to_int("2024-13-01"); // Month 13 doesn't exist
    assert!(result.is_err());
}

#[test]
fn test_date_to_int_invalid_day() {
    let result = date_to_int("2024-01-32"); // Day 32 doesn't exist
    assert!(result.is_err());
}

#[test]
fn test_date_to_int_not_leap_year() {
    let result = date_to_int("2023-02-29"); // 2023 is not a leap year
    assert!(result.is_err());
}

#[test]
fn test_date_to_int_empty_string() {
    let result = date_to_int("");
    assert!(result.is_err());
}

#[test]
fn test_date_to_int_partial_date() {
    let result = date_to_int("2024-01");
    assert!(result.is_err());
}

// =============================================================================
// Boundary and Edge Cases
// =============================================================================

#[test]
fn test_exercise_entry_zero_duration() {
    let json = r#"{
        "exercise_entry_id": "1",
        "exercise_id": "2",
        "exercise_name": "Test",
        "duration_min": 0,
        "calories": 0.0,
        "date_int": 19723
    }"#;

    let entry: ExerciseEntry = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(entry.duration_min, 0);
    assert!((entry.calories - 0.0).abs() < f64::EPSILON);
}

#[test]
fn test_exercise_entry_large_duration() {
    let json = r#"{
        "exercise_entry_id": "1",
        "exercise_id": "2",
        "exercise_name": "Marathon",
        "duration_min": 360,
        "calories": 3600.0,
        "date_int": 19723
    }"#;

    let entry: ExerciseEntry = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(entry.duration_min, 360);
    assert!((entry.calories - 3600.0).abs() < f64::EPSILON);
}

#[test]
fn test_exercise_entry_fractional_calories() {
    let json = r#"{
        "exercise_entry_id": "1",
        "exercise_id": "2",
        "exercise_name": "Walking",
        "duration_min": 30,
        "calories": 123.456789,
        "date_int": 19723
    }"#;

    let entry: ExerciseEntry = serde_json::from_str(json).expect("should deserialize");
    assert!((entry.calories - 123.456789).abs() < 0.000001);
}

#[test]
fn test_date_before_epoch() {
    let result = date_to_int("1969-12-31");
    assert!(result.is_ok());
    assert_eq!(result.unwrap(), -1);
}

#[test]
fn test_date_far_future() {
    let result = date_to_int("2100-01-01").expect("should convert");
    assert!(result > 19723); // Should be larger than 2024-01-01
}

#[test]
fn test_negative_date_int() {
    let result = int_to_date(-1).expect("should convert");
    assert_eq!(result, "1969-12-31");
}

// =============================================================================
// Malformed JSON Error Cases
// =============================================================================

#[test]
fn test_exercise_missing_required_field() {
    let json = r#"{"exercise_id": "123", "exercise_name": "Running"}"#;
    let result: Result<Exercise, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

#[test]
fn test_exercise_entry_missing_required_field() {
    let json = r#"{
        "exercise_entry_id": "1",
        "exercise_name": "Running",
        "duration_min": 30
    }"#;
    let result: Result<ExerciseEntry, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

#[test]
fn test_exercise_invalid_number_format() {
    let json = r#"{
        "exercise_id": "123",
        "exercise_name": "Running",
        "calories_per_hour": "not_a_number"
    }"#;
    let result: Result<Exercise, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

#[test]
fn test_exercise_entry_invalid_date_int() {
    let json = r#"{
        "exercise_entry_id": "1",
        "exercise_id": "2",
        "exercise_name": "Running",
        "duration_min": 30,
        "calories": 300.0,
        "date_int": "invalid"
    }"#;
    let result: Result<ExerciseEntry, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

#[test]
fn test_month_summary_missing_days_uses_default() {
    // The API uses #[serde(default)] so missing "day" field results in empty vec
    let json = r#"{"month": 1, "year": 2024}"#;
    let result: ExerciseMonthSummary = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(result.days.len(), 0);
    assert_eq!(result.month, 1);
    assert_eq!(result.year, 2024);
}

// =============================================================================
// Clone and Debug Trait Tests
// =============================================================================

#[test]
fn test_exercise_clone() {
    let exercise = Exercise {
        exercise_id: ExerciseId::new("12345"),
        exercise_name: "Running".to_string(),
        calories_per_hour: 600.5,
    };

    let cloned = exercise.clone();
    assert_eq!(cloned.exercise_id, exercise.exercise_id);
    assert_eq!(cloned.exercise_name, exercise.exercise_name);
    assert!((cloned.calories_per_hour - exercise.calories_per_hour).abs() < f64::EPSILON);
}

#[test]
fn test_exercise_entry_clone() {
    let entry = ExerciseEntry {
        exercise_entry_id: ExerciseEntryId::new("67890"),
        exercise_id: ExerciseId::new("12345"),
        exercise_name: "Running".to_string(),
        duration_min: 30,
        calories: 300.25,
        date_int: 19723,
    };

    let cloned = entry.clone();
    assert_eq!(cloned.exercise_entry_id, entry.exercise_entry_id);
    assert_eq!(cloned.duration_min, entry.duration_min);
}

#[test]
fn test_exercise_debug_format() {
    let exercise = Exercise {
        exercise_id: ExerciseId::new("12345"),
        exercise_name: "Running".to_string(),
        calories_per_hour: 600.5,
    };

    let debug = format!("{:?}", exercise);
    assert!(debug.contains("Exercise"));
    assert!(debug.contains("12345"));
    assert!(debug.contains("Running"));
}

#[test]
fn test_exercise_entry_debug_format() {
    let entry = ExerciseEntry {
        exercise_entry_id: ExerciseEntryId::new("67890"),
        exercise_id: ExerciseId::new("12345"),
        exercise_name: "Running".to_string(),
        duration_min: 30,
        calories: 300.25,
        date_int: 19723,
    };

    let debug = format!("{:?}", entry);
    assert!(debug.contains("ExerciseEntry"));
    assert!(debug.contains("67890"));
}

// =============================================================================
// Response Wrapper Tests
// =============================================================================

#[test]
fn test_exercise_response_wrapper() {
    let json = r#"{
        "exercise": {
            "exercise_id": "12345",
            "exercise_name": "Running",
            "calories_per_hour": 600.5
        }
    }"#;

    let response: ExerciseResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.exercise.exercise_id.as_str(), "12345");
}

#[test]
fn test_single_exercise_entry_response_wrapper() {
    let json = r#"{
        "exercise_entry": {
            "exercise_entry_id": "67890"
        }
    }"#;

    let response: SingleExerciseEntryResponse =
        serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.exercise_entry.exercise_entry_id.as_str(), "67890");
}

#[test]
fn test_exercise_month_summary_response_wrapper() {
    let json = r#"{
        "exercise_month": {
            "day": {
                "date_int": 19723,
                "exercise_calories": 750.5
            },
            "month": 1,
            "year": 2024
        }
    }"#;

    let response: ExerciseMonthSummaryResponse =
        serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.exercise_month.month, 1);
    assert_eq!(response.exercise_month.year, 2024);
}

// =============================================================================
// Validation Function Tests
// =============================================================================

use super::validation::*;

#[test]
fn validate_exercise_entry_id_valid() {
    assert!(validate_exercise_entry_id("12345").is_ok());
    assert!(validate_exercise_entry_id("67890").is_ok());
    assert!(validate_exercise_entry_id("0").is_ok());
}

#[test]
fn validate_exercise_entry_id_empty() {
    assert!(validate_exercise_entry_id("").is_err());
    assert!(validate_exercise_entry_id(" ").is_err());
}

#[test]
fn validate_exercise_entry_id_non_numeric() {
    assert!(validate_exercise_entry_id("abc").is_err());
    assert!(validate_exercise_entry_id("12a").is_err());
    assert!(validate_exercise_entry_id("123-456").is_err());
}

#[test]
fn validate_duration_min_valid() {
    assert!(validate_duration_min(1).is_ok());
    assert!(validate_duration_min(60).is_ok());
    assert!(validate_duration_min(1440).is_ok());
}

#[test]
fn validate_duration_min_too_low() {
    assert!(validate_duration_min(0).is_err());
    assert!(validate_duration_min(-1).is_err());
}

#[test]
fn validate_duration_min_too_high() {
    assert!(validate_duration_min(1441).is_err());
    assert!(validate_duration_min(10000).is_err());
}

#[test]
fn validate_exercise_id_valid() {
    assert!(validate_exercise_id("12345").is_ok());
    assert!(validate_exercise_id("67890").is_ok());
}

#[test]
fn validate_exercise_id_empty() {
    assert!(validate_exercise_id("").is_err());
    assert!(validate_exercise_id(" ").is_err());
}

#[test]
fn validate_exercise_id_non_numeric() {
    assert!(validate_exercise_id("abc").is_err());
    assert!(validate_exercise_id("running").is_err());
}

#[test]
fn validate_access_token_valid() {
    assert!(validate_access_token("token123").is_ok());
    assert!(validate_access_token("abc-def-ghi").is_ok());
}

#[test]
fn validate_access_token_empty() {
    assert!(validate_access_token("").is_err());
    assert!(validate_access_token("   ").is_err());
}

#[test]
fn validate_access_secret_valid() {
    assert!(validate_access_secret("secret123").is_ok());
    assert!(validate_access_secret("abc-def-ghi").is_ok());
}

#[test]
fn validate_access_secret_empty() {
    assert!(validate_access_secret("").is_err());
    assert!(validate_access_secret("   ").is_err());
}
