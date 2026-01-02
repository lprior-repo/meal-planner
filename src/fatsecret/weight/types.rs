//! `FatSecret` Weight Management types
//!
//! Type definitions for weight tracking via the `FatSecret` Platform API.
//! These types provide type-safe deserialization of API responses and
//! construction of API requests.
//!
//! # Core Types
//!
//! ## Entry Types
//! - [`WeightEntry`] - Single weight measurement with date and comment
//! - [`WeightUpdate`] - Input for recording new weight measurements
//! - [`WeightEntryId`] - Type-safe newtype wrapper for weight entry IDs
//!
//! ## Summary Types
//! - [`WeightMonthSummary`] - Collection of weight measurements for a month
//! - [`WeightDaySummary`] - Single day's weight data within a monthly summary
//!
//! ## Response Wrappers
//! - [`WeightEntryResponse`] - API response wrapper for single weight entry
//! - [`WeightMonthSummaryResponse`] - API response wrapper for monthly summary
//!
//! # Date Format
//!
//! All dates use date_int: the number of days since Unix epoch (1970-01-01).
//! For example:
//! - `0` = 1970-01-01
//! - `19723` = 2024-01-01
//!
//! # Flexible Deserialization
//!
//! This module uses custom deserializers from `fatsecret::core::serde_utils` to handle:
//! - Numeric values as either strings or numbers (`deserialize_flexible_int`, `deserialize_flexible_float`)
//! - Single items or arrays (`deserialize_single_or_vec`)
//!
//! This ensures compatibility with `FatSecret`'s inconsistent JSON responses.
//!
//! # Usage Example
//!
//! ```
//! use meal_planner::fatsecret::weight::{WeightUpdate, WeightEntry};
//!
//! // Create a weight update request
//! let update = WeightUpdate {
//!     current_weight_kg: 75.5,
//!     date_int: 19723, // 2024-01-01
//!     goal_weight_kg: Some(70.0),
//!     height_cm: Some(175.0),
//!     comment: Some("Morning weigh-in".to_string()),
//! };
//!
//! // Deserialize a weight entry from JSON
//! let json = r#"{
//!     "date_int": "19723",
//!     "weight_kg": "75.5",
//!     "weight_comment": "Morning weigh-in"
//! }"#;
//! let entry: WeightEntry = serde_json::from_str(json).unwrap();
//! assert_eq!(entry.date_int, 19723);
//! assert_eq!(entry.weight_kg, 75.5);
//! ```

use crate::fatsecret::core::serde_utils::{
    deserialize_flexible_float, deserialize_flexible_int, deserialize_single_or_vec,
};
use serde::{Deserialize, Serialize};

// ============================================================================
// Weight Entry ID (newtype for type safety)
// ============================================================================

/// Opaque weight entry ID
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct WeightEntryId(String);

impl WeightEntryId {
    /// Creates a new weight entry ID from a string-like value
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the ID as a string slice
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

// ============================================================================
// Weight Entry Types
// ============================================================================

/// Single weight measurement entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeightEntry {
    /// Date as days since Unix epoch (0 = 1970-01-01)
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub date_int: i32,
    /// Weight in kilograms
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub weight_kg: f64,
    /// Optional comment about the measurement
    pub weight_comment: Option<String>,
}

/// Wrapper for `WeightEntry` response
#[derive(Debug, Deserialize)]
pub struct WeightEntryResponse {
    /// The weight entry data
    pub weight: WeightEntry,
}

/// Input for updating weight
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct WeightUpdate {
    /// Current weight in kilograms
    pub current_weight_kg: f64,
    /// Date as days since Unix epoch
    pub date_int: i32,
    /// Optional goal weight in kilograms
    pub goal_weight_kg: Option<f64>,
    /// Optional height in centimeters
    pub height_cm: Option<f64>,
    /// Optional comment about the measurement
    pub comment: Option<String>,
}

// ============================================================================
// Summary Types
// ============================================================================

/// Single day's weight summary
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeightDaySummary {
    /// Date as days since Unix epoch
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub date_int: i32,
    /// Weight in kilograms
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub weight_kg: f64,
}

/// Monthly weight summary
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeightMonthSummary {
    /// Start date of the month as days since Unix epoch
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub from_date_int: i32,
    /// End date of the month as days since Unix epoch
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub to_date_int: i32,
    /// List of daily weight measurements
    #[serde(
        rename = "weight",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub days: Vec<WeightDaySummary>,
}

/// Wrapper for `WeightMonthSummary` response
#[derive(Debug, Deserialize)]
pub struct WeightMonthSummaryResponse {
    /// The monthly weight summary data
    pub weight_month: WeightMonthSummary,
}

#[cfg(test)]
mod tests {
    use super::*;

    // ============================================================================
    // WeightEntryId Tests
    // ============================================================================

    #[test]
    fn test_weight_entry_id_new() {
        let id = WeightEntryId::new("12345");
        assert_eq!(id.as_str(), "12345");
    }

    #[test]
    fn test_weight_entry_id_from_string() {
        let id = WeightEntryId::new(String::from("67890"));
        assert_eq!(id.as_str(), "67890");
    }

    #[test]
    fn test_weight_entry_id_equality() {
        let id1 = WeightEntryId::new("12345");
        let id2 = WeightEntryId::new("12345");
        let id3 = WeightEntryId::new("67890");
        assert_eq!(id1, id2);
        assert_ne!(id1, id3);
    }

    #[test]
    fn test_weight_entry_id_serialization() {
        let id = WeightEntryId::new("12345");
        let json = serde_json::to_string(&id).unwrap();
        assert_eq!(json, r#""12345""#);
    }

    #[test]
    fn test_weight_entry_id_deserialization() {
        let json = r#""12345""#;
        let id: WeightEntryId = serde_json::from_str(json).unwrap();
        assert_eq!(id.as_str(), "12345");
    }

    // ============================================================================
    // WeightEntry Tests - Deserialization
    // ============================================================================

    #[test]
    fn test_weight_entry_deserialize_with_comment() {
        let json = r#"{
            "date_int": "19723",
            "weight_kg": "75.5",
            "weight_comment": "Morning weigh-in"
        }"#;
        let entry: WeightEntry = serde_json::from_str(json).unwrap();
        assert_eq!(entry.date_int, 19723);
        assert!((entry.weight_kg - 75.5).abs() < f64::EPSILON);
        assert_eq!(entry.weight_comment.as_deref(), Some("Morning weigh-in"));
    }

    #[test]
    fn test_weight_entry_deserialize_without_comment() {
        let json = r#"{
            "date_int": "19723",
            "weight_kg": "75.5"
        }"#;
        let entry: WeightEntry = serde_json::from_str(json).unwrap();
        assert_eq!(entry.date_int, 19723);
        assert!((entry.weight_kg - 75.5).abs() < f64::EPSILON);
        assert_eq!(entry.weight_comment, None);
    }

    #[test]
    fn test_weight_entry_deserialize_null_comment() {
        let json = r#"{
            "date_int": "19723",
            "weight_kg": "75.5",
            "weight_comment": null
        }"#;
        let entry: WeightEntry = serde_json::from_str(json).unwrap();
        assert_eq!(entry.date_int, 19723);
        assert!((entry.weight_kg - 75.5).abs() < f64::EPSILON);
        assert_eq!(entry.weight_comment, None);
    }

    #[test]
    fn test_weight_entry_deserialize_numeric_values() {
        let json = r#"{
            "date_int": 19723,
            "weight_kg": 75.5
        }"#;
        let entry: WeightEntry = serde_json::from_str(json).unwrap();
        assert_eq!(entry.date_int, 19723);
        assert!((entry.weight_kg - 75.5).abs() < f64::EPSILON);
    }

    #[test]
    fn test_weight_entry_deserialize_string_values() {
        let json = r#"{
            "date_int": "19723",
            "weight_kg": "75.5"
        }"#;
        let entry: WeightEntry = serde_json::from_str(json).unwrap();
        assert_eq!(entry.date_int, 19723);
        assert!((entry.weight_kg - 75.5).abs() < f64::EPSILON);
    }

    #[test]
    fn test_weight_entry_deserialize_mixed_values() {
        let json = r#"{
            "date_int": 19723,
            "weight_kg": "75.5"
        }"#;
        let entry: WeightEntry = serde_json::from_str(json).unwrap();
        assert_eq!(entry.date_int, 19723);
        assert!((entry.weight_kg - 75.5).abs() < f64::EPSILON);
    }

    #[test]
    fn test_weight_entry_deserialize_zero_date() {
        let json = r#"{
            "date_int": "0",
            "weight_kg": "70.0"
        }"#;
        let entry: WeightEntry = serde_json::from_str(json).unwrap();
        assert_eq!(entry.date_int, 0);
        assert!((entry.weight_kg - 70.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_weight_entry_deserialize_negative_date() {
        let json = r#"{
            "date_int": "-365",
            "weight_kg": "70.0"
        }"#;
        let entry: WeightEntry = serde_json::from_str(json).unwrap();
        assert_eq!(entry.date_int, -365);
        assert!((entry.weight_kg - 70.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_weight_entry_deserialize_decimal_weight() {
        let json = r#"{
            "date_int": "19723",
            "weight_kg": "75.567"
        }"#;
        let entry: WeightEntry = serde_json::from_str(json).unwrap();
        assert_eq!(entry.date_int, 19723);
        assert!((entry.weight_kg - 75.567).abs() < f64::EPSILON);
    }

    #[test]
    fn test_weight_entry_deserialize_invalid_date_int() {
        let json = r#"{
            "date_int": "not-a-number",
            "weight_kg": "75.5"
        }"#;
        let result: Result<WeightEntry, _> = serde_json::from_str(json);
        assert!(result.is_err());
    }

    #[test]
    fn test_weight_entry_deserialize_invalid_weight() {
        let json = r#"{
            "date_int": "19723",
            "weight_kg": "not-a-number"
        }"#;
        let result: Result<WeightEntry, _> = serde_json::from_str(json);
        assert!(result.is_err());
    }

    #[test]
    fn test_weight_entry_response_deserialize() {
        let json = r#"{
            "weight": {
                "date_int": "19723",
                "weight_kg": "75.5",
                "weight_comment": "Morning"
            }
        }"#;
        let response: WeightEntryResponse = serde_json::from_str(json).unwrap();
        assert_eq!(response.weight.date_int, 19723);
        assert!((response.weight.weight_kg - 75.5).abs() < f64::EPSILON);
        assert_eq!(response.weight.weight_comment.as_deref(), Some("Morning"));
    }

    // ============================================================================
    // WeightUpdate Tests - Construction & Serialization
    // ============================================================================

    #[test]
    fn test_weight_update_minimal() {
        let update = WeightUpdate {
            current_weight_kg: 75.5,
            date_int: 19723,
            goal_weight_kg: None,
            height_cm: None,
            comment: None,
        };
        assert!((update.current_weight_kg - 75.5).abs() < f64::EPSILON);
        assert_eq!(update.date_int, 19723);
        assert_eq!(update.goal_weight_kg, None);
        assert_eq!(update.height_cm, None);
        assert_eq!(update.comment, None);
    }

    #[test]
    fn test_weight_update_with_goal() {
        let update = WeightUpdate {
            current_weight_kg: 75.5,
            date_int: 19723,
            goal_weight_kg: Some(70.0),
            height_cm: None,
            comment: None,
        };
        assert_eq!(update.goal_weight_kg, Some(70.0));
    }

    #[test]
    fn test_weight_update_with_height() {
        let update = WeightUpdate {
            current_weight_kg: 75.5,
            date_int: 19723,
            goal_weight_kg: None,
            height_cm: Some(175.0),
            comment: None,
        };
        assert_eq!(update.height_cm, Some(175.0));
    }

    #[test]
    fn test_weight_update_with_comment() {
        let update = WeightUpdate {
            current_weight_kg: 75.5,
            date_int: 19723,
            goal_weight_kg: None,
            height_cm: None,
            comment: Some("After workout".to_string()),
        };
        assert_eq!(update.comment.as_deref(), Some("After workout"));
    }

    #[test]
    fn test_weight_update_complete() {
        let update = WeightUpdate {
            current_weight_kg: 75.5,
            date_int: 19723,
            goal_weight_kg: Some(70.0),
            height_cm: Some(175.0),
            comment: Some("Morning weigh-in".to_string()),
        };
        assert!((update.current_weight_kg - 75.5).abs() < f64::EPSILON);
        assert_eq!(update.date_int, 19723);
        assert_eq!(update.goal_weight_kg, Some(70.0));
        assert_eq!(update.height_cm, Some(175.0));
        assert_eq!(update.comment.as_deref(), Some("Morning weigh-in"));
    }

    #[test]
    fn test_weight_update_default() {
        let update = WeightUpdate::default();
        assert!((update.current_weight_kg - 0.0).abs() < f64::EPSILON);
        assert_eq!(update.date_int, 0);
        assert_eq!(update.goal_weight_kg, None);
        assert_eq!(update.height_cm, None);
        assert_eq!(update.comment, None);
    }

    #[test]
    fn test_weight_update_serialization() {
        let update = WeightUpdate {
            current_weight_kg: 75.5,
            date_int: 19723,
            goal_weight_kg: Some(70.0),
            height_cm: Some(175.0),
            comment: Some("Morning".to_string()),
        };
        let json = serde_json::to_string(&update).unwrap();
        assert!(json.contains("75.5"));
        assert!(json.contains("19723"));
        assert!(json.contains("70.0"));
        assert!(json.contains("175.0"));
        assert!(json.contains("Morning"));
    }

    #[test]
    fn test_weight_update_deserialization() {
        let json = r#"{
            "current_weight_kg": 75.5,
            "date_int": 19723,
            "goal_weight_kg": 70.0,
            "height_cm": 175.0,
            "comment": "Morning"
        }"#;
        let update: WeightUpdate = serde_json::from_str(json).unwrap();
        assert!((update.current_weight_kg - 75.5).abs() < f64::EPSILON);
        assert_eq!(update.date_int, 19723);
        assert_eq!(update.goal_weight_kg, Some(70.0));
        assert_eq!(update.height_cm, Some(175.0));
        assert_eq!(update.comment.as_deref(), Some("Morning"));
    }

    // ============================================================================
    // WeightDaySummary Tests
    // ============================================================================

    #[test]
    fn test_weight_day_summary_deserialize_string_values() {
        let json = r#"{
            "date_int": "19723",
            "weight_kg": "75.5"
        }"#;
        let summary: WeightDaySummary = serde_json::from_str(json).unwrap();
        assert_eq!(summary.date_int, 19723);
        assert!((summary.weight_kg - 75.5).abs() < f64::EPSILON);
    }

    #[test]
    fn test_weight_day_summary_deserialize_numeric_values() {
        let json = r#"{
            "date_int": 19723,
            "weight_kg": 75.5
        }"#;
        let summary: WeightDaySummary = serde_json::from_str(json).unwrap();
        assert_eq!(summary.date_int, 19723);
        assert!((summary.weight_kg - 75.5).abs() < f64::EPSILON);
    }

    // ============================================================================
    // WeightMonthSummary Tests - Single/Multiple Items
    // ============================================================================

    #[test]
    fn test_weight_month_summary_empty() {
        let json = r#"{
            "from_date_int": "19723",
            "to_date_int": "19753"
        }"#;
        let summary: WeightMonthSummary = serde_json::from_str(json).unwrap();
        assert_eq!(summary.from_date_int, 19723);
        assert_eq!(summary.to_date_int, 19753);
        assert_eq!(summary.days.len(), 0);
    }

    #[test]
    #[allow(clippy::indexing_slicing)]
    fn test_weight_month_summary_single_day() {
        let json = r#"{
            "from_date_int": "19723",
            "to_date_int": "19753",
            "weight": {
                "date_int": "19723",
                "weight_kg": "75.5"
            }
        }"#;
        let summary: WeightMonthSummary = serde_json::from_str(json).unwrap();
        assert_eq!(summary.from_date_int, 19723);
        assert_eq!(summary.to_date_int, 19753);
        assert_eq!(summary.days.len(), 1);
        assert_eq!(summary.days[0].date_int, 19723);
        assert!((summary.days[0].weight_kg - 75.5).abs() < f64::EPSILON);
    }

    #[test]
    #[allow(clippy::indexing_slicing)]
    fn test_weight_month_summary_multiple_days() {
        let json = r#"{
            "from_date_int": "19723",
            "to_date_int": "19753",
            "weight": [
                {
                    "date_int": "19723",
                    "weight_kg": "75.5"
                },
                {
                    "date_int": "19724",
                    "weight_kg": "75.3"
                },
                {
                    "date_int": "19725",
                    "weight_kg": "75.1"
                }
            ]
        }"#;
        let summary: WeightMonthSummary = serde_json::from_str(json).unwrap();
        assert_eq!(summary.from_date_int, 19723);
        assert_eq!(summary.to_date_int, 19753);
        assert_eq!(summary.days.len(), 3);
        assert_eq!(summary.days[0].date_int, 19723);
        assert!((summary.days[0].weight_kg - 75.5).abs() < f64::EPSILON);
        assert_eq!(summary.days[1].date_int, 19724);
        assert!((summary.days[1].weight_kg - 75.3).abs() < f64::EPSILON);
        assert_eq!(summary.days[2].date_int, 19725);
        assert!((summary.days[2].weight_kg - 75.1).abs() < f64::EPSILON);
    }

    #[test]
    fn test_weight_month_summary_numeric_dates() {
        let json = r#"{
            "from_date_int": 19723,
            "to_date_int": 19753,
            "weight": [
                {
                    "date_int": 19723,
                    "weight_kg": 75.5
                }
            ]
        }"#;
        let summary: WeightMonthSummary = serde_json::from_str(json).unwrap();
        assert_eq!(summary.from_date_int, 19723);
        assert_eq!(summary.to_date_int, 19753);
        assert_eq!(summary.days.len(), 1);
    }

    #[test]
    fn test_weight_month_summary_response_deserialize() {
        let json = r#"{
            "weight_month": {
                "from_date_int": "19723",
                "to_date_int": "19753",
                "weight": [
                    {
                        "date_int": "19723",
                        "weight_kg": "75.5"
                    }
                ]
            }
        }"#;
        let response: WeightMonthSummaryResponse = serde_json::from_str(json).unwrap();
        assert_eq!(response.weight_month.from_date_int, 19723);
        assert_eq!(response.weight_month.to_date_int, 19753);
        assert_eq!(response.weight_month.days.len(), 1);
    }

    // ============================================================================
    // Error Cases
    // ============================================================================

    #[test]
    fn test_weight_entry_missing_required_field() {
        let json = r#"{
            "date_int": "19723"
        }"#;
        let result: Result<WeightEntry, _> = serde_json::from_str(json);
        assert!(result.is_err());
    }

    #[test]
    fn test_weight_month_summary_invalid_date_range() {
        let json = r#"{
            "from_date_int": "invalid",
            "to_date_int": "19753"
        }"#;
        let result: Result<WeightMonthSummary, _> = serde_json::from_str(json);
        assert!(result.is_err());
    }

    #[test]
    fn test_weight_month_summary_malformed_weight_array() {
        let json = r#"{
            "from_date_int": "19723",
            "to_date_int": "19753",
            "weight": [
                {
                    "date_int": "19723"
                }
            ]
        }"#;
        let result: Result<WeightMonthSummary, _> = serde_json::from_str(json);
        assert!(result.is_err());
    }

    // ============================================================================
    // Month Summary Calculations
    // ============================================================================

    #[test]
    fn test_weight_month_summary_date_range() {
        let json = r#"{
            "from_date_int": "19723",
            "to_date_int": "19753",
            "weight": []
        }"#;
        let summary: WeightMonthSummary = serde_json::from_str(json).unwrap();
        let days_in_range = summary.to_date_int - summary.from_date_int;
        assert_eq!(days_in_range, 30);
    }

    #[test]
    fn test_weight_month_summary_trend_calculation() {
        let summary = WeightMonthSummary {
            from_date_int: 19723,
            to_date_int: 19753,
            days: vec![
                WeightDaySummary {
                    date_int: 19723,
                    weight_kg: 80.0,
                },
                WeightDaySummary {
                    date_int: 19733,
                    weight_kg: 78.0,
                },
                WeightDaySummary {
                    date_int: 19743,
                    weight_kg: 76.0,
                },
            ],
        };

        // Test first and last weight
        let first = summary.days.first().unwrap();
        let last = summary.days.last().unwrap();
        assert!((first.weight_kg - 80.0).abs() < f64::EPSILON);
        assert!((last.weight_kg - 76.0).abs() < f64::EPSILON);

        // Calculate weight loss
        let loss = first.weight_kg - last.weight_kg;
        assert!((loss - 4.0).abs() < f64::EPSILON);
    }

    #[test]
    #[allow(clippy::cast_precision_loss)]
    fn test_weight_month_summary_average_calculation() {
        let summary = WeightMonthSummary {
            from_date_int: 19723,
            to_date_int: 19753,
            days: vec![
                WeightDaySummary {
                    date_int: 19723,
                    weight_kg: 75.0,
                },
                WeightDaySummary {
                    date_int: 19724,
                    weight_kg: 76.0,
                },
                WeightDaySummary {
                    date_int: 19725,
                    weight_kg: 77.0,
                },
            ],
        };

        let sum: f64 = summary.days.iter().map(|d| d.weight_kg).sum();
        let avg = sum / summary.days.len() as f64;
        assert!((avg - 76.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_weight_month_summary_min_max() {
        let summary = WeightMonthSummary {
            from_date_int: 19723,
            to_date_int: 19753,
            days: vec![
                WeightDaySummary {
                    date_int: 19723,
                    weight_kg: 78.5,
                },
                WeightDaySummary {
                    date_int: 19724,
                    weight_kg: 75.0,
                },
                WeightDaySummary {
                    date_int: 19725,
                    weight_kg: 80.2,
                },
            ],
        };

        let min = summary
            .days
            .iter()
            .map(|d| d.weight_kg)
            .fold(f64::INFINITY, f64::min);
        let max = summary
            .days
            .iter()
            .map(|d| d.weight_kg)
            .fold(f64::NEG_INFINITY, f64::max);

        assert!((min - 75.0).abs() < f64::EPSILON);
        assert!((max - 80.2).abs() < f64::EPSILON);
    }

    #[test]
    #[allow(clippy::indexing_slicing)]
    fn test_weight_month_summary_sorted_by_date() {
        let summary = WeightMonthSummary {
            from_date_int: 19723,
            to_date_int: 19753,
            days: vec![
                WeightDaySummary {
                    date_int: 19725,
                    weight_kg: 77.0,
                },
                WeightDaySummary {
                    date_int: 19723,
                    weight_kg: 75.0,
                },
                WeightDaySummary {
                    date_int: 19724,
                    weight_kg: 76.0,
                },
            ],
        };

        let mut sorted_days = summary.days;
        sorted_days.sort_by_key(|d| d.date_int);

        assert_eq!(sorted_days[0].date_int, 19723);
        assert_eq!(sorted_days[1].date_int, 19724);
        assert_eq!(sorted_days[2].date_int, 19725);
    }

    // ============================================================================
    // Clone Tests
    // ============================================================================

    #[test]
    fn test_weight_entry_clone() {
        let entry = WeightEntry {
            date_int: 19723,
            weight_kg: 75.5,
            weight_comment: Some("Morning".to_string()),
        };
        let cloned = entry.clone();
        assert_eq!(entry.date_int, cloned.date_int);
        assert!((entry.weight_kg - cloned.weight_kg).abs() < f64::EPSILON);
        assert_eq!(entry.weight_comment, cloned.weight_comment);
    }

    #[test]
    fn test_weight_update_clone() {
        let update = WeightUpdate {
            current_weight_kg: 75.5,
            date_int: 19723,
            goal_weight_kg: Some(70.0),
            height_cm: Some(175.0),
            comment: Some("Morning".to_string()),
        };
        let cloned = update.clone();
        assert!((update.current_weight_kg - cloned.current_weight_kg).abs() < f64::EPSILON);
        assert_eq!(update.date_int, cloned.date_int);
        assert_eq!(update.goal_weight_kg, cloned.goal_weight_kg);
        assert_eq!(update.height_cm, cloned.height_cm);
        assert_eq!(update.comment, cloned.comment);
    }
}
