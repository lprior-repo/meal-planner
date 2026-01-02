//! `FatSecret` Food Diary Type Definitions
//!
//! This module defines the complete type system for the `FatSecret` Food Diary API,
//! including food entries, nutrition summaries, meal types, and utility functions
//! for date conversion and validation.
//!
//! # Purpose
//!
//! Provides strongly-typed representations of:
//! - Food diary entries with full nutrition data
//! - Input types for creating/updating entries
//! - Daily and monthly nutrition summaries
//! - Date conversion between ISO format and `FatSecret`'s `date_int`
//! - Validation logic for custom food entries
//! - Error types for authentication and validation
//!
//! # Core Types
//!
//! ## Entry Types
//! - [`FoodEntry`] - Complete diary entry (read from API)
//! - [`FoodEntryInput`] - Input for creating entries (`FromFood` or Custom variants)
//! - [`FoodEntryUpdate`] - Builder for partial updates (portions, meal)
//! - [`FoodEntryId`] - Type-safe newtype wrapper for entry IDs
//!
//! ## Meal Classification
//! - [`MealType`] - Breakfast, Lunch, Dinner, or Snack
//!
//! ## Summary Types
//! - [`DaySummary`] - Aggregated nutrition totals for one day
//! - [`MonthSummary`] - Collection of day summaries for a month
//!
//! ## Error Types
//! - [`ValidationError`] - Custom entry validation failures
//! - [`AuthError`] - OAuth authentication error classification
//!
//! # Date System
//!
//! `FatSecret` uses `date_int` (i32) representing days since Unix epoch (1970-01-01):
//! - `0` = 1970-01-01
//! - `19723` = 2024-01-01
//!
//! Conversion functions:
//! - [`date_to_int`] - "YYYY-MM-DD" → `date_int`
//! - [`int_to_date`] - `date_int` → "YYYY-MM-DD"
//!
//! # Validation Functions
//!
//! - [`validate_custom_entry`] - Validates all fields for custom food entries
//! - [`validate_number_of_units`] - Ensures portion size is positive
//! - [`validate_date_int_string`] - Parses `date_int` from string (for URL params)
//! - [`map_auth_error`] - Maps HTTP status codes to auth error types
//!
//! # Nutrition Units
//!
//! All nutrition values use specific units:
//! - **Calories**: kcal
//! - **Macronutrients** (carbs, protein, fat): grams (g)
//! - **Cholesterol, sodium, potassium**: milligrams (mg)
//! - **Fiber, sugar**: grams (g)
//!
//! # Serde Handling
//!
//! The `FatSecret` API has inconsistent response formats. This module handles:
//! - Flexible numeric parsing (strings OR numbers) via `deserialize_flexible_*`
//! - Single item OR array responses via `deserialize_single_or_vec`
//! - Optional fields with default values
//!
//! # Usage Examples
//!
//! ## Creating Entries
//!
//! ```rust
//! use meal_planner::fatsecret::diary::{FoodEntryInput, `MealType`, date_to_int};
//!
//! // From `FatSecret` database
//! let from_db = FoodEntryInput::`FromFood` {
//!     `food_id`: "12345".to_string(),
//!     food_entry_name: "Grilled Chicken".to_string(),
//!     `serving_id`: "67890".to_string(),
//!     number_of_units: 1.0,
//!     meal: `MealType`::Dinner,
//!     `date_int`: date_to_int("2024-01-15").unwrap(),
//! };
//!
//! // Custom nutrition values
//! let custom = FoodEntryInput::Custom {
//!     food_entry_name: "Protein Smoothie".to_string(),
//!     serving_description: "1 large (500ml)".to_string(),
//!     number_of_units: 1.0,
//!     meal: `MealType`::Breakfast,
//!     `date_int`: date_to_int("2024-01-15").unwrap(),
//!     calories: 300.0,
//!     carbohydrate: 25.0,  // grams
//!     protein: 35.0,       // grams
//!     fat: 8.0,            // grams
//! };
//! ```
//!
//! ## Updating Entries
//!
//! ```rust
//! use meal_planner::fatsecret::diary::{FoodEntryUpdate, `MealType`};
//!
//! // Builder pattern for updates
//! let update = FoodEntryUpdate::new()
//!     .with_units(2.0)
//!     .with_meal(`MealType`::Snack);
//!
//! // Only update portion size
//! let partial = FoodEntryUpdate::new().with_units(1.5);
//! ```
//!
//! ## Date Conversion
//!
//! ```rust
//! use meal_planner::fatsecret::diary::{date_to_int, int_to_date};
//!
//! // ISO date to `FatSecret` format
//! let `date_int` = date_to_int("2024-01-01").unwrap();
//! assert_eq!(`date_int`, 19723);
//!
//! // `FatSecret` format back to ISO
//! let iso_date = int_to_date(19723).unwrap();
//! assert_eq!(iso_date, "2024-01-01");
//!
//! // Epoch start
//! assert_eq!(date_to_int("1970-01-01").unwrap(), 0);
//! ```
//!
//! ## Validation
//!
//! ```rust
//! use meal_planner::fatsecret::diary::validate_custom_entry;
//!
//! // Valid custom entry
//! let result = validate_custom_entry(
//!     "Apple",
//!     "1 medium",
//!     1.0,    // units
//!     95.0,   // calories
//!     25.0,   // carbs
//!     0.5,    // protein
//!     0.3,    // fat
//! );
//! assert!(result.is_ok());
//!
//! // Invalid: negative nutrition
//! let result = validate_custom_entry(
//!     "Bad Food",
//!     "1 serving",
//!     1.0,
//!     -100.0,  // ❌ negative calories
//!     10.0,
//!     5.0,
//!     2.0,
//! );
//! assert!(result.is_err());
//! ```
//!
//! ## Working with Meal Types
//!
//! ```rust
//! use meal_planner::fatsecret::diary::`MealType`;
//!
//! let meal = `MealType`::Breakfast;
//! assert_eq!(meal.to_api_string(), "breakfast");
//!
//! let parsed = `MealType`::from_api_string("lunch").unwrap();
//! assert_eq!(parsed, `MealType`::Lunch);
//!
//! // "other" maps to Snack
//! let snack = `MealType`::from_api_string("other").unwrap();
//! assert_eq!(snack, `MealType`::Snack);
//! ```
//!
//! # Type Safety
//!
//! ## `FoodEntryId` Newtype
//!
//! The [`FoodEntryId`] newtype prevents accidental misuse of entry IDs:
//!
//! ```rust
//! use meal_planner::fatsecret::diary::`FoodEntryId`;
//!
//! let id = `FoodEntryId`::new("123456");
//! let id_str: &str = id.as_str();
//! assert_eq!(id_str, "123456");
//!
//! // Type safety: can't accidentally pass wrong string type
//! // fn delete(id: &`FoodEntryId`) { ... }
//! // delete("raw_string"); // ❌ compile error
//! ```
//!
//! # Implementation Details
//!
//! - Uses `chrono` for date calculations
//! - All numeric fields use `f64` for precision
//! - Optional nutrition fields default to `None`
//! - Implements `Display`, `Debug`, `Clone`, `Serialize`, `Deserialize` where appropriate
//! - Comprehensive unit tests for all conversion and validation logic

use serde::{Deserialize, Serialize};

use crate::fatsecret::core::serde_utils::{
    deserialize_flexible_float, deserialize_flexible_int, deserialize_optional_flexible_float,
    deserialize_single_or_vec,
};

// ============================================================================
// MealType
// ============================================================================

/// Meal type for diary entries
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum MealType {
    /// Breakfast meal
    Breakfast,
    /// Lunch meal
    Lunch,
    /// Dinner meal
    Dinner,
    /// Snack or other meal
    #[serde(rename = "other")]
    Snack,
}

impl MealType {
    /// Convert `MealType` to API string
    pub fn to_api_string(&self) -> &'static str {
        match self {
            MealType::Breakfast => "breakfast",
            MealType::Lunch => "lunch",
            MealType::Dinner => "dinner",
            MealType::Snack => "other",
        }
    }

    /// Parse `MealType` from API string
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

/// Opaque food entry ID from `FatSecret` API
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct FoodEntryId(String);

impl FoodEntryId {
    /// Create a `FoodEntryId` from a string
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
    /// Unique entry ID from `FatSecret`
    pub food_entry_id: FoodEntryId,
    /// Entry display name
    pub food_entry_name: String,
    /// Full description (includes serving size info)
    pub food_entry_description: String,
    /// Food ID (if from `FatSecret` database, empty for custom)
    pub food_id: String,
    /// Serving ID (if from `FatSecret` database, empty for custom)
    pub serving_id: String,
    /// Number of servings consumed
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_units: f64,
    /// Which meal this entry belongs to
    pub meal: MealType,
    /// Date as days since Unix epoch (0 = 1970-01-01)
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub date_int: i32,
    /// Calories
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub calories: f64,
    /// Carbohydrates in grams
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub carbohydrate: f64,
    /// Protein in grams
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub protein: f64,
    /// Total fat in grams
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub fat: f64,
    /// Saturated fat in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub saturated_fat: Option<f64>,
    /// Polyunsaturated fat in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub polyunsaturated_fat: Option<f64>,
    /// Monounsaturated fat in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub monounsaturated_fat: Option<f64>,
    /// Cholesterol in milligrams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub cholesterol: Option<f64>,
    /// Sodium in milligrams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub sodium: Option<f64>,
    /// Potassium in milligrams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub potassium: Option<f64>,
    /// Fiber in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub fiber: Option<f64>,
    /// Sugar in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub sugar: Option<f64>,
}

/// Input for creating a new food entry
///
/// Two ways to create entries:
/// 1. `FromFood`: Reference an existing `FatSecret` food with serving
/// 2. Custom: Manually enter all nutrition values
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum FoodEntryInput {
    /// Create entry from `FatSecret` database food
    FromFood {
        /// `FatSecret` food database ID
        food_id: String,
        /// Display name for the food entry
        food_entry_name: String,
        /// `FatSecret` serving ID
        serving_id: String,
        /// Number of servings consumed
        number_of_units: f64,
        /// Which meal this entry belongs to
        meal: MealType,
        /// Date as days since Unix epoch
        date_int: i32,
    },
    /// Create custom entry with manual nutrition values
    Custom {
        /// Display name for the food entry
        food_entry_name: String,
        /// Description of the serving size
        serving_description: String,
        /// Number of servings consumed
        number_of_units: f64,
        /// Which meal this entry belongs to
        meal: MealType,
        /// Date as days since Unix epoch
        date_int: i32,
        /// Calories per serving
        calories: f64,
        /// Carbohydrates in grams per serving
        carbohydrate: f64,
        /// Protein in grams per serving
        protein: f64,
        /// Fat in grams per serving
        fat: f64,
    },
}

impl FoodEntryInput {
    /// Returns the food entry name
    pub fn food_entry_name(&self) -> &str {
        match self {
            FoodEntryInput::FromFood {
                food_entry_name, ..
            }
            | FoodEntryInput::Custom {
                food_entry_name, ..
            } => food_entry_name,
        }
    }
}

/// Update for an existing food entry
///
/// Only allows updating serving size and meal type.
/// To change nutrition values, delete and recreate the entry.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct FoodEntryUpdate {
    /// New number of servings (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub number_of_units: Option<f64>,
    /// New meal type (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub meal: Option<MealType>,
}

impl FoodEntryUpdate {
    /// Creates a new empty update
    pub fn new() -> Self {
        Self::default()
    }

    /// Sets the number of units to update
    #[must_use]
    pub fn with_units(mut self, units: f64) -> Self {
        self.number_of_units = Some(units);
        self
    }

    /// Sets the meal type to update
    #[must_use]
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
    /// Date as days since Unix epoch
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub date_int: i32,
    /// Total calories for the day
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub calories: f64,
    /// Total carbohydrates in grams
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub carbohydrate: f64,
    /// Total protein in grams
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub protein: f64,
    /// Total fat in grams
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub fat: f64,
}

/// Monthly nutrition summary
///
/// Contains a summary for each day in the month.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MonthSummary {
    /// Daily summaries for each day with logged entries
    #[serde(
        rename = "day",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub days: Vec<DaySummary>,
    /// Month number (1-12)
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub month: i32,
    /// Year (e.g., 2024)
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub year: i32,
}

// ============================================================================
// Date Conversion Functions
// ============================================================================

/// Unix epoch date (1970-01-01) - constant for date calculations
const UNIX_EPOCH_DATE: (i32, u32, u32) = (1970, 1, 1);

/// Convert YYYY-MM-DD to days since epoch (`date_int`)
#[allow(clippy::arithmetic_side_effects)] // Safe: chrono date subtraction is bounded
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

// ============================================================================
// Validation Functions
// ============================================================================

/// Validation error for custom entries
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ValidationError(pub String);

impl std::fmt::Display for ValidationError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl std::error::Error for ValidationError {}

/// Validate custom food entry data
#[allow(clippy::too_many_arguments)] // Validation needs all fields to check
pub fn validate_custom_entry(
    food_entry_name: &str,
    serving_description: &str,
    number_of_units: f64,
    calories: f64,
    carbohydrate: f64,
    protein: f64,
    fat: f64,
) -> Result<(), ValidationError> {
    if food_entry_name.is_empty() {
        return Err(ValidationError(
            "food_entry_name cannot be empty".to_string(),
        ));
    }
    if serving_description.is_empty() {
        return Err(ValidationError(
            "serving_description cannot be empty".to_string(),
        ));
    }
    validate_number_of_units(number_of_units)?;
    if calories < 0.0 || carbohydrate < 0.0 || protein < 0.0 || fat < 0.0 {
        return Err(ValidationError(
            "Nutrition values cannot be negative".to_string(),
        ));
    }
    Ok(())
}

/// Validate number of units is positive
pub fn validate_number_of_units(number_of_units: f64) -> Result<(), ValidationError> {
    if number_of_units > 0.0 {
        Ok(())
    } else {
        Err(ValidationError(
            "number_of_units must be greater than 0".to_string(),
        ))
    }
}

/// Validate `date_int` string from URL parameter
pub fn validate_date_int_string(date_int_str: &str) -> Option<i32> {
    date_int_str.parse().ok()
}

// ============================================================================
// Auth Error Types
// ============================================================================

/// Simplified auth error for mapping HTTP status codes
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AuthError {
    /// User's OAuth authorization was revoked (401/403)
    AuthRevoked,
    /// Any other error type
    OtherError,
}

/// Map HTTP auth error codes to service errors
pub fn map_auth_error(status_code: u16) -> AuthError {
    match status_code {
        401 | 403 => AuthError::AuthRevoked,
        _ => AuthError::OtherError,
    }
}

#[cfg(test)]
#[allow(clippy::unwrap_used)] // Tests are allowed to use unwrap/expect
mod tests {
    use super::*;

    // ========================================================================
    // Date Conversion Tests
    // ========================================================================

    #[test]
    fn test_date_to_int_epoch() {
        assert_eq!(date_to_int("1970-01-01").unwrap(), 0);
    }

    #[test]
    fn test_date_to_int_sequential_days() {
        assert_eq!(date_to_int("1970-01-02").unwrap(), 1);
        assert_eq!(date_to_int("1970-01-03").unwrap(), 2);
        assert_eq!(date_to_int("1970-01-10").unwrap(), 9);
    }

    #[test]
    fn test_date_to_int_modern_dates() {
        assert_eq!(date_to_int("2024-01-01").unwrap(), 19723);
        assert_eq!(date_to_int("2024-12-31").unwrap(), 20088);
        assert_eq!(date_to_int("2025-01-01").unwrap(), 20089);
    }

    #[test]
    fn test_date_to_int_leap_year() {
        // 2024 is a leap year
        assert_eq!(date_to_int("2024-02-29").unwrap(), 19782);
        assert_eq!(date_to_int("2024-03-01").unwrap(), 19783);
    }

    #[test]
    fn test_date_to_int_invalid_format() {
        assert!(date_to_int("2024/01/01").is_err());
        assert!(date_to_int("01-01-2024").is_err());
        // Note: chrono actually accepts single-digit months/days, so "2024-1-1" parses fine
        assert!(date_to_int("invalid").is_err());
        assert!(date_to_int("").is_err());
    }

    #[test]
    fn test_date_to_int_invalid_dates() {
        assert!(date_to_int("2024-02-30").is_err()); // Feb doesn't have 30 days
        assert!(date_to_int("2024-13-01").is_err()); // Invalid month
        assert!(date_to_int("2024-00-01").is_err()); // Invalid month
    }

    #[test]
    fn test_int_to_date_epoch() {
        assert_eq!(int_to_date(0).unwrap(), "1970-01-01");
    }

    #[test]
    fn test_int_to_date_sequential_days() {
        assert_eq!(int_to_date(1).unwrap(), "1970-01-02");
        assert_eq!(int_to_date(2).unwrap(), "1970-01-03");
        assert_eq!(int_to_date(365).unwrap(), "1971-01-01");
    }

    #[test]
    fn test_int_to_date_modern_dates() {
        assert_eq!(int_to_date(19723).unwrap(), "2024-01-01");
        assert_eq!(int_to_date(20088).unwrap(), "2024-12-31");
        assert_eq!(int_to_date(20089).unwrap(), "2025-01-01");
    }

    #[test]
    fn test_int_to_date_negative() {
        // Dates before epoch
        assert_eq!(int_to_date(-1).unwrap(), "1969-12-31");
        assert_eq!(int_to_date(-365).unwrap(), "1969-01-01");
    }

    #[test]
    fn test_date_conversion_roundtrip() {
        let dates = [
            "1970-01-01",
            "2000-01-01",
            "2024-06-15",
            "2024-12-31",
            "2025-01-01",
        ];
        for date in dates {
            let int = date_to_int(date).unwrap();
            let back = int_to_date(int).unwrap();
            assert_eq!(date, back);
        }
    }

    // ========================================================================
    // MealType Tests
    // ========================================================================

    #[test]
    fn test_meal_type_to_api_string() {
        assert_eq!(MealType::Breakfast.to_api_string(), "breakfast");
        assert_eq!(MealType::Lunch.to_api_string(), "lunch");
        assert_eq!(MealType::Dinner.to_api_string(), "dinner");
        assert_eq!(MealType::Snack.to_api_string(), "other");
    }

    #[test]
    fn test_meal_type_from_api_string() {
        assert_eq!(
            MealType::from_api_string("breakfast"),
            Some(MealType::Breakfast)
        );
        assert_eq!(MealType::from_api_string("lunch"), Some(MealType::Lunch));
        assert_eq!(MealType::from_api_string("dinner"), Some(MealType::Dinner));
        assert_eq!(MealType::from_api_string("other"), Some(MealType::Snack));
        assert_eq!(MealType::from_api_string("snack"), Some(MealType::Snack));
    }

    #[test]
    fn test_meal_type_from_api_string_invalid() {
        assert_eq!(MealType::from_api_string("invalid"), None);
        assert_eq!(MealType::from_api_string(""), None);
        assert_eq!(MealType::from_api_string("BREAKFAST"), None); // Case sensitive
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

    #[test]
    fn test_meal_type_display() {
        assert_eq!(format!("{}", MealType::Breakfast), "breakfast");
        assert_eq!(format!("{}", MealType::Lunch), "lunch");
        assert_eq!(format!("{}", MealType::Dinner), "dinner");
        assert_eq!(format!("{}", MealType::Snack), "other");
    }

    #[test]
    fn test_meal_type_serde_json() {
        let json = serde_json::json!("breakfast");
        let meal: MealType = serde_json::from_value(json).unwrap();
        assert_eq!(meal, MealType::Breakfast);

        let json = serde_json::json!("other");
        let meal: MealType = serde_json::from_value(json).unwrap();
        assert_eq!(meal, MealType::Snack);
    }

    // ========================================================================
    // FoodEntryId Tests
    // ========================================================================

    #[test]
    fn test_food_entry_id_new() {
        let id = FoodEntryId::new("12345");
        assert_eq!(id.as_str(), "12345");
    }

    #[test]
    fn test_food_entry_id_from_string() {
        let id: FoodEntryId = "67890".into();
        assert_eq!(id.as_str(), "67890");

        let id: FoodEntryId = String::from("abc123").into();
        assert_eq!(id.as_str(), "abc123");
    }

    #[test]
    fn test_food_entry_id_display() {
        let id = FoodEntryId::new("test-id");
        assert_eq!(format!("{}", id), "test-id");
    }

    #[test]
    fn test_food_entry_id_equality() {
        let id1 = FoodEntryId::new("12345");
        let id2 = FoodEntryId::new("12345");
        let id3 = FoodEntryId::new("67890");

        assert_eq!(id1, id2);
        assert_ne!(id1, id3);
    }

    #[test]
    fn test_food_entry_id_clone() {
        let id1 = FoodEntryId::new("12345");
        let id2 = id1.clone();
        assert_eq!(id1, id2);
    }

    // ========================================================================
    // Validation Tests
    // ========================================================================

    #[test]
    fn test_validate_custom_entry_valid() {
        assert!(validate_custom_entry("Apple", "1 medium", 1.0, 95.0, 25.0, 0.5, 0.3).is_ok());
        assert!(validate_custom_entry("Chicken", "100g", 2.5, 200.0, 0.0, 40.0, 5.0).is_ok());
    }

    #[test]
    fn test_validate_custom_entry_valid_zero_nutrition() {
        // Zero nutrition values are valid (e.g., water has 0 calories)
        assert!(validate_custom_entry("Water", "1 glass", 1.0, 0.0, 0.0, 0.0, 0.0).is_ok());
    }

    #[test]
    fn test_validate_custom_entry_empty_name() {
        let result = validate_custom_entry("", "1 medium", 1.0, 95.0, 25.0, 0.5, 0.3);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err().0, "food_entry_name cannot be empty");
    }

    #[test]
    fn test_validate_custom_entry_empty_serving() {
        let result = validate_custom_entry("Apple", "", 1.0, 95.0, 25.0, 0.5, 0.3);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err().0, "serving_description cannot be empty");
    }

    #[test]
    fn test_validate_custom_entry_zero_units() {
        let result = validate_custom_entry("Apple", "1 medium", 0.0, 95.0, 25.0, 0.5, 0.3);
        assert!(result.is_err());
        assert_eq!(
            result.unwrap_err().0,
            "number_of_units must be greater than 0"
        );
    }

    #[test]
    fn test_validate_custom_entry_negative_units() {
        let result = validate_custom_entry("Apple", "1 medium", -1.0, 95.0, 25.0, 0.5, 0.3);
        assert!(result.is_err());
        assert_eq!(
            result.unwrap_err().0,
            "number_of_units must be greater than 0"
        );
    }

    #[test]
    fn test_validate_custom_entry_negative_calories() {
        let result = validate_custom_entry("Apple", "1 medium", 1.0, -95.0, 25.0, 0.5, 0.3);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err().0, "Nutrition values cannot be negative");
    }

    #[test]
    fn test_validate_custom_entry_negative_carbs() {
        let result = validate_custom_entry("Apple", "1 medium", 1.0, 95.0, -25.0, 0.5, 0.3);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err().0, "Nutrition values cannot be negative");
    }

    #[test]
    fn test_validate_custom_entry_negative_protein() {
        let result = validate_custom_entry("Apple", "1 medium", 1.0, 95.0, 25.0, -0.5, 0.3);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err().0, "Nutrition values cannot be negative");
    }

    #[test]
    fn test_validate_custom_entry_negative_fat() {
        let result = validate_custom_entry("Apple", "1 medium", 1.0, 95.0, 25.0, 0.5, -0.3);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err().0, "Nutrition values cannot be negative");
    }

    #[test]
    fn test_validate_number_of_units_valid() {
        assert!(validate_number_of_units(1.0).is_ok());
        assert!(validate_number_of_units(0.5).is_ok());
        assert!(validate_number_of_units(0.001).is_ok());
        assert!(validate_number_of_units(100.0).is_ok());
    }

    #[test]
    fn test_validate_number_of_units_invalid() {
        assert!(validate_number_of_units(0.0).is_err());
        assert!(validate_number_of_units(-1.0).is_err());
        assert!(validate_number_of_units(-0.001).is_err());
    }

    #[test]
    fn test_validate_date_int_string_valid() {
        assert_eq!(validate_date_int_string("19723"), Some(19723));
        assert_eq!(validate_date_int_string("0"), Some(0));
        assert_eq!(validate_date_int_string("1"), Some(1));
        assert_eq!(validate_date_int_string("99999"), Some(99999));
    }

    #[test]
    fn test_validate_date_int_string_negative() {
        assert_eq!(validate_date_int_string("-1"), Some(-1));
        assert_eq!(validate_date_int_string("-365"), Some(-365));
    }

    #[test]
    fn test_validate_date_int_string_invalid() {
        assert_eq!(validate_date_int_string("invalid"), None);
        assert_eq!(validate_date_int_string(""), None);
        assert_eq!(validate_date_int_string("12.5"), None);
        assert_eq!(validate_date_int_string("12a"), None);
    }

    #[test]
    fn test_validation_error_display() {
        let err = ValidationError("test error".to_string());
        assert_eq!(format!("{}", err), "test error");
    }

    // ========================================================================
    // Auth Error Tests
    // ========================================================================

    #[test]
    fn test_map_auth_error_revoked() {
        assert_eq!(map_auth_error(401), AuthError::AuthRevoked);
        assert_eq!(map_auth_error(403), AuthError::AuthRevoked);
    }

    #[test]
    fn test_map_auth_error_other() {
        assert_eq!(map_auth_error(500), AuthError::OtherError);
        assert_eq!(map_auth_error(404), AuthError::OtherError);
        assert_eq!(map_auth_error(400), AuthError::OtherError);
        assert_eq!(map_auth_error(200), AuthError::OtherError);
    }

    // ========================================================================
    // FoodEntryInput Tests
    // ========================================================================

    #[test]
    fn test_food_entry_input_from_food_name() {
        let input = FoodEntryInput::FromFood {
            food_id: "123".to_string(),
            food_entry_name: "Banana".to_string(),
            serving_id: "456".to_string(),
            number_of_units: 1.0,
            meal: MealType::Breakfast,
            date_int: 19723,
        };
        assert_eq!(input.food_entry_name(), "Banana");
    }

    #[test]
    fn test_food_entry_input_custom_name() {
        let input = FoodEntryInput::Custom {
            food_entry_name: "Homemade Smoothie".to_string(),
            serving_description: "1 large glass".to_string(),
            number_of_units: 1.0,
            meal: MealType::Snack,
            date_int: 19723,
            calories: 250.0,
            carbohydrate: 30.0,
            protein: 20.0,
            fat: 5.0,
        };
        assert_eq!(input.food_entry_name(), "Homemade Smoothie");
    }

    // ========================================================================
    // FoodEntryUpdate Tests
    // ========================================================================

    #[test]
    fn test_food_entry_update_new() {
        let update = FoodEntryUpdate::new();
        assert!(update.number_of_units.is_none());
        assert!(update.meal.is_none());
    }

    #[test]
    fn test_food_entry_update_with_units() {
        let update = FoodEntryUpdate::new().with_units(2.0);
        assert_eq!(update.number_of_units, Some(2.0));
        assert!(update.meal.is_none());
    }

    #[test]
    fn test_food_entry_update_with_meal() {
        let update = FoodEntryUpdate::new().with_meal(MealType::Lunch);
        assert!(update.number_of_units.is_none());
        assert_eq!(update.meal, Some(MealType::Lunch));
    }

    #[test]
    fn test_food_entry_update_chained() {
        let update = FoodEntryUpdate::new()
            .with_units(1.5)
            .with_meal(MealType::Dinner);
        assert_eq!(update.number_of_units, Some(1.5));
        assert_eq!(update.meal, Some(MealType::Dinner));
    }

    #[test]
    fn test_food_entry_update_default() {
        let update: FoodEntryUpdate = FoodEntryUpdate::default();
        assert!(update.number_of_units.is_none());
        assert!(update.meal.is_none());
    }

    // ========================================================================
    // FoodEntry Deserialization Tests
    // ========================================================================

    #[test]
    fn test_food_entry_deserialize_from_json() {
        let json = r#"{
            "food_entry_id": "12345",
            "food_entry_name": "Banana",
            "food_entry_description": "1 medium banana",
            "food_id": "100",
            "serving_id": "200",
            "number_of_units": "1.5",
            "meal": "breakfast",
            "date_int": "19723",
            "calories": "157.5",
            "carbohydrate": "40.5",
            "protein": "1.5",
            "fat": "0.6"
        }"#;

        let entry: FoodEntry = serde_json::from_str(json).unwrap();
        assert_eq!(entry.food_entry_id.as_str(), "12345");
        assert_eq!(entry.food_entry_name, "Banana");
        assert!((entry.number_of_units - 1.5).abs() < f64::EPSILON);
        assert_eq!(entry.meal, MealType::Breakfast);
        assert_eq!(entry.date_int, 19723);
        assert!((entry.calories - 157.5).abs() < f64::EPSILON);
    }

    #[test]
    fn test_food_entry_deserialize_numeric_values() {
        let json = r#"{
            "food_entry_id": "12345",
            "food_entry_name": "Chicken",
            "food_entry_description": "100g grilled chicken",
            "food_id": "101",
            "serving_id": "201",
            "number_of_units": 2.0,
            "meal": "dinner",
            "date_int": 19723,
            "calories": 300.0,
            "carbohydrate": 0.0,
            "protein": 60.0,
            "fat": 6.0
        }"#;

        let entry: FoodEntry = serde_json::from_str(json).unwrap();
        assert!((entry.number_of_units - 2.0).abs() < f64::EPSILON);
        assert_eq!(entry.date_int, 19723);
        assert!((entry.calories - 300.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_food_entry_deserialize_optional_fields() {
        let json = r#"{
            "food_entry_id": "12345",
            "food_entry_name": "Apple",
            "food_entry_description": "1 medium apple",
            "food_id": "102",
            "serving_id": "202",
            "number_of_units": "1",
            "meal": "other",
            "date_int": "19723",
            "calories": "95",
            "carbohydrate": "25",
            "protein": "0.5",
            "fat": "0.3",
            "fiber": "4.4",
            "sugar": "19"
        }"#;

        let entry: FoodEntry = serde_json::from_str(json).unwrap();
        assert_eq!(entry.meal, MealType::Snack);
        assert_eq!(entry.fiber, Some(4.4));
        assert_eq!(entry.sugar, Some(19.0));
        assert!(entry.saturated_fat.is_none());
    }

    #[test]
    fn test_food_entry_deserialize_meal_types() {
        for (meal_str, expected) in [
            ("breakfast", MealType::Breakfast),
            ("lunch", MealType::Lunch),
            ("dinner", MealType::Dinner),
            ("other", MealType::Snack),
        ] {
            let json = format!(
                r#"{{
                "food_entry_id": "1",
                "food_entry_name": "Test",
                "food_entry_description": "Test",
                "food_id": "1",
                "serving_id": "1",
                "number_of_units": "1",
                "meal": "{}",
                "date_int": "19723",
                "calories": "100",
                "carbohydrate": "10",
                "protein": "10",
                "fat": "10"
            }}"#,
                meal_str
            );

            let entry: FoodEntry = serde_json::from_str(&json).unwrap();
            assert_eq!(entry.meal, expected);
        }
    }

    // ========================================================================
    // DaySummary Tests
    // ========================================================================

    #[test]
    fn test_day_summary_deserialize() {
        let json = r#"{
            "date_int": "19723",
            "calories": "2500",
            "carbohydrate": "300",
            "protein": "150",
            "fat": "80"
        }"#;

        let summary: DaySummary = serde_json::from_str(json).unwrap();
        assert_eq!(summary.date_int, 19723);
        assert!((summary.calories - 2500.0).abs() < f64::EPSILON);
        assert!((summary.carbohydrate - 300.0).abs() < f64::EPSILON);
        assert!((summary.protein - 150.0).abs() < f64::EPSILON);
        assert!((summary.fat - 80.0).abs() < f64::EPSILON);
    }

    #[test]
    fn test_day_summary_deserialize_numeric() {
        let json = r#"{
            "date_int": 19723,
            "calories": 2500.5,
            "carbohydrate": 300.2,
            "protein": 150.8,
            "fat": 80.1
        }"#;

        let summary: DaySummary = serde_json::from_str(json).unwrap();
        assert_eq!(summary.date_int, 19723);
        assert!((summary.calories - 2500.5).abs() < f64::EPSILON);
    }

    // ========================================================================
    // MonthSummary Tests
    // ========================================================================

    #[test]
    fn test_month_summary_deserialize_single_day() {
        let json = r#"{
            "day": {
                "date_int": "19723",
                "calories": "2000",
                "carbohydrate": "250",
                "protein": "120",
                "fat": "70"
            },
            "month": "1",
            "year": "2024"
        }"#;

        let summary: MonthSummary = serde_json::from_str(json).unwrap();
        assert_eq!(summary.days.len(), 1);
        assert_eq!(summary.month, 1);
        assert_eq!(summary.year, 2024);
        assert_eq!(
            summary.days.first().expect("should have day").date_int,
            19723
        );
    }

    #[test]
    fn test_month_summary_deserialize_multiple_days() {
        let json = r#"{
            "day": [
                {
                    "date_int": "19723",
                    "calories": "2000",
                    "carbohydrate": "250",
                    "protein": "120",
                    "fat": "70"
                },
                {
                    "date_int": "19724",
                    "calories": "2100",
                    "carbohydrate": "260",
                    "protein": "130",
                    "fat": "75"
                }
            ],
            "month": "1",
            "year": "2024"
        }"#;

        let summary: MonthSummary = serde_json::from_str(json).unwrap();
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
    }

    #[test]
    fn test_month_summary_deserialize_no_days() {
        let json = r#"{
            "month": "1",
            "year": "2024"
        }"#;

        let summary: MonthSummary = serde_json::from_str(json).unwrap();
        assert_eq!(summary.days.len(), 0);
        assert_eq!(summary.month, 1);
        assert_eq!(summary.year, 2024);
    }
}
