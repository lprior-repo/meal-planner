//! FatSecret Weight Management types
//!
//! These types represent weight entries and summaries from the FatSecret API.
//! The API uses date_int (days since Unix epoch) for all date operations.

use serde::{Deserialize, Serialize};
use std::fmt;

// ============================================================================
// Weight Entry ID (opaque type for type safety)
// ============================================================================

/// Opaque weight entry ID
///
/// Used to uniquely identify weight entries for edit/delete operations.
/// Implements the newtype pattern for type safety.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct WeightEntryId(String);

impl WeightEntryId {
    /// Create a WeightEntryId from a string
    pub fn new(id: impl Into<String>) -> Self {
        WeightEntryId(id.into())
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

impl fmt::Display for WeightEntryId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl From<String> for WeightEntryId {
    fn from(s: String) -> Self {
        WeightEntryId(s)
    }
}

impl From<&str> for WeightEntryId {
    fn from(s: &str) -> Self {
        WeightEntryId(s.to_string())
    }
}

// ============================================================================
// Weight Entry Types
// ============================================================================

/// Single weight measurement entry
///
/// Represents a weight logged to the user's profile on a specific date.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeightEntry {
    /// Date as days since Unix epoch (0 = 1970-01-01)
    pub date_int: i64,
    /// Weight in kilograms
    pub weight_kg: f64,
    /// Optional comment about the measurement
    pub weight_comment: Option<String>,
}

/// Input for updating weight
///
/// Used to log a new weight measurement or update an existing one.
/// FatSecret API has specific rules about which dates can be updated.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeightUpdate {
    /// Current weight in kilograms
    pub current_weight_kg: f64,
    /// Date as days since Unix epoch
    pub date_int: i64,
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
///
/// Used within monthly summaries to show weight for each day.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeightDaySummary {
    /// Date as days since Unix epoch
    pub date_int: i64,
    /// Weight in kilograms
    pub weight_kg: f64,
}

/// Monthly weight summary
///
/// Contains weight measurements for each day in the month that has data.
/// The FatSecret API returns date ranges using from_date_int/to_date_int
/// rather than explicit month/year fields.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WeightMonthSummary {
    /// Start date of the month as days since Unix epoch
    pub from_date_int: i64,
    /// End date of the month as days since Unix epoch
    pub to_date_int: i64,
    /// List of daily weight measurements
    pub days: Vec<WeightDaySummary>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_weight_entry_id_creation() {
        let id = WeightEntryId::new("123");
        assert_eq!(id.as_str(), "123");
        assert_eq!(id.to_string(), "123");
    }

    #[test]
    fn test_weight_entry_id_from_string() {
        let id: WeightEntryId = "456".into();
        assert_eq!(id.as_str(), "456");
    }

    #[test]
    fn test_weight_entry_serialization() {
        let entry = WeightEntry {
            date_int: 19723,
            weight_kg: 75.5,
            weight_comment: Some("Morning weigh-in".to_string()),
        };

        let json = serde_json::to_string(&entry).unwrap();
        let deserialized: WeightEntry = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.date_int, 19723);
        assert_eq!(deserialized.weight_kg, 75.5);
    }

    #[test]
    fn test_weight_month_summary() {
        let summary = WeightMonthSummary {
            from_date_int: 19723,
            to_date_int: 19753,
            days: vec![
                WeightDaySummary {
                    date_int: 19723,
                    weight_kg: 75.0,
                },
                WeightDaySummary {
                    date_int: 19730,
                    weight_kg: 74.5,
                },
            ],
        };

        assert_eq!(summary.days.len(), 2);
    }
}
