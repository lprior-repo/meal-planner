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
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }
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
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }
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
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub calories: f64,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub carbohydrate: f64,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub protein: f64,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub fat: f64,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub saturated_fat: Option<f64>,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub polyunsaturated_fat: Option<f64>,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub monounsaturated_fat: Option<f64>,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub trans_fat: Option<f64>,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub cholesterol: Option<f64>,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub sodium: Option<f64>,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub potassium: Option<f64>,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub fiber: Option<f64>,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub sugar: Option<f64>,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub added_sugars: Option<f64>,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub vitamin_a: Option<f64>,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub vitamin_c: Option<f64>,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub vitamin_d: Option<f64>,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub calcium: Option<f64>,
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
    pub serving_id: ServingId,
    pub serving_description: String,
    pub serving_url: String,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub metric_serving_amount: Option<f64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub metric_serving_unit: Option<String>,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_units: f64,
    pub measurement_description: String,
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_optional_flexible_int"
    )]
    pub is_default: Option<i32>,
    #[serde(flatten)]
    pub nutrition: Nutrition,
}

// ============================================================================
// Food Information
// ============================================================================

/// Complete food details from FatSecret API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Food {
    pub food_id: FoodId,
    pub food_name: String,
    pub food_type: String,
    pub food_url: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub brand_name: Option<String>,
    pub servings: FoodServings,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodServings {
    #[serde(rename = "serving", deserialize_with = "deserialize_single_or_vec")]
    pub serving: Vec<Serving>,
}

// ============================================================================
// Search Results
// ============================================================================

/// Single food search result
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodSearchResult {
    pub food_id: FoodId,
    pub food_name: String,
    pub food_type: String,
    pub food_description: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub brand_name: Option<String>,
    pub food_url: String,
}

/// Response from foods.search API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodSearchResponse {
    #[serde(rename = "food", default, deserialize_with = "deserialize_single_or_vec")]
    pub foods: Vec<FoodSearchResult>,
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub max_results: i32,
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub total_results: i32,
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub page_number: i32,
}

// ============================================================================
// Autocomplete Results
// ============================================================================

/// Single food autocomplete suggestion
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodSuggestion {
    pub food_id: FoodId,
    pub food_name: String,
}

/// Response from foods.autocomplete API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FoodAutocompleteResponse {
    #[serde(rename = "suggestion", deserialize_with = "deserialize_single_or_vec")]
    pub suggestions: Vec<FoodSuggestion>,
}
