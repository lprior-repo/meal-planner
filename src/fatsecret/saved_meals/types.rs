//! `FatSecret` Saved Meals Domain Types

use crate::fatsecret::core::serde_utils::{deserialize_flexible_float, deserialize_single_or_vec};
use serde::{Deserialize, Serialize};

// ============================================================================
// Opaque ID Types
// ============================================================================

/// Opaque type for `FatSecret` saved meal IDs
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct SavedMealId(String);

impl SavedMealId {
    /// Creates a new saved meal ID from any string-like type
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the ID as a string slice
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl From<String> for SavedMealId {
    fn from(s: String) -> Self {
        Self(s)
    }
}

impl From<&str> for SavedMealId {
    fn from(s: &str) -> Self {
        Self(s.to_string())
    }
}

impl std::fmt::Display for SavedMealId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

/// Opaque type for `FatSecret` saved meal item IDs
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct SavedMealItemId(String);

impl SavedMealItemId {
    /// Creates a new saved meal item ID from any string-like type
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the ID as a string slice
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

// ============================================================================
// Meal Types
// ============================================================================

/// Meal types that a saved meal can be used for
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
    /// Converts the meal type to its `FatSecret` API string representation
    pub fn to_api_string(&self) -> &'static str {
        match self {
            MealType::Breakfast => "breakfast",
            MealType::Lunch => "lunch",
            MealType::Dinner => "dinner",
            MealType::Snack => "other",
        }
    }
}

// ============================================================================
// Domain Types
// ============================================================================

/// A saved meal template (collection of food items)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SavedMeal {
    /// Unique saved meal ID
    pub saved_meal_id: SavedMealId,
    /// Name of the saved meal
    pub saved_meal_name: String,
    /// Optional description for the saved meal
    pub saved_meal_description: Option<String>,
    /// Meal types this saved meal is associated with
    #[serde(rename = "meals", deserialize_with = "deserialize_meals")]
    pub meals: Vec<MealType>,
    /// Total calories for the saved meal
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

fn deserialize_meals<'de, D>(deserializer: D) -> Result<Vec<MealType>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let s: String = serde::Deserialize::deserialize(deserializer)?;
    Ok(s.split(',')
        .filter_map(|m| match m.trim() {
            "breakfast" => Some(MealType::Breakfast),
            "lunch" => Some(MealType::Lunch),
            "dinner" => Some(MealType::Dinner),
            "other" | "snack" => Some(MealType::Snack),
            _ => None,
        })
        .collect())
}

/// A food item within a saved meal
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SavedMealItem {
    /// Unique ID for this item within the saved meal
    pub saved_meal_item_id: SavedMealItemId,
    /// `FatSecret` food ID
    pub food_id: String,
    /// Display name for the food entry
    pub food_entry_name: String,
    /// Serving size ID
    pub serving_id: String,
    /// Number of serving units
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_units: f64,
    /// Calories for this item
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub calories: f64,
    /// Carbohydrates in grams
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub carbohydrate: f64,
    /// Protein in grams
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub protein: f64,
    /// Fat in grams
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub fat: f64,
}

/// Input for creating/editing saved meal items
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum SavedMealItemInput {
    /// Reference an existing `FatSecret` food by ID and serving
    ByFoodId {
        /// `FatSecret` food ID to reference
        food_id: String,
        /// Serving size ID
        serving_id: String,
        /// Number of serving units
        number_of_units: f64,
    },
    /// Create custom entry with nutrition values
    ByNutrition {
        /// Display name for the custom food entry
        food_entry_name: String,
        /// Description of the serving size (e.g., "1 cup", "100g")
        serving_description: String,
        /// Number of serving units
        number_of_units: f64,
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

// ============================================================================
// Response Wrappers
// ============================================================================

/// Response from `saved_meals.get.v2` API
#[derive(Debug, Deserialize)]
pub struct SavedMealsResponse {
    /// List of saved meals returned by the API
    #[serde(
        rename = "saved_meal",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub saved_meals: Vec<SavedMeal>,
    /// Optional meal type filter applied to the response
    pub meal_filter: Option<String>,
}

/// Response from `saved_meal_items.get.v2` API
#[derive(Debug, Deserialize)]
pub struct SavedMealItemsResponse {
    /// ID of the saved meal these items belong to
    pub saved_meal_id: SavedMealId,
    /// List of food items in the saved meal
    #[serde(
        rename = "item",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub items: Vec<SavedMealItem>,
}

/// Top-level wrapper for `saved_meals.get.v2` API response
#[derive(Debug, Deserialize)]
pub struct SavedMealsResponseWrapper {
    /// The saved meals response data
    pub saved_meals: SavedMealsResponse,
}

/// Top-level wrapper for `saved_meal_items.get.v2` API response
#[derive(Debug, Deserialize)]
pub struct SavedMealItemsResponseWrapper {
    /// The saved meal items response data
    pub saved_meal_items: SavedMealItemsResponse,
}
