//! FatSecret Food Diary types
//!
//! These types represent food entries logged in the user's food diary,
//! along with daily and monthly summaries. The FatSecret API uses
//! date_int (days since Unix epoch) for all date operations.

use chrono::NaiveDate;
use serde::{Deserialize, Serialize};
use std::fmt;

// ============================================================================
// MealType
// ============================================================================

/// Meal type for diary entries
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum MealType {
    Breakfast,
    Lunch,
    Dinner,
    Snack,
}

impl MealType {
    /// Convert MealType to API string
    pub fn to_api_string(self) -> &'static str {
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

impl fmt::Display for MealType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.to_api_string())
    }
}

// ============================================================================
// Food Entry ID (opaque type for type safety)
// ============================================================================

/// Opaque food entry ID from FatSecret API
///
/// This type wraps a String ID to provide type safety and prevent
/// accidental mixing with other string IDs.
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct FoodEntryId(String);

impl FoodEntryId {
    /// Create a FoodEntryId from a string
    pub fn new(id: impl Into<String>) -> Self {
        FoodEntryId(id.into())
    }

    /// Convert FoodEntryId to string for API calls
    pub fn as_str(&self) -> &str {
        &self.0
    }

    /// Consume and return the inner string
    pub fn into_inner(self) -> String {
        self.0
    }
}

impl fmt::Display for FoodEntryId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl From<String> for FoodEntryId {
    fn from(s: String) -> Self {
        FoodEntryId::new(s)
    }
}

impl From<&str> for FoodEntryId {
    fn from(s: &str) -> Self {
        FoodEntryId::new(s)
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
    /// Carbohydrate in grams
    pub carbohydrate: f64,
    /// Protein in grams
    pub protein: f64,
    /// Fat in grams
    pub fat: f64,
    /// Saturated fat in grams
    pub saturated_fat: Option<f64>,
    /// Polyunsaturated fat in grams
    pub polyunsaturated_fat: Option<f64>,
    /// Monounsaturated fat in grams
    pub monounsaturated_fat: Option<f64>,
    /// Cholesterol in milligrams
    pub cholesterol: Option<f64>,
    /// Sodium in milligrams
    pub sodium: Option<f64>,
    /// Potassium in milligrams
    pub potassium: Option<f64>,
    /// Fiber in grams
    pub fiber: Option<f64>,
    /// Sugar in grams
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
    pub number_of_units: Option<f64>,
    pub meal: Option<MealType>,
}

impl FoodEntryUpdate {
    /// Create a new empty update
    pub fn new() -> Self {
        Self::default()
    }

    /// Set the number of units
    pub fn with_number_of_units(mut self, units: f64) -> Self {
        self.number_of_units = Some(units);
        self
    }

    /// Set the meal type
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
    pub month: u32,
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
pub fn date_to_int(date: &str) -> Option<i32> {
    let parsed = NaiveDate::parse_from_str(date, "%Y-%m-%d").ok()?;
    let epoch = NaiveDate::from_ymd_opt(1970, 1, 1)?;
    let days = parsed.signed_duration_since(epoch).num_days();
    Some(days as i32)
}

/// Convert days since epoch to YYYY-MM-DD
///
/// Inverse of date_to_int. Returns None for invalid day counts.
/// Examples:
/// - 0 -> "1970-01-01"
/// - 1 -> "1970-01-02"
/// - 19723 -> "2024-01-01"
pub fn int_to_date(date_int: i32) -> Option<String> {
    let epoch = NaiveDate::from_ymd_opt(1970, 1, 1)?;
    let date = epoch.checked_add_signed(chrono::Duration::days(date_int as i64))?;
    Some(date.format("%Y-%m-%d").to_string())
}

/// Convert NaiveDate to date_int
pub fn naive_date_to_int(date: NaiveDate) -> i32 {
    let epoch = NaiveDate::from_ymd_opt(1970, 1, 1).expect("valid epoch date");
    date.signed_duration_since(epoch).num_days() as i32
}

/// Convert date_int to NaiveDate
pub fn int_to_naive_date(date_int: i32) -> Option<NaiveDate> {
    let epoch = NaiveDate::from_ymd_opt(1970, 1, 1)?;
    epoch.checked_add_signed(chrono::Duration::days(date_int as i64))
}

// ============================================================================
// Validation Functions
// ============================================================================

/// Validation error for food entries
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ValidationError {
    EmptyFoodEntryName,
    EmptyServingDescription,
    InvalidNumberOfUnits,
    NegativeNutritionValue,
}

impl fmt::Display for ValidationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ValidationError::EmptyFoodEntryName => write!(f, "food_entry_name cannot be empty"),
            ValidationError::EmptyServingDescription => {
                write!(f, "serving_description cannot be empty")
            }
            ValidationError::InvalidNumberOfUnits => {
                write!(f, "number_of_units must be greater than 0")
            }
            ValidationError::NegativeNutritionValue => {
                write!(f, "Nutrition values cannot be negative")
            }
        }
    }
}

impl std::error::Error for ValidationError {}

/// Validate custom food entry data
///
/// Ensures all nutrition values are valid (allows zero for things like water).
/// Checks that names are not empty and serving descriptions are present.
///
/// Returns Ok(()) if valid, Err with validation message otherwise.
pub fn validate_custom_entry(
    food_entry_name: &str,
    serving_description: &str,
    number_of_units: f64,
    calories: f64,
    carbohydrate: f64,
    protein: f64,
    fat: f64,
) -> Result<(), ValidationError> {
    // Validate name is not empty
    if food_entry_name.is_empty() {
        return Err(ValidationError::EmptyFoodEntryName);
    }

    // Validate serving description is not empty
    if serving_description.is_empty() {
        return Err(ValidationError::EmptyServingDescription);
    }

    // Validate number of units
    validate_number_of_units(number_of_units)?;

    // Validate nutrition values are non-negative (zero is allowed)
    if calories < 0.0 || carbohydrate < 0.0 || protein < 0.0 || fat < 0.0 {
        return Err(ValidationError::NegativeNutritionValue);
    }

    Ok(())
}

/// Validate number of units is positive
///
/// Checks that serving quantity is greater than 0.
/// Returns Ok(()) if valid, Err otherwise.
pub fn validate_number_of_units(number_of_units: f64) -> Result<(), ValidationError> {
    if number_of_units > 0.0 {
        Ok(())
    } else {
        Err(ValidationError::InvalidNumberOfUnits)
    }
}

/// Validate date_int string from URL parameter
///
/// Parses string to ensure it's a valid integer.
/// Returns Ok(i32) if valid, Err(()) otherwise.
pub fn validate_date_int_string(date_int_str: &str) -> Result<i32, ()> {
    date_int_str.parse::<i32>().map_err(|_| ())
}

// ============================================================================
// Auth Error (for API error mapping)
// ============================================================================

/// Authentication error types for API error mapping
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AuthError {
    AuthRevoked,
    OtherError,
}

/// Map HTTP auth error codes to service errors
///
/// Helper for testing error mapping from API layer.
/// Returns simplified error type for 401/403 responses.
pub fn map_auth_error(status_code: u16) -> AuthError {
    match status_code {
        401 | 403 => AuthError::AuthRevoked,
        _ => AuthError::OtherError,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_meal_type_api_string() {
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
        assert_eq!(MealType::from_api_string("invalid"), None);
    }

    #[test]
    fn test_food_entry_id() {
        let id = FoodEntryId::new("12345");
        assert_eq!(id.as_str(), "12345");
        assert_eq!(id.to_string(), "12345");
        assert_eq!(id.into_inner(), "12345");
    }

    #[test]
    fn test_food_entry_id_from() {
        let id1: FoodEntryId = "test".into();
        let id2: FoodEntryId = String::from("test").into();
        assert_eq!(id1, id2);
    }

    #[test]
    fn test_date_to_int() {
        assert_eq!(date_to_int("1970-01-01"), Some(0));
        assert_eq!(date_to_int("1970-01-02"), Some(1));
        assert_eq!(date_to_int("2024-01-01"), Some(19723));
        assert_eq!(date_to_int("invalid"), None);
    }

    #[test]
    fn test_int_to_date() {
        assert_eq!(int_to_date(0), Some("1970-01-01".to_string()));
        assert_eq!(int_to_date(1), Some("1970-01-02".to_string()));
        assert_eq!(int_to_date(19723), Some("2024-01-01".to_string()));
    }

    #[test]
    fn test_date_roundtrip() {
        let dates = ["1970-01-01", "2000-06-15", "2024-12-31"];
        for date in dates {
            let int_val = date_to_int(date).unwrap();
            let back = int_to_date(int_val).unwrap();
            assert_eq!(date, back);
        }
    }

    #[test]
    fn test_validate_number_of_units() {
        assert!(validate_number_of_units(1.0).is_ok());
        assert!(validate_number_of_units(0.5).is_ok());
        assert!(validate_number_of_units(0.0).is_err());
        assert!(validate_number_of_units(-1.0).is_err());
    }

    #[test]
    fn test_validate_custom_entry() {
        // Valid entry
        assert!(validate_custom_entry("Chicken", "100g", 1.0, 165.0, 0.0, 31.0, 3.6).is_ok());

        // Empty name
        assert_eq!(
            validate_custom_entry("", "100g", 1.0, 165.0, 0.0, 31.0, 3.6),
            Err(ValidationError::EmptyFoodEntryName)
        );

        // Empty serving description
        assert_eq!(
            validate_custom_entry("Chicken", "", 1.0, 165.0, 0.0, 31.0, 3.6),
            Err(ValidationError::EmptyServingDescription)
        );

        // Invalid units
        assert_eq!(
            validate_custom_entry("Chicken", "100g", 0.0, 165.0, 0.0, 31.0, 3.6),
            Err(ValidationError::InvalidNumberOfUnits)
        );

        // Negative nutrition
        assert_eq!(
            validate_custom_entry("Chicken", "100g", 1.0, -10.0, 0.0, 31.0, 3.6),
            Err(ValidationError::NegativeNutritionValue)
        );

        // Zero values allowed (e.g., water has 0 calories)
        assert!(validate_custom_entry("Water", "1 cup", 1.0, 0.0, 0.0, 0.0, 0.0).is_ok());
    }

    #[test]
    fn test_validate_date_int_string() {
        assert_eq!(validate_date_int_string("19723"), Ok(19723));
        assert_eq!(validate_date_int_string("0"), Ok(0));
        assert_eq!(validate_date_int_string("-1"), Ok(-1));
        assert!(validate_date_int_string("invalid").is_err());
        assert!(validate_date_int_string("").is_err());
    }

    #[test]
    fn test_map_auth_error() {
        assert_eq!(map_auth_error(401), AuthError::AuthRevoked);
        assert_eq!(map_auth_error(403), AuthError::AuthRevoked);
        assert_eq!(map_auth_error(500), AuthError::OtherError);
        assert_eq!(map_auth_error(200), AuthError::OtherError);
    }

    #[test]
    fn test_food_entry_update_builder() {
        let update = FoodEntryUpdate::new()
            .with_number_of_units(2.5)
            .with_meal(MealType::Dinner);

        assert_eq!(update.number_of_units, Some(2.5));
        assert_eq!(update.meal, Some(MealType::Dinner));
    }
}
