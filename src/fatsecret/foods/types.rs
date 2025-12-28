//! FatSecret Food Domain Types
//!
//! These types represent foods, servings, and nutrition information
//! from the FatSecret Platform API.

use serde::{Deserialize, Serialize};

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
    pub calories: f64,
    pub carbohydrate: f64,
    pub protein: f64,
    pub fat: f64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub saturated_fat: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub polyunsaturated_fat: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub monounsaturated_fat: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub trans_fat: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub cholesterol: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sodium: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub potassium: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub fiber: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sugar: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub added_sugars: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub vitamin_a: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub vitamin_c: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub vitamin_d: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub calcium: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
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
    #[serde(skip_serializing_if = "Option::is_none")]
    pub metric_serving_amount: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub metric_serving_unit: Option<String>,
    pub number_of_units: f64,
    pub measurement_description: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub is_default: Option<i32>,
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
    pub servings: Vec<Serving>,
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
    pub foods: Vec<FoodSearchResult>,
    pub max_results: i32,
    pub total_results: i32,
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
    pub suggestions: Vec<FoodSuggestion>,
}
