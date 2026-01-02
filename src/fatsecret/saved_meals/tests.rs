//! Unit tests for the `FatSecret` Saved Meals domain

#![allow(clippy::unwrap_used)]
#![allow(clippy::expect_used)]
#![allow(clippy::panic)]

use super::types::*;
use serde_json;

// =============================================================================
// SavedMealId Tests
// =============================================================================

#[test]
fn test_saved_meal_id_new() {
    let id = SavedMealId::new("12345");
    assert_eq!(id.as_str(), "12345");
}

#[test]
fn test_saved_meal_id_from_string() {
    let id = SavedMealId::new(String::from("67890"));
    assert_eq!(id.as_str(), "67890");
}

#[test]
fn test_saved_meal_id_serialize() {
    let id = SavedMealId::new("12345");
    let json = serde_json::to_string(&id).expect("should serialize");
    assert_eq!(json, r#""12345""#);
}

#[test]
fn test_saved_meal_id_deserialize() {
    let json = r#""12345""#;
    let id: SavedMealId = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(id.as_str(), "12345");
}

#[test]
fn test_saved_meal_id_display() {
    let id = SavedMealId::new("12345");
    let display = format!("{}", id);
    assert_eq!(display, "12345");
}

#[test]
fn test_saved_meal_id_equality() {
    let id1 = SavedMealId::new("12345");
    let id2 = SavedMealId::new("12345");
    let id3 = SavedMealId::new("67890");
    assert_eq!(id1, id2);
    assert_ne!(id1, id3);
}

// =============================================================================
// SavedMealItemId Tests
// =============================================================================

#[test]
fn test_saved_meal_item_id_new() {
    let id = SavedMealItemId::new("11111");
    assert_eq!(id.as_str(), "11111");
}

#[test]
fn test_saved_meal_item_id_serialize() {
    let id = SavedMealItemId::new("11111");
    let json = serde_json::to_string(&id).expect("should serialize");
    assert_eq!(json, r#""11111""#);
}

#[test]
fn test_saved_meal_item_id_deserialize() {
    let json = r#""11111""#;
    let id: SavedMealItemId = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(id.as_str(), "11111");
}

// =============================================================================
// SavedMealType Tests
// =============================================================================

#[test]
fn test_saved_meal_type_to_api_string() {
    assert_eq!(MealType::Breakfast.to_api_string(), "breakfast");
    assert_eq!(MealType::Lunch.to_api_string(), "lunch");
    assert_eq!(MealType::Dinner.to_api_string(), "dinner");
    assert_eq!(MealType::Snack.to_api_string(), "other");
}

#[test]
fn test_saved_meal_type_from_api_string() {
    assert_eq!(MealType::from_api_string("breakfast"), Some(MealType::Breakfast));
    assert_eq!(MealType::from_api_string("lunch"), Some(MealType::Lunch));
    assert_eq!(MealType::from_api_string("dinner"), Some(MealType::Dinner));
    assert_eq!(MealType::from_api_string("other"), Some(MealType::Snack));
    assert_eq!(MealType::from_api_string("snack"), Some(MealType::Snack));
}

#[test]
fn test_saved_meal_type_roundtrip() {
    for meal in [MealType::Breakfast, MealType::Lunch, MealType::Dinner, MealType::Snack] {
        let s = meal.to_api_string();
        let parsed = MealType::from_api_string(s).unwrap();
        assert_eq!(meal, parsed);
    }
}

// =============================================================================
// SavedMeal Tests
// =============================================================================

#[test]
fn test_saved_meal_deserialize() {
    let json = r#"{
        "saved_meal": {
            "saved_meal_id": "123",
            "saved_meal_name": "My Breakfast",
            "saved_meal_type": "breakfast",
            "saved_meal_items": {
                "saved_meal_item": [
                    {
                        "saved_meal_item_id": "456",
                        "food_id": "789",
                        "food_name": "Oatmeal",
                        "serving_id": "111",
                        "number_of_units": "1.0",
                        "meal_type": "breakfast"
                    }
                ]
            }
        }
    }"#;
    let response: SavedMealsResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.meals.len(), 1);
    let meal = &response.meals[0];
    assert_eq!(meal.saved_meal_id.as_str(), "123");
    assert_eq!(meal.saved_meal_name, "My Breakfast");
    assert_eq!(meal.meal_type, MealType::Breakfast);
}

#[test]
fn test_saved_meal_multiple_items() {
    let json = r#"{
        "saved_meal": {
            "saved_meal_id": "123",
            "saved_meal_name": "Full Lunch",
            "saved_meal_type": "lunch",
            "saved_meal_items": {
                "saved_meal_item": [
                    {
                        "saved_meal_item_id": "1",
                        "food_id": "f1",
                        "food_name": "Sandwich",
                        "serving_id": "s1",
                        "number_of_units": "1.0",
                        "meal_type": "lunch"
                    },
                    {
                        "saved_meal_item_id": "2",
                        "food_id": "f2",
                        "food_name": "Apple",
                        "serving_id": "s2",
                        "number_of_units": "1.0",
                        "meal_type": "lunch"
                    }
                ]
            }
        }
    }"#;
    let response: SavedMealsResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.meals.len(), 1);
    assert_eq!(response.meals[0].items.len(), 2);
}

#[test]
fn test_saved_meal_single_item() {
    let json = r#"{
        "saved_meal": {
            "saved_meal_id": "123",
            "saved_meal_name": "Quick Snack",
            "saved_meal_type": "snack",
            "saved_meal_items": {
                "saved_meal_item": {
                    "saved_meal_item_id": "456",
                    "food_id": "789",
                    "food_name": "Banana",
                    "serving_id": "111",
                    "number_of_units": "1.0",
                    "meal_type": "snack"
                }
            }
        }
    }"#;
    let response: SavedMealsResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.meals.len(), 1);
    assert_eq!(response.meals[0].items.len(), 1);
}

#[test]
fn test_saved_meal_array_response() {
    let json = r#"{
        "saved_meal": [
            {
                "saved_meal_id": "1",
                "saved_meal_name": "Breakfast",
                "saved_meal_type": "breakfast",
                "saved_meal_items": {"saved_meal_item": []}
            },
            {
                "saved_meal_id": "2",
                "saved_meal_name": "Lunch",
                "saved_meal_type": "lunch",
                "saved_meal_items": {"saved_meal_item": []}
            }
        ]
    }"#;
    let response: SavedMealsResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.meals.len(), 2);
}

// =============================================================================
// SavedMealItem Tests
// =============================================================================

#[test]
fn test_saved_meal_item_deserialize() {
    let json = r#"{
        "saved_meal_item_id": "456",
        "food_id": "789",
        "food_name": "Oatmeal",
        "serving_id": "111",
        "number_of_units": "2.0",
        "meal_type": "breakfast"
    }"#;
    let item: SavedMealItem = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(item.saved_meal_item_id.as_str(), "456");
    assert_eq!(item.food_name, "Oatmeal");
    assert!((item.number_of_units - 2.0).abs() < f64::EPSILON);
    assert_eq!(item.meal_type, MealType::Breakfast);
}

#[test]
fn test_saved_meal_item_numeric_units() {
    let json = r#"{
        "saved_meal_item_id": "1",
        "food_id": "f1",
        "food_name": "Test",
        "serving_id": "s1",
        "number_of_units": 1.5,
        "meal_type": "lunch"
    }"#;
    let item: SavedMealItem = serde_json::from_str(json).expect("should deserialize");
    assert!((item.number_of_units - 1.5).abs() < f64::EPSILON);
}

// =============================================================================
// SavedMealItemsResponse Tests
// =============================================================================

#[test]
fn test_saved_meal_items_response() {
    let json = r#"{
        "saved_meal_items": {
            "saved_meal_item": [
                {"saved_meal_item_id": "1", "food_id": "f1", "food_name": "A", "serving_id": "s1", "number_of_units": 1.0, "meal_type": "lunch"},
                {"saved_meal_item_id": "2", "food_id": "f2", "food_name": "B", "serving_id": "s2", "number_of_units": 1.0, "meal_type": "lunch"}
            ]
        }
    }"#;
    let response: SavedMealItemsResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.items.len(), 2);
}

#[test]
fn test_saved_meal_items_response_single() {
    let json = r#"{
        "saved_meal_items": {
            "saved_meal_item": {
                "saved_meal_item_id": "1",
                "food_id": "f1",
                "food_name": "Single",
                "serving_id": "s1",
                "number_of_units": 1.0,
                "meal_type": "lunch"
            }
        }
    }"#;
    let response: SavedMealItemsResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.items.len(), 1);
}

#[test]
fn test_saved_meal_items_response_empty() {
    let json = r#"{"saved_meal_items": {}}"#;
    let response: SavedMealItemsResponse = serde_json::from_str(json).expect("should deserialize");
    assert!(response.items.is_empty());
}

// =============================================================================
// SavedMealItemInput Tests
// =============================================================================

#[test]
fn test_saved_meal_item_input() {
    let input = SavedMealItemInput {
        food_id: "123".to_string(),
        serving_id: "456".to_string(),
        number_of_units: 2.0,
        meal_type: MealType::Dinner,
    };
    assert_eq!(input.food_id, "123");
    assert!((input.number_of_units - 2.0).abs() < f64::EPSILON);
    assert_eq!(input.meal_type, MealType::Dinner);
}

#[test]
fn test_saved_meal_item_input_serialize() {
    let input = SavedMealItemInput {
        food_id: "123".to_string(),
        serving_id: "456".to_string(),
        number_of_units: 1.5,
        meal_type: MealType::Breakfast,
    };
    let json = serde_json::to_string(&input).expect("should serialize");
    assert!(json.contains("123"));
    assert!(json.contains("1.5"));
}

#[test]
fn test_saved_meal_item_input_deserialize() {
    let json = r#"{
        "food_id": "999",
        "serving_id": "888",
        "number_of_units": 3.0,
        "meal_type": "snack"
    }"#;
    let input: SavedMealItemInput = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(input.food_id, "999");
    assert!((input.number_of_units - 3.0).abs() < f64::EPSILON);
    assert_eq!(input.meal_type, MealType::Snack);
}

// =============================================================================
// Clone and Debug Tests
// =============================================================================

#[test]
fn test_saved_meal_id_clone() {
    let id1 = SavedMealId::new("12345");
    let id2 = id1.clone();
    assert_eq!(id1, id2);
}

#[test]
fn test_saved_meal_clone() {
    let json = r#"{
        "saved_meal": {
            "saved_meal_id": "123",
            "saved_meal_name": "Test",
            "saved_meal_type": "lunch",
            "saved_meal_items": {"saved_meal_item": []}
        }
    }"#;
    let response: SavedMealsResponse = serde_json::from_str(json).expect("should deserialize");
    let cloned = response.meals[0].clone();
    assert_eq!(response.meals[0].saved_meal_id, cloned.saved_meal_id);
}

#[test]
fn test_saved_meal_item_clone() {
    let json = r#"{
        "saved_meal_item_id": "1",
        "food_id": "f1",
        "food_name": "Test",
        "serving_id": "s1",
        "number_of_units": 1.0,
        "meal_type": "lunch"
    }"#;
    let item: SavedMealItem = serde_json::from_str(json).expect("should deserialize");
    let cloned = item.clone();
    assert_eq!(item.saved_meal_item_id, cloned.saved_meal_item_id);
}

#[test]
fn test_saved_meal_id_debug_format() {
    let id = SavedMealId::new("12345");
    let debug = format!("{:?}", id);
    assert!(debug.contains("12345"));
}

// =============================================================================
// Edge Cases
// =============================================================================

#[test]
fn test_saved_meal_empty_items() {
    let json = r#"{
        "saved_meal": {
            "saved_meal_id": "123",
            "saved_meal_name": "Empty Meal",
            "saved_meal_type": "lunch",
            "saved_meal_items": {"saved_meal_item": []}
        }
    }"#;
    let response: SavedMealsResponse = serde_json::from_str(json).expect("should deserialize");
    assert!(response.meals[0].items.is_empty());
}

#[test]
fn test_saved_meal_meal_type_variants() {
    for (api_str, expected_type) in [
        ("breakfast", MealType::Breakfast),
        ("lunch", MealType::Lunch),
        ("dinner", MealType::Dinner),
        ("other", MealType::Snack),
    ] {
        let json = format!(
            r#"{{
            "saved_meal_id": "1",
            "saved_meal_name": "Test",
            "saved_meal_type": "{}",
            "saved_meal_items": {{"saved_meal_item": []}}
        }}"#,
            api_str
        );
        let response: SavedMealsResponse = serde_json::from_str(&json).expect("should deserialize");
        assert_eq!(response.meals[0].meal_type, expected_type);
    }
}

#[test]
fn test_saved_meal_item_decimal_units() {
    let json = r#"{
        "saved_meal_item_id": "1",
        "food_id": "f1",
        "food_name": "Test",
        "serving_id": "s1",
        "number_of_units": "0.25",
        "meal_type": "lunch"
    }"#;
    let item: SavedMealItem = serde_json::from_str(json).expect("should deserialize");
    assert!((item.number_of_units - 0.25).abs() < f64::EPSILON);
}

#[test]
fn test_saved_meals_response_empty() {
    let json = r#"{"saved_meal": []}"#;
    let response: SavedMealsResponse = serde_json::from_str(json).expect("should deserialize");
    assert!(response.meals.is_empty());
}

// =============================================================================
// Error Cases
// =============================================================================

#[test]
fn test_saved_meal_id_invalid_json() {
    let json = r#"not_a_string"#;
    let result: Result<SavedMealId, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

#[test]
fn test_saved_meal_missing_required_field() {
    let json = r#"{
        "saved_meal": {
            "saved_meal_name": "Test"
        }
    }"#;
    let result: Result<SavedMealsResponse, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

#[test]
fn test_saved_meal_item_missing_required_field() {
    let json = r#"{
        "saved_meal_item_id": "1",
        "food_name": "Test"
    }"#;
    let result: Result<SavedMealItem, _> = serde_json::from_str(json);
    assert!(result.is_err());
}
