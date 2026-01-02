#![allow(clippy::unwrap_used)]

use meal_planner::fatsecret::foods::types::Food;
use std::fs;

#[allow(clippy::panic)]
fn load_fixture(name: &str) -> String {
    fs::read_to_string(format!("tests/fixtures/foods/{}.json", name))
        .unwrap_or_else(|e| panic!("Failed to load fixture {}: {}", name, e))
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing)]
fn test_deserialize_food_complete() {
    let json = load_fixture("food_complete");
    let result: serde_json::Result<serde_json::Value> = serde_json::from_str(&json);
    assert!(result.is_ok(), "Failed to parse JSON: {:?}", result.err());

    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize complete food");

    assert_eq!(food.food_id.as_str(), "12345");
    assert_eq!(food.food_name, "Chicken Breast");
    assert_eq!(food.food_type, "Generic");
    assert!(food.brand_name.is_none());
    assert_eq!(food.servings.serving.len(), 2);
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing)]
fn test_deserialize_food_branded() {
    let json = load_fixture("food_branded");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize branded food");

    assert_eq!(food.food_id.as_str(), "98765");
    assert_eq!(food.food_name, "Greek Yogurt");
    assert_eq!(food.brand_name, Some("Fage".to_string()));
    assert_eq!(food.food_type, "Brand");
    assert_eq!(food.servings.serving.len(), 1);
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing)]
fn test_deserialize_food_minimal() {
    let json = load_fixture("food_minimal");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize minimal food");

    assert_eq!(food.food_id.as_str(), "55555");
    assert_eq!(food.food_name, "Apple");
    assert_eq!(food.servings.serving.len(), 1);

    let serving = &food.servings.serving[0];
    assert_eq!(serving.serving_id.as_str(), "22222");
    assert!(serving.nutrition.saturated_fat.is_none());
    assert!(serving.nutrition.fiber.is_none());
    assert!(serving.nutrition.cholesterol.is_none());
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing)]
fn test_serialize_food_roundtrip() {
    let json = load_fixture("food_complete");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize food");

    let serialized = serde_json::to_string(&food).expect("Failed to serialize");
    let deserialized: Food = serde_json::from_str(&serialized).expect("Failed to deserialize");

    assert_eq!(food.food_id, deserialized.food_id);
    assert_eq!(food.food_name, deserialized.food_name);
    assert_eq!(food.servings.serving.len(), deserialized.servings.serving.len());
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing, clippy::unwrap_used)]
fn test_deserialize_missing_required_field() {
    let invalid_json = r#"{
        "food": {
            "food_id": "12345",
            "food_name": "Test Food",
            "food_type": "Generic",
            "food_url": "http://example.com",
            "servings": {
                "serving": {
                    "serving_id": "67890",
                    "serving_description": "1 cup",
                    "serving_url": "http://example.com",
                    "number_of_units": "1.0",
                    "measurement_description": "cup",
                    "protein": "10.0",
                    "carbohydrate": "20.0",
                    "fat": "5.0"
                }
            }
        }
    }"#;

    let result: Result<serde_json::Value, _> = serde_json::from_str(invalid_json);
    assert!(result.is_ok());

    let value = result.unwrap();
    let food_result: Result<Food, _> = serde_json::from_value(value["food"].clone());
    assert!(food_result.is_err(), "Should fail when missing required calories field");
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing, clippy::unwrap_used)]
fn test_deserialize_invalid_number_format() {
    let invalid_json = r#"{
        "food": {
            "food_id": "12345",
            "food_name": "Test Food",
            "food_type": "Generic",
            "food_url": "http://example.com",
            "servings": {
                "serving": {
                    "serving_id": "67890",
                    "serving_description": "1 cup",
                    "serving_url": "http://example.com",
                    "number_of_units": "1.0",
                    "measurement_description": "cup",
                    "calories": "not-a-number",
                    "protein": "10.0",
                    "carbohydrate": "20.0",
                    "fat": "5.0"
                }
            }
        }
    }"#;

    let result: Result<serde_json::Value, _> = serde_json::from_str(invalid_json);
    assert!(result.is_ok());

    let value = result.unwrap();
    let food_result: Result<Food, _> = serde_json::from_value(value["food"].clone());
    assert!(food_result.is_err(), "Should fail with invalid number format");
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing, clippy::unwrap_used)]
fn test_deserialize_empty_string_as_zero() {
    let json = r#"{
        "food": {
            "food_id": "12345",
            "food_name": "Test Food",
            "food_type": "Generic",
            "food_url": "http://example.com",
            "servings": {
                "serving": {
                    "serving_id": "67890",
                    "serving_description": "1 cup",
                    "serving_url": "http://example.com",
                    "number_of_units": "0",
                    "measurement_description": "cup",
                    "calories": "100",
                    "protein": "10.0",
                    "carbohydrate": "0",
                    "fat": "5.0"
                }
            }
        }
    }"#;

    let value: serde_json::Value = serde_json::from_str(json).unwrap();
    let food: Food = serde_json::from_value(value["food"].clone()).expect("Should handle zero values");

    let serving = &food.servings.serving[0];
    assert!((serving.number_of_units - 0.0).abs() < f64::EPSILON);
    assert!((serving.nutrition.carbohydrate - 0.0).abs() < f64::EPSILON);
}
