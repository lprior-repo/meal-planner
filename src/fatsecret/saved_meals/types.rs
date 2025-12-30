//! FatSecret Saved Meals Domain Types

use crate::fatsecret::core::serde_utils::{deserialize_flexible_float, deserialize_single_or_vec};
use serde::{Deserialize, Serialize};

// ============================================================================
// Opaque ID Types
// ============================================================================

/// Opaque type for FatSecret saved meal IDs
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct SavedMealId(String);

impl SavedMealId {
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

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

/// Opaque type for FatSecret saved meal item IDs
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct SavedMealItemId(String);

impl SavedMealItemId {
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

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
    Breakfast,
    Lunch,
    Dinner,
    #[serde(rename = "other")]
    Snack,
}

impl MealType {
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
    pub saved_meal_id: SavedMealId,
    pub saved_meal_name: String,
    pub saved_meal_description: Option<String>,
    #[serde(rename = "meals", deserialize_with = "deserialize_meals")]
    pub meals: Vec<MealType>,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub calories: f64,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub carbohydrate: f64,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub protein: f64,
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
    pub saved_meal_item_id: SavedMealItemId,
    pub food_id: String,
    pub food_entry_name: String,
    pub serving_id: String,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_units: f64,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub calories: f64,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub carbohydrate: f64,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub protein: f64,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub fat: f64,
}

/// Input for creating/editing saved meal items
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum SavedMealItemInput {
    /// Reference an existing FatSecret food by ID and serving
    ByFoodId {
        food_id: String,
        serving_id: String,
        number_of_units: f64,
    },
    /// Create custom entry with nutrition values
    ByNutrition {
        food_entry_name: String,
        serving_description: String,
        number_of_units: f64,
        calories: f64,
        carbohydrate: f64,
        protein: f64,
        fat: f64,
    },
}

// ============================================================================
// Response Wrappers
// ============================================================================

/// Response from saved_meals.get.v2 API
#[derive(Debug, Deserialize)]
pub struct SavedMealsResponse {
    #[serde(
        rename = "saved_meal",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub saved_meals: Vec<SavedMeal>,
    pub meal_filter: Option<String>,
}

/// Response from saved_meal_items.get.v2 API
#[derive(Debug, Deserialize)]
pub struct SavedMealItemsResponse {
    pub saved_meal_id: SavedMealId,
    #[serde(
        rename = "item",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub items: Vec<SavedMealItem>,
}

#[derive(Debug, Deserialize)]
pub struct SavedMealsResponseWrapper {
    pub saved_meals: SavedMealsResponse,
}

#[derive(Debug, Deserialize)]
pub struct SavedMealItemsResponseWrapper {
    pub saved_meal_items: SavedMealItemsResponse,
}
