//! FatSecret Food Diary types
//!
//! These types represent food entries logged in the user's food diary,
//! along with daily and monthly summaries. The FatSecret API uses
//! date_int (days since Unix epoch) for all date operations.

use serde::{Deserialize, Serialize};

// ============================================================================
// MealType
// ============================================================================

/// Meal type for diary entries
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum MealType {
    Breakfast,
    Lunch,
    Dinner,
    #[serde(rename = "other")]
    Snack,
}

impl MealType {
    /// Convert MealType to API string
    pub fn to_api_string(&self) -> &'static str {
        match self {
            MealType::Breakfast => "breakfast",
            MealType::Lunch => "lunch",
            MealType::Dinner => "dinner",
            MealType::Snack => "other",
        }
    }

    /// Parse MealType from API string
    pub fn from_api_string(s: &str) -> Option<Self> {
        match s {
            "breakfast" => Some(MealType::Breakfast),
            "lunch" => Some(MealType::Lunch),
            "dinner" => Some(MealType::Dinner),
            "other" | "snack" => Some(MealType::Snack),
            _ => None,
        }
    }
}

impl std::fmt::Display for MealType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.to_api_string())
    }
}

// ============================================================================
// Food Entry ID (newtype for type safety)
// ============================================================================

/// Opaque food entry ID from FatSecret API
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct FoodEntryId(String);

impl FoodEntryId {
    /// Create a FoodEntryId from a string
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Get the ID as a string reference
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl From<String> for FoodEntryId {
    fn from(s: String) -> Self {
        Self(s)
    }
}

impl From<&str> for FoodEntryId {
    fn from(s: &str) -> Self {
        Self(s.to_string())
    }
}

impl std::fmt::Display for FoodEntryId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

// ============================================================================
// Food Entry Types
// ============================================================================

/// Complete food diary entry
///
/// Represents a single food logged to the user's diary. All nutrition
/// values are stored in the units they come from the API (grams, milligrams).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodEntry {
    /// Unique entry ID from FatSecret
    pub food_entry_id: FoodEntryId,
    /// Entry display name
    pub food_entry_name: String,
    /// Full description (includes serving size info)
    pub food_entry_description: String,
    /// Food ID (if from FatSecret database, empty for custom)
    pub food_id: String,
    /// Serving ID (if from FatSecret database, empty for custom)
    pub serving_id: String,
    /// Number of servings consumed
    pub number_of_units: f64,
    /// Which meal this entry belongs to
    pub meal: MealType,
    /// Date as days since Unix epoch (0 = 1970-01-01)
    pub date_int: i32,
    /// Calories
    pub calories: f64,
    /// Carbohydrates in grams
    pub carbohydrate: f64,
    /// Protein in grams
    pub protein: f64,
    /// Total fat in grams
    pub fat: f64,
    /// Saturated fat in grams
    #[serde(skip_serializing_if = "Option::is_none")]
    pub saturated_fat: Option<f64>,
    /// Polyunsaturated fat in grams
    #[serde(skip_serializing_if = "Option::is_none")]
    pub polyunsaturated_fat: Option<f64>,
    /// Monounsaturated fat in grams
    #[serde(skip_serializing_if = "Option::is_none")]
    pub monounsaturated_fat: Option<f64>,
    /// Cholesterol in milligrams
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cholesterol: Option<f64>,
    /// Sodium in milligrams
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sodium: Option<f64>,
    /// Potassium in milligrams
    #[serde(skip_serializing_if = "Option::is_none")]
    pub potassium: Option<f64>,
    /// Fiber in grams
    #[serde(skip_serializing_if = "Option::is_none")]
    pub fiber: Option<f64>,
    /// Sugar in grams
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sugar: Option<f64>,
}

/// Input for creating a new food entry
///
/// Two ways to create entries:
/// 1. FromFood: Reference an existing FatSecret food with serving
/// 2. Custom: Manually enter all nutrition values
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum FoodEntryInput {
    /// Create entry from FatSecret database food
    FromFood {
        food_id: String,
        food_entry_name: String,
        serving_id: String,
        number_of_units: f64,
        meal: MealType,
        date_int: i32,
    },
    /// Create custom entry with manual nutrition values
    Custom {
        food_entry_name: String,
        serving_description: String,
        number_of_units: f64,
        meal: MealType,
        date_int: i32,
        calories: f64,
        carbohydrate: f64,
        protein: f64,
        fat: f64,
    },
}

/// Update for an existing food entry
///
/// Only allows updating serving size and meal type.
/// To change nutrition values, delete and recreate the entry.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct FoodEntryUpdate {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub number_of_units: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub meal: Option<MealType>,
}

impl FoodEntryUpdate {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_units(mut self, units: f64) -> Self {
        self.number_of_units = Some(units);
        self
    }

    pub fn with_meal(mut self, meal: MealType) -> Self {
        self.meal = Some(meal);
        self
    }
}

// ============================================================================
// Summary Types
// ============================================================================

/// Daily nutrition summary
///
/// Aggregated totals for a single day's diary entries.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DaySummary {
    pub date_int: i32,
    pub calories: f64,
    pub carbohydrate: f64,
    pub protein: f64,
    pub fat: f64,
}

/// Monthly nutrition summary
///
/// Contains a summary for each day in the month.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MonthSummary {
    pub days: Vec<DaySummary>,
    pub month: i32,
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
#[allow(dead_code)]
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
///
/// Inverse of date_to_int. Always returns a valid date string.
#[allow(dead_code)]
pub fn int_to_date(date_int: i32) -> String {
    use chrono::{Duration, NaiveDate};

    let epoch = NaiveDate::from_ymd_opt(1970, 1, 1).unwrap();
    let date = epoch + Duration::days(date_int as i64);
    date.format("%Y-%m-%d").to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_date_to_int() {
        assert_eq!(date_to_int("1970-01-01").unwrap(), 0);
        assert_eq!(date_to_int("1970-01-02").unwrap(), 1);
        assert_eq!(date_to_int("2024-01-01").unwrap(), 19723);
    }

    #[test]
    fn test_int_to_date() {
        assert_eq!(int_to_date(0), "1970-01-01");
        assert_eq!(int_to_date(1), "1970-01-02");
        assert_eq!(int_to_date(19723), "2024-01-01");
    }

    #[test]
    fn test_meal_type_roundtrip() {
        for meal in [
            MealType::Breakfast,
            MealType::Lunch,
            MealType::Dinner,
            MealType::Snack,
        ] {
            let s = meal.to_api_string();
            let parsed = MealType::from_api_string(s).unwrap();
            assert_eq!(meal, parsed);
        }
    }
}
