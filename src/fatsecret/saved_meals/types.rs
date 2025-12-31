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

#[cfg(test)]
mod tests {
    use super::*;

    // ============================================================================
    // SavedMealId tests
    // ============================================================================

    #[test]
    fn test_saved_meal_id_new() {
        let id = SavedMealId::new("12345");
        assert_eq!(id.as_str(), "12345");
    }

    #[test]
    fn test_saved_meal_id_from_string() {
        let id: SavedMealId = String::from("67890").into();
        assert_eq!(id.as_str(), "67890");
    }

    #[test]
    fn test_saved_meal_id_from_str() {
        let id: SavedMealId = "abc123".into();
        assert_eq!(id.as_str(), "abc123");
    }

    #[test]
    fn test_saved_meal_id_display() {
        let id = SavedMealId::new("meal-id");
        assert_eq!(format!("{}", id), "meal-id");
    }

    #[test]
    fn test_saved_meal_id_equality() {
        let id1 = SavedMealId::new("same");
        let id2 = SavedMealId::new("same");
        let id3 = SavedMealId::new("different");
        assert_eq!(id1, id2);
        assert_ne!(id1, id3);
    }

    #[test]
    fn test_saved_meal_id_hash() {
        use std::collections::HashSet;
        let mut set = HashSet::new();
        set.insert(SavedMealId::new("id1"));
        set.insert(SavedMealId::new("id2"));
        set.insert(SavedMealId::new("id1")); // duplicate
        assert_eq!(set.len(), 2);
    }

    #[test]
    fn test_saved_meal_id_serde() {
        let id = SavedMealId::new("serde-test");
        let json = serde_json::to_string(&id).unwrap();
        assert_eq!(json, "\"serde-test\"");
        let parsed: SavedMealId = serde_json::from_str(&json).unwrap();
        assert_eq!(id, parsed);
    }

    // ============================================================================
    // SavedMealItemId tests
    // ============================================================================

    #[test]
    fn test_saved_meal_item_id_new() {
        let id = SavedMealItemId::new("item123");
        assert_eq!(id.as_str(), "item123");
    }

    #[test]
    fn test_saved_meal_item_id_equality() {
        let id1 = SavedMealItemId::new("same");
        let id2 = SavedMealItemId::new("same");
        assert_eq!(id1, id2);
    }

    // ============================================================================
    // MealType tests
    // ============================================================================

    #[test]
    fn test_meal_type_breakfast_api_string() {
        assert_eq!(MealType::Breakfast.to_api_string(), "breakfast");
    }

    #[test]
    fn test_meal_type_lunch_api_string() {
        assert_eq!(MealType::Lunch.to_api_string(), "lunch");
    }

    #[test]
    fn test_meal_type_dinner_api_string() {
        assert_eq!(MealType::Dinner.to_api_string(), "dinner");
    }

    #[test]
    fn test_meal_type_snack_api_string() {
        assert_eq!(MealType::Snack.to_api_string(), "other");
    }

    #[test]
    fn test_meal_type_serde_roundtrip() {
        let types = vec![
            MealType::Breakfast,
            MealType::Lunch,
            MealType::Dinner,
            MealType::Snack,
        ];
        for meal_type in types {
            let json = serde_json::to_string(&meal_type).unwrap();
            let parsed: MealType = serde_json::from_str(&json).unwrap();
            assert_eq!(meal_type, parsed);
        }
    }

    #[test]
    fn test_meal_type_deserialize_other_as_snack() {
        let json = r#""other""#;
        let meal_type: MealType = serde_json::from_str(json).unwrap();
        assert_eq!(meal_type, MealType::Snack);
    }

    // ============================================================================
    // SavedMeal tests
    // ============================================================================

    #[test]
    fn test_saved_meal_deserialize() {
        let json = r#"{
            "saved_meal_id": "12345",
            "saved_meal_name": "My Breakfast",
            "meals": "breakfast",
            "calories": "350",
            "carbohydrate": "45.5",
            "protein": "12",
            "fat": "10"
        }"#;
        let meal: SavedMeal = serde_json::from_str(json).unwrap();
        assert_eq!(meal.saved_meal_id.as_str(), "12345");
        assert_eq!(meal.saved_meal_name, "My Breakfast");
        assert_eq!(meal.meals, vec![MealType::Breakfast]);
        assert!((meal.calories - 350.0).abs() < 0.01);
        assert!(meal.saved_meal_description.is_none());
    }

    #[test]
    fn test_saved_meal_multiple_meal_types() {
        let json = r#"{
            "saved_meal_id": "67890",
            "saved_meal_name": "Flexible Meal",
            "meals": "breakfast,lunch,dinner",
            "calories": "500",
            "carbohydrate": "60",
            "protein": "30",
            "fat": "15"
        }"#;
        let meal: SavedMeal = serde_json::from_str(json).unwrap();
        assert_eq!(meal.meals.len(), 3);
        assert!(meal.meals.contains(&MealType::Breakfast));
        assert!(meal.meals.contains(&MealType::Lunch));
        assert!(meal.meals.contains(&MealType::Dinner));
    }

    #[test]
    fn test_saved_meal_with_description() {
        let json = r#"{
            "saved_meal_id": "123",
            "saved_meal_name": "Healthy Start",
            "saved_meal_description": "A nutritious breakfast to start the day",
            "meals": "breakfast",
            "calories": "400",
            "carbohydrate": "50",
            "protein": "20",
            "fat": "12"
        }"#;
        let meal: SavedMeal = serde_json::from_str(json).unwrap();
        assert_eq!(
            meal.saved_meal_description,
            Some("A nutritious breakfast to start the day".to_string())
        );
    }

    #[test]
    fn test_saved_meal_snack_meal_type() {
        let json = r#"{
            "saved_meal_id": "999",
            "saved_meal_name": "Afternoon Snack",
            "meals": "other",
            "calories": "150",
            "carbohydrate": "20",
            "protein": "5",
            "fat": "5"
        }"#;
        let meal: SavedMeal = serde_json::from_str(json).unwrap();
        assert_eq!(meal.meals, vec![MealType::Snack]);
    }

    #[test]
    fn test_saved_meal_snack_alias() {
        let json = r#"{
            "saved_meal_id": "999",
            "saved_meal_name": "Snack",
            "meals": "snack",
            "calories": "100",
            "carbohydrate": "15",
            "protein": "3",
            "fat": "3"
        }"#;
        let meal: SavedMeal = serde_json::from_str(json).unwrap();
        assert_eq!(meal.meals, vec![MealType::Snack]);
    }

    // ============================================================================
    // SavedMealItem tests
    // ============================================================================

    #[test]
    fn test_saved_meal_item_deserialize() {
        let json = r#"{
            "saved_meal_item_id": "item1",
            "food_id": "12345",
            "food_entry_name": "Oatmeal",
            "serving_id": "789",
            "number_of_units": "1.5",
            "calories": "150",
            "carbohydrate": "27",
            "protein": "5",
            "fat": "3"
        }"#;
        let item: SavedMealItem = serde_json::from_str(json).unwrap();
        assert_eq!(item.saved_meal_item_id.as_str(), "item1");
        assert_eq!(item.food_id, "12345");
        assert_eq!(item.food_entry_name, "Oatmeal");
        assert!((item.number_of_units - 1.5).abs() < 0.01);
        assert!((item.calories - 150.0).abs() < 0.01);
    }

    #[test]
    fn test_saved_meal_item_numeric_values() {
        let json = r#"{
            "saved_meal_item_id": "item2",
            "food_id": "456",
            "food_entry_name": "Eggs",
            "serving_id": "111",
            "number_of_units": 2.0,
            "calories": 140,
            "carbohydrate": 1,
            "protein": 12,
            "fat": 10
        }"#;
        let item: SavedMealItem = serde_json::from_str(json).unwrap();
        assert!((item.number_of_units - 2.0).abs() < 0.01);
        assert!((item.calories - 140.0).abs() < 0.01);
    }

    // ============================================================================
    // SavedMealItemInput tests
    // ============================================================================

    #[test]
    fn test_saved_meal_item_input_by_food_id() {
        let input = SavedMealItemInput::ByFoodId {
            food_id: "12345".to_string(),
            serving_id: "789".to_string(),
            number_of_units: 1.5,
        };
        let json = serde_json::to_string(&input).unwrap();
        assert!(json.contains("by_food_id"));
        assert!(json.contains("12345"));
    }

    #[test]
    fn test_saved_meal_item_input_by_nutrition() {
        let input = SavedMealItemInput::ByNutrition {
            food_entry_name: "Custom Food".to_string(),
            serving_description: "1 cup".to_string(),
            number_of_units: 2.0,
            calories: 200.0,
            carbohydrate: 25.0,
            protein: 10.0,
            fat: 8.0,
        };
        let json = serde_json::to_string(&input).unwrap();
        assert!(json.contains("by_nutrition"));
        assert!(json.contains("Custom Food"));
    }

    #[test]
    fn test_saved_meal_item_input_roundtrip() {
        let input = SavedMealItemInput::ByFoodId {
            food_id: "abc".to_string(),
            serving_id: "def".to_string(),
            number_of_units: 3.0,
        };
        let json = serde_json::to_string(&input).unwrap();
        let parsed: SavedMealItemInput = serde_json::from_str(&json).unwrap();
        if let SavedMealItemInput::ByFoodId {
            food_id,
            serving_id,
            number_of_units,
        } = parsed
        {
            assert_eq!(food_id, "abc");
            assert_eq!(serving_id, "def");
            assert!((number_of_units - 3.0).abs() < 0.01);
        } else {
            panic!("Expected ByFoodId variant");
        }
    }

    // ============================================================================
    // Response wrapper tests
    // ============================================================================

    #[test]
    fn test_saved_meals_response_single() {
        let json = r#"{
            "saved_meal": {
                "saved_meal_id": "1",
                "saved_meal_name": "Lunch",
                "meals": "lunch",
                "calories": "400",
                "carbohydrate": "50",
                "protein": "20",
                "fat": "15"
            }
        }"#;
        let response: SavedMealsResponse = serde_json::from_str(json).unwrap();
        assert_eq!(response.saved_meals.len(), 1);
    }

    #[test]
    fn test_saved_meals_response_multiple() {
        let json = r#"{
            "saved_meal": [
                {
                    "saved_meal_id": "1",
                    "saved_meal_name": "Meal 1",
                    "meals": "breakfast",
                    "calories": "300",
                    "carbohydrate": "40",
                    "protein": "15",
                    "fat": "10"
                },
                {
                    "saved_meal_id": "2",
                    "saved_meal_name": "Meal 2",
                    "meals": "lunch",
                    "calories": "500",
                    "carbohydrate": "60",
                    "protein": "25",
                    "fat": "18"
                }
            ]
        }"#;
        let response: SavedMealsResponse = serde_json::from_str(json).unwrap();
        assert_eq!(response.saved_meals.len(), 2);
    }

    #[test]
    fn test_saved_meals_response_empty() {
        let json = r#"{}"#;
        let response: SavedMealsResponse = serde_json::from_str(json).unwrap();
        assert!(response.saved_meals.is_empty());
    }

    #[test]
    fn test_saved_meals_response_with_filter() {
        let json = r#"{
            "saved_meal": [],
            "meal_filter": "breakfast"
        }"#;
        let response: SavedMealsResponse = serde_json::from_str(json).unwrap();
        assert_eq!(response.meal_filter, Some("breakfast".to_string()));
    }

    #[test]
    fn test_saved_meal_items_response() {
        let json = r#"{
            "saved_meal_id": "meal123",
            "item": [
                {
                    "saved_meal_item_id": "item1",
                    "food_id": "food1",
                    "food_entry_name": "Item 1",
                    "serving_id": "srv1",
                    "number_of_units": "1",
                    "calories": "100",
                    "carbohydrate": "15",
                    "protein": "5",
                    "fat": "3"
                }
            ]
        }"#;
        let response: SavedMealItemsResponse = serde_json::from_str(json).unwrap();
        assert_eq!(response.saved_meal_id.as_str(), "meal123");
        assert_eq!(response.items.len(), 1);
    }

    #[test]
    fn test_saved_meals_response_wrapper() {
        let json = r#"{
            "saved_meals": {
                "saved_meal": []
            }
        }"#;
        let wrapper: SavedMealsResponseWrapper = serde_json::from_str(json).unwrap();
        assert!(wrapper.saved_meals.saved_meals.is_empty());
    }

    #[test]
    fn test_saved_meal_items_response_wrapper() {
        let json = r#"{
            "saved_meal_items": {
                "saved_meal_id": "meal1",
                "item": []
            }
        }"#;
        let wrapper: SavedMealItemsResponseWrapper = serde_json::from_str(json).unwrap();
        assert_eq!(wrapper.saved_meal_items.saved_meal_id.as_str(), "meal1");
    }
}
