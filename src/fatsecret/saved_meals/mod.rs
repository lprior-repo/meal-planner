//! FatSecret Saved Meals API - Core Types
//!
//! Opaque types for type-safe IDs and domain types for saved meals and items.
//! These types mirror the FatSecret API structure for saved meal templates.

use serde::{Deserialize, Serialize};
use std::fmt;

// ============================================================================
// Opaque ID Types
// ============================================================================

/// Opaque type for saved meal IDs (from FatSecret)
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct SavedMealId(String);

impl SavedMealId {
    /// Create a SavedMealId from a string
    pub fn new(id: impl Into<String>) -> Self {
        SavedMealId(id.into())
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

impl fmt::Display for SavedMealId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl From<String> for SavedMealId {
    fn from(s: String) -> Self {
        SavedMealId(s)
    }
}

impl From<&str> for SavedMealId {
    fn from(s: &str) -> Self {
        SavedMealId(s.to_string())
    }
}

/// Opaque type for saved meal item IDs (from FatSecret)
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct SavedMealItemId(String);

impl SavedMealItemId {
    /// Create a SavedMealItemId from a string
    pub fn new(id: impl Into<String>) -> Self {
        SavedMealItemId(id.into())
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

impl fmt::Display for SavedMealItemId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl From<String> for SavedMealItemId {
    fn from(s: String) -> Self {
        SavedMealItemId(s)
    }
}

impl From<&str> for SavedMealItemId {
    fn from(s: &str) -> Self {
        SavedMealItemId(s.to_string())
    }
}

// ============================================================================
// Meal Type Enum
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
    /// Snacks or other meals
    Other,
}

impl MealType {
    /// Convert meal type to API string format
    pub fn as_api_str(&self) -> &'static str {
        match self {
            MealType::Breakfast => "breakfast",
            MealType::Lunch => "lunch",
            MealType::Dinner => "dinner",
            MealType::Other => "other",
        }
    }

    /// Parse meal type from API string
    pub fn from_api_str(s: &str) -> Option<Self> {
        match s {
            "breakfast" => Some(MealType::Breakfast),
            "lunch" => Some(MealType::Lunch),
            "dinner" => Some(MealType::Dinner),
            "other" => Some(MealType::Other),
            _ => None,
        }
    }
}

// ============================================================================
// Saved Meal Types
// ============================================================================

/// A saved meal template (collection of food items)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SavedMeal {
    /// Unique saved meal identifier
    pub saved_meal_id: SavedMealId,
    /// Name of the saved meal
    pub saved_meal_name: String,
    /// Optional description
    pub saved_meal_description: Option<String>,
    /// Meal types this saved meal can be used for
    pub meals: Vec<MealType>,
    /// Total calories in the saved meal
    pub calories: f64,
    /// Total carbohydrates (g)
    pub carbohydrate: f64,
    /// Total protein (g)
    pub protein: f64,
    /// Total fat (g)
    pub fat: f64,
}

/// A food item within a saved meal
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SavedMealItem {
    /// Unique item identifier within the saved meal
    pub saved_meal_item_id: SavedMealItemId,
    /// FatSecret food ID
    pub food_id: String,
    /// Display name for the food entry
    pub food_entry_name: String,
    /// Serving ID
    pub serving_id: String,
    /// Number of units of the serving
    pub number_of_units: f64,
    /// Calories for this item
    pub calories: f64,
    /// Carbohydrates (g) for this item
    pub carbohydrate: f64,
    /// Protein (g) for this item
    pub protein: f64,
    /// Fat (g) for this item
    pub fat: f64,
}

// ============================================================================
// Input Types
// ============================================================================

/// Input for creating/editing saved meal items
/// Can either reference an existing food or provide custom nutrition
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum SavedMealItemInput {
    /// Reference an existing FatSecret food by ID and serving
    #[serde(rename = "by_food_id")]
    ByFoodId {
        /// FatSecret food ID
        food_id: String,
        /// Serving ID
        serving_id: String,
        /// Number of units
        number_of_units: f64,
    },
    /// Create custom entry with nutrition values
    #[serde(rename = "by_nutrition")]
    ByNutrition {
        /// Display name for the food entry
        food_entry_name: String,
        /// Serving description (e.g., "1 serving", "100g")
        serving_description: String,
        /// Number of units
        number_of_units: f64,
        /// Calories
        calories: f64,
        /// Carbohydrates (g)
        carbohydrate: f64,
        /// Protein (g)
        protein: f64,
        /// Fat (g)
        fat: f64,
    },
}

// ============================================================================
// Response Types
// ============================================================================

/// Response from saved_meals.get.v2 API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SavedMealsResponse {
    /// List of saved meals
    pub saved_meals: Vec<SavedMeal>,
    /// Meal type filter that was applied (if any)
    pub meal_filter: Option<String>,
}

/// Response from saved_meal_items.get.v2 API
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SavedMealItemsResponse {
    /// ID of the saved meal these items belong to
    pub saved_meal_id: SavedMealId,
    /// Items in the saved meal
    pub items: Vec<SavedMealItem>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_saved_meal_id_creation() {
        let id = SavedMealId::new("meal_123");
        assert_eq!(id.as_str(), "meal_123");
        assert_eq!(id.to_string(), "meal_123");
    }

    #[test]
    fn test_saved_meal_item_id_creation() {
        let id = SavedMealItemId::new("item_456");
        assert_eq!(id.as_str(), "item_456");
    }

    #[test]
    fn test_meal_type_conversion() {
        assert_eq!(MealType::Breakfast.as_api_str(), "breakfast");
        assert_eq!(MealType::from_api_str("lunch"), Some(MealType::Lunch));
        assert_eq!(MealType::from_api_str("invalid"), None);
    }

    #[test]
    fn test_saved_meal_serialization() {
        let meal = SavedMeal {
            saved_meal_id: SavedMealId::new("1"),
            saved_meal_name: "Quick Breakfast".to_string(),
            saved_meal_description: Some("My go-to breakfast".to_string()),
            meals: vec![MealType::Breakfast],
            calories: 450.0,
            carbohydrate: 50.0,
            protein: 25.0,
            fat: 15.0,
        };

        let json = serde_json::to_string(&meal).unwrap();
        let deserialized: SavedMeal = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.saved_meal_name, "Quick Breakfast");
    }

    #[test]
    fn test_saved_meal_item_input_by_food_id() {
        let input = SavedMealItemInput::ByFoodId {
            food_id: "123".to_string(),
            serving_id: "456".to_string(),
            number_of_units: 1.5,
        };

        let json = serde_json::to_string(&input).unwrap();
        assert!(json.contains("by_food_id"));
    }

    #[test]
    fn test_saved_meal_item_input_by_nutrition() {
        let input = SavedMealItemInput::ByNutrition {
            food_entry_name: "Custom Food".to_string(),
            serving_description: "1 serving".to_string(),
            number_of_units: 1.0,
            calories: 200.0,
            carbohydrate: 25.0,
            protein: 10.0,
            fat: 8.0,
        };

        let json = serde_json::to_string(&input).unwrap();
        assert!(json.contains("by_nutrition"));
    }
}
