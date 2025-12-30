//! FatSecret Weight Management types

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

/// Wrapper for WeightEntry response
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

/// Wrapper for WeightMonthSummary response
#[derive(Debug, Deserialize)]
pub struct WeightMonthSummaryResponse {
    /// The monthly weight summary data
    pub weight_month: WeightMonthSummary,
}
