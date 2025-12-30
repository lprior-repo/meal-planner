//! FatSecret Food Domain Types
//!
//! These types represent foods, servings, and nutrition information
//! from the FatSecret Platform API.

use serde::{Deserialize, Serialize};

use crate::fatsecret::core::serde_utils::{
    deserialize_flexible_float, deserialize_flexible_int, deserialize_optional_flexible_float,
    deserialize_optional_flexible_int, deserialize_single_or_vec,
};

// ============================================================================
// Opaque ID Types
// ============================================================================

/// Opaque food ID from FatSecret API
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct FoodId(String);

impl FoodId {
    /// Creates a new FoodId from the given value
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the food ID as a string slice
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl From<String> for FoodId {
    fn from(s: String) -> Self {
        Self(s)
    }
}

impl From<&str> for FoodId {
    fn from(s: &str) -> Self {
        Self(s.to_string())
    }
}

impl std::fmt::Display for FoodId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Opaque serving ID from FatSecret API
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct ServingId(String);

impl ServingId {
    /// Creates a new ServingId from the given value
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the serving ID as a string slice
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl From<String> for ServingId {
    fn from(s: String) -> Self {
        Self(s)
    }
}

impl From<&str> for ServingId {
    fn from(s: &str) -> Self {
        Self(s.to_string())
    }
}

impl std::fmt::Display for ServingId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

// ============================================================================
// Nutrition Information
// ============================================================================

/// Nutrition information for a food serving
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Nutrition {
    /// Calorie content in kcal
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub calories: f64,
    /// Carbohydrate content in grams
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub carbohydrate: f64,
    /// Protein content in grams
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub protein: f64,
    /// Total fat content in grams
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub fat: f64,
    /// Saturated fat content in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub saturated_fat: Option<f64>,
    /// Polyunsaturated fat content in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub polyunsaturated_fat: Option<f64>,
    /// Monounsaturated fat content in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub monounsaturated_fat: Option<f64>,
    /// Trans fat content in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub trans_fat: Option<f64>,
    /// Cholesterol content in milligrams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub cholesterol: Option<f64>,
    /// Sodium content in milligrams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub sodium: Option<f64>,
    /// Potassium content in milligrams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub potassium: Option<f64>,
    /// Dietary fiber content in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub fiber: Option<f64>,
    /// Total sugar content in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub sugar: Option<f64>,
    /// Added sugars content in grams
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub added_sugars: Option<f64>,
    /// Vitamin A as percentage of daily value
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub vitamin_a: Option<f64>,
    /// Vitamin C as percentage of daily value
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub vitamin_c: Option<f64>,
    /// Vitamin D as percentage of daily value
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub vitamin_d: Option<f64>,
    /// Calcium as percentage of daily value
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub calcium: Option<f64>,
    /// Iron as percentage of daily value
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub iron: Option<f64>,
}

// ============================================================================
// Serving Information
// ============================================================================

/// A serving size option for a food
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Serving {
    /// Unique identifier for this serving size
    pub serving_id: ServingId,
    /// Human-readable description of the serving (e.g., "1 cup")
    pub serving_description: String,
    /// URL to the serving details on FatSecret
    pub serving_url: String,
    /// Metric equivalent amount (e.g., 240 for 240g)
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub metric_serving_amount: Option<f64>,
    /// Unit for metric serving amount (e.g., "g", "ml")
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub metric_serving_unit: Option<String>,
    /// Number of units in this serving
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_units: f64,
    /// Description of the measurement unit (e.g., "cup", "tbsp")
    pub measurement_description: String,
    /// Whether this is the default serving size (1 = default)
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_int"
    )]
    pub is_default: Option<i32>,
    /// Nutrition information for this serving size
    #[serde(flatten)]
    pub nutrition: Nutrition,
}

// ============================================================================
// Food Information
// ============================================================================

/// Complete food details from FatSecret API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Food {
    /// Unique identifier for this food
    pub food_id: FoodId,
    /// Name of the food
    pub food_name: String,
    /// Type of food (e.g., "Generic", "Brand")
    pub food_type: String,
    /// URL to the food details on FatSecret
    pub food_url: String,
    /// Brand name for branded foods
    #[serde(skip_serializing_if = "Option::is_none")]
    pub brand_name: Option<String>,
    /// Available serving sizes for this food
    pub servings: FoodServings,
}

/// Container for food serving options
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodServings {
    /// List of available serving sizes
    #[serde(rename = "serving", deserialize_with = "deserialize_single_or_vec")]
    pub serving: Vec<Serving>,
}

// ============================================================================
// Search Results
// ============================================================================

/// Single food search result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodSearchResult {
    /// Unique identifier for this food
    pub food_id: FoodId,
    /// Name of the food
    pub food_name: String,
    /// Type of food (e.g., "Generic", "Brand")
    pub food_type: String,
    /// Brief description including nutrition summary
    pub food_description: String,
    /// Brand name for branded foods
    #[serde(skip_serializing_if = "Option::is_none")]
    pub brand_name: Option<String>,
    /// URL to the food details on FatSecret
    pub food_url: String,
}

/// Response from foods.search API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodSearchResponse {
    /// List of matching foods
    #[serde(
        rename = "food",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub foods: Vec<FoodSearchResult>,
    /// Maximum results per page
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub max_results: i32,
    /// Total number of matching results
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub total_results: i32,
    /// Current page number (0-indexed)
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub page_number: i32,
}

// ============================================================================
// Autocomplete Results
// ============================================================================

/// Single food autocomplete suggestion
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodSuggestion {
    /// Unique identifier for this food
    pub food_id: FoodId,
    /// Name of the suggested food
    pub food_name: String,
}

/// Response from foods.autocomplete API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodAutocompleteResponse {
    /// List of autocomplete suggestions
    #[serde(rename = "suggestion", deserialize_with = "deserialize_single_or_vec")]
    pub suggestions: Vec<FoodSuggestion>,
}
