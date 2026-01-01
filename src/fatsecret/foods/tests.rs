//! Unit tests for the `FatSecret` Foods domain
//!
//! Test coverage:
//! - Opaque ID types (FoodId, ServingId)
//! - Nutrition deserialization (required and optional fields)
//! - Serving and Food type deserialization
//! - Search response pagination
//! - Autocomplete response handling
//! - Flexible number parsing (strings vs numbers)
//! - Single-or-vec deserialization patterns
//!
//! # TDD Principles Applied (Kent Beck Style)
//!
//! - **Parameterized tests**: Using rstest for table-driven tests
//! - **Pretty assertions**: Better diff output for failures
//! - **Test builders**: Fluent API for test data construction
//! - **Focused assertions**: One concept per test

#![allow(clippy::unwrap_used)]
#![allow(clippy::expect_used)]
#![allow(clippy::panic)]

use super::types::*;
use pretty_assertions::assert_eq;
use rstest::rstest;
use serde_json;

// =============================================================================
// Test Fixtures
// =============================================================================

mod fixtures {
    pub const FOOD_FULL_RESPONSE: &str = r#"{
        "food": {
            "food_id": "12345",
            "food_name": "Chicken Breast",
            "food_type": "Generic",
            "food_url": "https://www.fatsecret.com/calories-nutrition/generic/chicken-breast",
            "servings": {
                "serving": {
                    "serving_id": "67890",
                    "serving_description": "100g",
                    "serving_url": "https://www.fatsecret.com/serving/67890",
                    "metric_serving_amount": "100.0",
                    "metric_serving_unit": "g",
                    "number_of_units": "1.0",
                    "measurement_description": "gram",
                    "is_default": "1",
                    "calories": "165.0",
                    "carbohydrate": "0.0",
                    "protein": "31.0",
                    "fat": "3.6",
                    "saturated_fat": "1.0",
                    "fiber": "0.0",
                    "sugar": "0.0"
                }
            }
        }
    }"#;

    pub const FOOD_BRAND_RESPONSE: &str = r#"{
        "food": {
            "food_id": "99999",
            "food_name": "Kellogg's Corn Flakes",
            "food_type": "Brand",
            "food_url": "https://www.fatsecret.com/kellcornfl",
            "brand_name": "Kellogg's",
            "servings": {
                "serving": [
                    {
                        "serving_id": "11111",
                        "serving_description": "1 cup (30g)",
                        "serving_url": "https://www.fatsecret.com/serving/11111",
                        "metric_serving_amount": "30.0",
                        "metric_serving_unit": "g",
                        "number_of_units": "1.0",
                        "measurement_description": "cup",
                        "is_default": "1",
                        "calories": 100.0,
                        "carbohydrate": 24.0,
                        "protein": 2.0,
                        "fat": 0.5
                    },
                    {
                        "serving_id": "22222",
                        "serving_description": "100g",
                        "serving_url": "https://www.fatsecret.com/serving/22222",
                        "metric_serving_amount": "100.0",
                        "metric_serving_unit": "g",
                        "number_of_units": "1.0",
                        "measurement_description": "gram",
                        "calories": 333.0,
                        "carbohydrate": 80.0,
                        "protein": 7.0,
                        "fat": 1.5
                    }
                ]
            }
        }
    }"#;

    pub const FOOD_MINIMAL_NUTRITION: &str = r#"{
        "food": {
            "food_id": "55555",
            "food_name": "Minimal Food",
            "food_type": "Generic",
            "food_url": "https://example.com",
            "servings": {
                "serving": {
                    "serving_id": "66666",
                    "serving_description": "1 serving",
                    "serving_url": "https://example.com/serving",
                    "metric_serving_amount": 50.0,
                    "metric_serving_unit": "g",
                    "number_of_units": 1.0,
                    "measurement_description": "serving",
                    "calories": 100,
                    "carbohydrate": 10,
                    "protein": 5,
                    "fat": 2
                }
            }
        }
    }"#;

    pub const SEARCH_RESPONSE: &str = r#"{
        "foods": {
            "food": [
                {
                    "food_id": "111",
                    "food_name": "Apple",
                    "food_type": "Generic",
                    "food_description": "1 medium (180g)",
                    "food_url": "https://www.fatsecret.com/apple"
                },
                {
                    "food_id": "222",
                    "food_name": "Banana",
                    "food_type": "Generic",
                    "food_description": "1 medium (118g)",
                    "food_url": "https://www.fatsecret.com/banana"
                }
            ],
            "max_results": "20",
            "total_results": "100",
            "page_number": "0"
        }
    }"#;

    pub const SEARCH_RESPONSE_SINGLE: &str = r#"{
        "foods": {
            "food": {
                "food_id": "111",
                "food_name": "Apple",
                "food_type": "Generic",
                "food_description": "1 medium (180g)",
                "food_url": "https://www.fatsecret.com/apple"
            },
            "max_results": 20,
            "total_results": 1,
            "page_number": 0
        }
    }"#;

    pub const AUTOCOMPLETE_RESPONSE: &str = r#"{
        "suggestions": {
            "suggestion": [
                {"food_id": "123", "food_name": "Banana"},
                {"food_id": "456", "food_name": "Banana Bread"},
                {"food_id": "789", "food_name": "Banana Split"}
            ]
        }
    }"#;

    pub const AUTOCOMPLETE_SINGLE: &str = r#"{
        "suggestions": {
            "suggestion": {"food_id": "123", "food_name": "Banana"}
        }
    }"#;

    pub const FOOD_MICRONUTRIENTS: &str = r#"{
        "food": {
            "food_id": "77777",
            "food_name": "Full Nutrition Food",
            "food_type": "Generic",
            "food_url": "https://example.com",
            "servings": {
                "serving": {
                    "serving_id": "88888",
                    "serving_description": "100g",
                    "serving_url": "https://example.com/serving",
                    "metric_serving_amount": 100.0,
                    "metric_serving_unit": "g",
                    "number_of_units": 1.0,
                    "measurement_description": "gram",
                    "calories": 200.0,
                    "carbohydrate": 25.0,
                    "protein": 20.0,
                    "fat": 8.0,
                    "saturated_fat": 2.0,
                    "polyunsaturated_fat": 3.0,
                    "monounsaturated_fat": 2.5,
                    "trans_fat": 0.1,
                    "cholesterol": 50.0,
                    "sodium": 400.0,
                    "potassium": 300.0,
                    "fiber": 5.0,
                    "sugar": 10.0,
                    "added_sugars": 5.0,
                    "vitamin_a": 10.0,
                    "vitamin_c": 50.0,
                    "vitamin_d": 25.0,
                    "calcium": 15.0,
                    "iron": 8.0
                }
            }
        }
    }"#;
}

// =============================================================================
// Opaque ID Type Tests
// =============================================================================

#[test]
fn test_food_id_new() {
    let id = FoodId::new("12345");
    assert_eq!(id.as_str(), "12345");
}

#[test]
fn test_food_id_from_string() {
    let id = FoodId::new(String::from("12345"));
    assert_eq!(id.as_str(), "12345");
}

#[test]
fn test_food_id_from_str() {
    let id = FoodId::from("12345");
    assert_eq!(id.as_str(), "12345");
}

#[test]
fn test_food_id_serialize() {
    let id = FoodId::new("12345");
    let json = serde_json::to_string(&id).expect("should serialize");
    assert_eq!(json, r#""12345""#);
}

#[test]
fn test_food_id_deserialize() {
    let json = r#""12345""#;
    let id: FoodId = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(id.as_str(), "12345");
}

#[test]
fn test_food_id_display() {
    let id = FoodId::new("12345");
    let display = format!("{}", id);
    assert_eq!(display, "12345");
}

#[test]
fn test_food_id_equality() {
    let id1 = FoodId::new("12345");
    let id2 = FoodId::new("12345");
    let id3 = FoodId::new("67890");
    assert_eq!(id1, id2);
    assert_ne!(id1, id3);
}

#[test]
fn test_serving_id_new() {
    let id = ServingId::new("67890");
    assert_eq!(id.as_str(), "67890");
}

#[test]
fn test_serving_id_serialize() {
    let id = ServingId::new("67890");
    let json = serde_json::to_string(&id).expect("should serialize");
    assert_eq!(json, r#""67890""#);
}

#[test]
fn test_serving_id_deserialize() {
    let json = r#""67890""#;
    let id: ServingId = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(id.as_str(), "67890");
}

#[test]
fn test_id_type_safety() {
    let food_id = FoodId::new("12345");
    let serving_id = ServingId::new("67890");
    assert_ne!(food_id.as_str(), serving_id.as_str());
}

// =============================================================================
// Nutrition Type Tests
// =============================================================================

#[test]
fn test_nutrition_required_fields() {
    let json = r#"{
        "calories": 200.0,
        "carbohydrate": 25.0,
        "protein": 20.0,
        "fat": 8.0
    }"#;
    let nutrition: Nutrition = serde_json::from_str(json).expect("should deserialize");
    assert!((nutrition.calories - 200.0).abs() < f64::EPSILON);
    assert!((nutrition.carbohydrate - 25.0).abs() < f64::EPSILON);
    assert!((nutrition.protein - 20.0).abs() < f64::EPSILON);
    assert!((nutrition.fat - 8.0).abs() < f64::EPSILON);
}

#[test]
fn test_nutrition_string_values() {
    let json = r#"{
        "calories": "200.5",
        "carbohydrate": "25.5",
        "protein": "20.5",
        "fat": "8.5"
    }"#;
    let nutrition: Nutrition = serde_json::from_str(json).expect("should deserialize");
    assert!((nutrition.calories - 200.5).abs() < f64::EPSILON);
}

#[test]
fn test_nutrition_optional_micronutrients() {
    let json = r#"{
        "calories": 200.0,
        "carbohydrate": 25.0,
        "protein": 20.0,
        "fat": 8.0,
        "saturated_fat": 2.0,
        "fiber": 5.0,
        "sodium": 400.0
    }"#;
    let nutrition: Nutrition = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(nutrition.saturated_fat, Some(2.0));
    assert_eq!(nutrition.fiber, Some(5.0));
    assert_eq!(nutrition.sodium, Some(400.0));
}

#[test]
fn test_nutrition_missing_optionals() {
    let json = r#"{
        "calories": 200.0,
        "carbohydrate": 25.0,
        "protein": 20.0,
        "fat": 8.0
    }"#;
    let nutrition: Nutrition = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(nutrition.saturated_fat, None);
    assert_eq!(nutrition.fiber, None);
    assert_eq!(nutrition.sodium, None);
}

#[test]
fn test_nutrition_all_micronutrients() {
    let nutrition: Nutrition = serde_json::from_str(fixtures::FOOD_MICRONUTRIENTS)
        .expect("should deserialize")
        .servings
        .serving
        .first()
        .expect("should have serving")
        .nutrition
        .clone();

    assert_eq!(nutrition.saturated_fat, Some(2.0));
    assert_eq!(nutrition.polyunsaturated_fat, Some(3.0));
    assert_eq!(nutrition.monounsaturated_fat, Some(2.5));
    assert_eq!(nutrition.trans_fat, Some(0.1));
    assert_eq!(nutrition.cholesterol, Some(50.0));
    assert_eq!(nutrition.potassium, Some(300.0));
    assert_eq!(nutrition.fiber, Some(5.0));
    assert_eq!(nutrition.sugar, Some(10.0));
    assert_eq!(nutrition.added_sugars, Some(5.0));
    assert_eq!(nutrition.vitamin_a, Some(10.0));
    assert_eq!(nutrition.vitamin_c, Some(50.0));
}

#[test]
fn test_nutrition_serialize_roundtrip() {
    let nutrition = Nutrition {
        calories: 200.0,
        carbohydrate: 25.0,
        protein: 20.0,
        fat: 8.0,
        saturated_fat: Some(2.0),
        polyunsaturated_fat: None,
        monounsaturated_fat: None,
        trans_fat: None,
        cholesterol: None,
        sodium: None,
        potassium: None,
        fiber: Some(5.0),
        sugar: None,
        added_sugars: None,
        vitamin_a: None,
        vitamin_c: None,
        vitamin_d: None,
        calcium: None,
        iron: None,
    };

    let json = serde_json::to_string(&nutrition).expect("should serialize");
    let deserialized: Nutrition = serde_json::from_str(&json).expect("should deserialize");

    assert!((deserialized.calories - 200.0).abs() < f64::EPSILON);
    assert_eq!(deserialized.fiber, Some(5.0));
}

// =============================================================================
// Serving Type Tests
// =============================================================================

#[test]
fn test_serving_deserialize() {
    let food: Food = serde_json::from_str(fixtures::FOOD_FULL_RESPONSE).expect("should deserialize");
    let serving = food.servings.serving.first().expect("should have serving");

    assert_eq!(serving.serving_id.as_str(), "67890");
    assert_eq!(serving.serving_description, "100g");
    assert!((serving.number_of_units - 1.0).abs() < f64::EPSILON);
    assert_eq!(serving.is_default, Some(1));
}

#[test]
fn test_serving_metric_info() {
    let food: Food = serde_json::from_str(fixtures::FOOD_FULL_RESPONSE).expect("should deserialize");
    let serving = food.servings.serving.first().expect("should have serving");

    assert_eq!(serving.metric_serving_amount, Some(100.0));
    assert_eq!(serving.metric_serving_unit, Some("g".to_string()));
}

#[test]
fn test_serving_multiple_options() {
    let food: Food = serde_json::from_str(fixtures::FOOD_BRAND_RESPONSE).expect("should deserialize");
    assert_eq!(food.servings.serving.len(), 2);
}

#[test]
fn test_serving_default_indicator() {
    let food: Food = serde_json::from_str(fixtures::FOOD_BRAND_RESPONSE).expect("should deserialize");
    let default_serving = food.servings.serving.iter().find(|s| s.is_default == Some(1));
    assert!(default_serving.is_some());
    assert_eq!(default_serving.unwrap().serving_id.as_str(), "11111");
}

// =============================================================================
// Food Type Tests
// =============================================================================

#[test]
fn test_food_deserialize_generic() {
    let food: Food = serde_json::from_str(fixtures::FOOD_FULL_RESPONSE).expect("should deserialize");

    assert_eq!(food.food_id.as_str(), "12345");
    assert_eq!(food.food_name, "Chicken Breast");
    assert_eq!(food.food_type, "Generic");
    assert!(food.brand_name.is_none());
}

#[test]
fn test_food_deserialize_brand() {
    let food: Food = serde_json::from_str(fixtures::FOOD_BRAND_RESPONSE).expect("should deserialize");

    assert_eq!(food.food_id.as_str(), "99999");
    assert_eq!(food.food_name, "Kellogg's Corn Flakes");
    assert_eq!(food.food_type, "Brand");
    assert_eq!(food.brand_name, Some("Kellogg's".to_string()));
}

#[test]
fn test_food_serialize_roundtrip() {
    let food: Food = serde_json::from_str(fixtures::FOOD_FULL_RESPONSE).expect("should deserialize");
    let json = serde_json::to_string(&food).expect("should serialize");
    let deserialized: Food = serde_json::from_str(&json).expect("should deserialize");

    assert_eq!(deserialized.food_id, food.food_id);
    assert_eq!(deserialized.food_name, food.food_name);
}

#[test]
fn test_food_debug_format() {
    let food: Food = serde_json::from_str(fixtures::FOOD_FULL_RESPONSE).expect("should deserialize");
    let debug = format!("{:?}", food);
    assert!(debug.contains("Chicken Breast"));
    assert!(debug.contains("12345"));
}

// =============================================================================
// Search Response Tests
// =============================================================================

#[test]
fn test_search_response_multiple() {
    let response: FoodSearchResponse =
        serde_json::from_str(fixtures::SEARCH_RESPONSE).expect("should deserialize");

    assert_eq!(response.foods.len(), 2);
    assert_eq!(response.page_number, 0);
    assert_eq!(response.max_results, 20);
    assert_eq!(response.total_results, 100);
}

#[test]
fn test_search_response_single() {
    let response: FoodSearchResponse =
        serde_json::from_str(fixtures::SEARCH_RESPONSE_SINGLE).expect("should deserialize");

    assert_eq!(response.foods.len(), 1);
    assert_eq!(response.foods[0].food_name, "Apple");
}

#[test]
fn test_search_response_pagination() {
    let json = r#"{
        "foods": {
            "food": [],
            "max_results": "50",
            "total_results": "200",
            "page_number": "3"
        }
    }"#;
    let response: FoodSearchResponse = serde_json::from_str(json).expect("should deserialize");

    assert_eq!(response.page_number, 3);
    assert_eq!(response.max_results, 50);
    assert_eq!(response.total_results, 200);
}

#[test]
fn test_search_result_fields() {
    let response: FoodSearchResponse =
        serde_json::from_str(fixtures::SEARCH_RESPONSE).expect("should deserialize");
    let result = response.foods.first().expect("should have result");

    assert_eq!(result.food_id.as_str(), "111");
    assert_eq!(result.food_name, "Apple");
    assert_eq!(result.food_type, "Generic");
    assert_eq!(result.food_description, "1 medium (180g)");
}

#[test]
fn test_search_result_brand_name() {
    let json = r#"{
        "foods": {
            "food": {
                "food_id": "123",
                "food_name": "Special K",
                "food_type": "Brand",
                "food_description": "1 cup",
                "brand_name": "Kellogg's",
                "food_url": "https://example.com"
            },
            "max_results": 20,
            "total_results": 1,
            "page_number": 0
        }
    }"#;
    let response: FoodSearchResponse = serde_json::from_str(json).expect("should deserialize");
    let result = response.foods.first().expect("should have result");

    assert_eq!(result.brand_name, Some("Kellogg's".to_string()));
}

// =============================================================================
// Autocomplete Response Tests
// =============================================================================

#[test]
fn test_autocomplete_multiple() {
    let response: FoodAutocompleteResponse =
        serde_json::from_str(fixtures::AUTOCOMPLETE_RESPONSE).expect("should deserialize");

    assert_eq!(response.suggestions.len(), 3);
    assert_eq!(response.suggestions[0].food_name, "Banana");
    assert_eq!(response.suggestions[1].food_name, "Banana Bread");
}

#[test]
fn test_autocomplete_single() {
    let response: FoodAutocompleteResponse =
        serde_json::from_str(fixtures::AUTOCOMPLETE_SINGLE).expect("should deserialize");

    assert_eq!(response.suggestions.len(), 1);
    assert_eq!(response.suggestions[0].food_id.as_str(), "123");
    assert_eq!(response.suggestions[0].food_name, "Banana");
}

#[test]
fn test_autocomplete_empty() {
    let json = r#"{"suggestions": {}}"#;
    let response: FoodAutocompleteResponse = serde_json::from_str(json).expect("should deserialize");
    assert!(response.suggestions.is_empty());
}

// =============================================================================
// Edge Cases and Boundary Conditions
// =============================================================================

#[test]
fn test_zero_nutrition_values() {
    let json = r#"{
        "calories": 0.0,
        "carbohydrate": 0.0,
        "protein": 0.0,
        "fat": 0.0
    }"#;
    let nutrition: Nutrition = serde_json::from_str(json).expect("should deserialize");
    assert!((nutrition.calories - 0.0).abs() < f64::EPSILON);
}

#[test]
fn test_large_nutrition_values() {
    let json = r#"{
        "calories": 10000.0,
        "carbohydrate": 1000.0,
        "protein": 500.0,
        "fat": 200.0
    }"#;
    let nutrition: Nutrition = serde_json::from_str(json).expect("should deserialize");
    assert!((nutrition.calories - 10000.0).abs() < f64::EPSILON);
}

#[test]
fn test_fractional_serving() {
    let json = r#"{
        "food_id": "123",
        "food_name": "Test",
        "food_type": "Generic",
        "food_url": "https://example.com",
        "servings": {
            "serving": {
                "serving_id": "456",
                "serving_description": "0.5 cup",
                "serving_url": "https://example.com",
                "metric_serving_amount": 60.0,
                "metric_serving_unit": "ml",
                "number_of_units": 0.5,
                "measurement_description": "cup",
                "calories": 50.0,
                "carbohydrate": 10.0,
                "protein": 2.0,
                "fat": 1.0
            }
        }
    }"#;
    let food: Food = serde_json::from_str(json).expect("should deserialize");
    assert!((food.servings.serving[0].number_of_units - 0.5).abs() < f64::EPSILON);
}

#[test]
fn test_special_characters_in_food_name() {
    let json = r#"{
        "food_id": "123",
        "food_name": " Häagen-Dazs® Ice Cream ",
        "food_type": "Brand",
        "food_url": "https://example.com",
        "servings": {
            "serving": {
                "serving_id": "456",
                "serving_description": "1 cup",
                "serving_url": "https://example.com",
                "metric_serving_amount": 100.0,
                "metric_serving_unit": "g",
                "number_of_units": 1.0,
                "measurement_description": "cup",
                "calories": 250.0,
                "carbohydrate": 30.0,
                "protein": 5.0,
                "fat": 12.0
            }
        }
    }"#;
    let food: Food = serde_json::from_str(json).expect("should deserialize");
    assert!(food.food_name.contains("Häagen-Dazs"));
}

#[test]
fn test_unicode_in_brand_name() {
    let json = r#"{
        "food_id": "123",
        "food_name": "Ramen",
        "food_type": "Brand",
        "food_url": "https://example.com",
        "brand_name": "日清食品",
        "servings": {
            "serving": {
                "serving_id": "456",
                "serving_description": "1 pack",
                "serving_url": "https://example.com",
                "metric_serving_amount": 80.0,
                "metric_serving_unit": "g",
                "number_of_units": 1.0,
                "measurement_description": "pack",
                "calories": 400.0,
                "carbohydrate": 60.0,
                "protein": 10.0,
                "fat": 15.0
            }
        }
    }"#;
    let food: Food = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(food.brand_name, Some("日清食品".to_string()));
}

// =============================================================================
// Clone and Debug Trait Tests
// =============================================================================

#[test]
fn test_food_clone() {
    let food1: Food = serde_json::from_str(fixtures::FOOD_FULL_RESPONSE).expect("should deserialize");
    let food2 = food1.clone();
    assert_eq!(food1.food_id, food2.food_id);
    assert_eq!(food1.food_name, food2.food_name);
}

#[test]
fn test_serving_clone() {
    let food: Food = serde_json::from_str(fixtures::FOOD_FULL_RESPONSE).expect("should deserialize");
    let serving1 = food.servings.serving[0].clone();
    let serving2 = serving1.clone();
    assert_eq!(serving1.serving_id, serving2.serving_id);
}

#[test]
fn test_nutrition_clone() {
    let food: Food = serde_json::from_str(fixtures::FOOD_FULL_RESPONSE).expect("should deserialize");
    let nutrition1 = food.servings.serving[0].nutrition.clone();
    let nutrition2 = nutrition1.clone();
    assert!((nutrition1.calories - nutrition2.calories).abs() < f64::EPSILON);
}

#[test]
fn test_food_debug_format() {
    let food: Food = serde_json::from_str(fixtures::FOOD_FULL_RESPONSE).expect("should deserialize");
    let debug = format!("{:?}", food);
    assert!(debug.contains("Food"));
    assert!(debug.contains("12345"));
    assert!(debug.contains("Chicken Breast"));
}

#[test]
fn test_serving_debug_format() {
    let food: Food = serde_json::from_str(fixtures::FOOD_FULL_RESPONSE).expect("should deserialize");
    let serving = &food.servings.serving[0];
    let debug = format!("{:?}", serving);
    assert!(debug.contains("Serving"));
    assert!(debug.contains("67890"));
}

// =============================================================================
// Error Cases
// =============================================================================

#[test]
fn test_food_missing_required_field() {
    let json = r#"{
        "food_id": "123",
        "food_name": "Test",
        "food_url": "https://example.com"
    }"#;
    let result: Result<Food, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

#[test]
fn test_nutrition_missing_required_field() {
    let json = r#"{"calories": 100.0, "carbohydrate": 10.0}"#;
    let result: Result<Nutrition, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

#[test]
fn test_invalid_nutrition_string() {
    let json = r#"{
        "calories": "not_a_number",
        "carbohydrate": 10.0,
        "protein": 5.0,
        "fat": 2.0
    }"#;
    let result: Result<Nutrition, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

#[test]
fn test_food_id_invalid_json() {
    let json = r#"not_a_string"#;
    let result: Result<FoodId, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

// =============================================================================
// Parameterized Tests (rstest) - Kent Beck Table-Driven Style
// =============================================================================

/// Parameterized test for FoodId creation from various string types
#[rstest]
#[case::from_str("12345", "12345")]
#[case::from_numeric_string("67890", "67890")]
#[case::from_empty_string("", "")]
#[case::from_special_chars("food-123_abc", "food-123_abc")]
fn test_food_id_creation(#[case] input: &str, #[case] expected: &str) {
    let id = FoodId::new(input);
    assert_eq!(id.as_str(), expected);
}

/// Parameterized test for ServingId creation
#[rstest]
#[case::from_str("serve_123", "serve_123")]
#[case::from_numeric_string("99999", "99999")]
fn test_serving_id_creation(#[case] input: &str, #[case] expected: &str) {
    let id = ServingId::new(input);
    assert_eq!(id.as_str(), expected);
}

/// Parameterized test for nutrition deserialization with flexible number formats
/// Tests that both string and numeric JSON values deserialize correctly
#[rstest]
#[case::all_integers(
    r#"{"calories": 200, "carbohydrate": 25, "protein": 20, "fat": 8}"#,
    200.0, 25.0, 20.0, 8.0
)]
#[case::all_floats(
    r#"{"calories": 200.5, "carbohydrate": 25.5, "protein": 20.5, "fat": 8.5}"#,
    200.5, 25.5, 20.5, 8.5
)]
#[case::all_strings(
    r#"{"calories": "200", "carbohydrate": "25", "protein": "20", "fat": "8"}"#,
    200.0, 25.0, 20.0, 8.0
)]
#[case::mixed_types(
    r#"{"calories": 200, "carbohydrate": "25.5", "protein": 20, "fat": "8.0"}"#,
    200.0, 25.5, 20.0, 8.0
)]
#[case::zero_values(
    r#"{"calories": 0, "carbohydrate": 0.0, "protein": "0", "fat": "0.0"}"#,
    0.0, 0.0, 0.0, 0.0
)]
fn test_nutrition_flexible_parsing(
    #[case] json: &str,
    #[case] expected_calories: f64,
    #[case] expected_carbs: f64,
    #[case] expected_protein: f64,
    #[case] expected_fat: f64,
) {
    let nutrition: Nutrition = serde_json::from_str(json).expect("should parse");

    assert!(
        (nutrition.calories - expected_calories).abs() < f64::EPSILON,
        "calories mismatch: got {}, expected {}",
        nutrition.calories,
        expected_calories
    );
    assert!(
        (nutrition.carbohydrate - expected_carbs).abs() < f64::EPSILON,
        "carbs mismatch"
    );
    assert!(
        (nutrition.protein - expected_protein).abs() < f64::EPSILON,
        "protein mismatch"
    );
    assert!((nutrition.fat - expected_fat).abs() < f64::EPSILON, "fat mismatch");
}

/// Parameterized test for pagination values in search responses
#[rstest]
#[case::first_page(0, 20, 100)]
#[case::middle_page(5, 50, 500)]
#[case::last_page(9, 10, 100)]
#[case::single_result(0, 20, 1)]
fn test_search_pagination_values(
    #[case] page_number: i32,
    #[case] max_results: i32,
    #[case] total_results: i32,
) {
    let json = format!(
        r#"{{
            "foods": {{
                "food": [],
                "max_results": "{}",
                "total_results": "{}",
                "page_number": "{}"
            }}
        }}"#,
        max_results, total_results, page_number
    );

    let response: FoodSearchResponse = serde_json::from_str(&json).expect("should parse");

    assert_eq!(response.page_number, page_number);
    assert_eq!(response.max_results, max_results);
    assert_eq!(response.total_results, total_results);
}

/// Parameterized test for food type classification
#[rstest]
#[case::generic_food("Generic", None)]
#[case::branded_food("Brand", Some("Kellogg's"))]
fn test_food_type_classification(#[case] food_type: &str, #[case] brand_name: Option<&str>) {
    let brand_json = brand_name
        .map(|b| format!(r#""brand_name": "{}","#, b))
        .unwrap_or_default();

    let json = format!(
        r#"{{
            "food_id": "123",
            "food_name": "Test Food",
            "food_type": "{}",
            "food_url": "https://example.com",
            {}
            "servings": {{
                "serving": {{
                    "serving_id": "456",
                    "serving_description": "1 serving",
                    "serving_url": "https://example.com/serving",
                    "metric_serving_amount": 100.0,
                    "metric_serving_unit": "g",
                    "number_of_units": 1.0,
                    "measurement_description": "serving",
                    "calories": 100.0,
                    "carbohydrate": 10.0,
                    "protein": 5.0,
                    "fat": 2.0
                }}
            }}
        }}"#,
        food_type, brand_json
    );

    let food: Food = serde_json::from_str(&json).expect("should parse");
    assert_eq!(food.food_type, food_type);
    assert_eq!(food.brand_name.as_deref(), brand_name);
}

/// Parameterized test for single vs array serving deserialization
#[rstest]
#[case::single_serving(
    r#"{"serving": {"serving_id": "1", "serving_description": "1 cup", "serving_url": "http://x", "number_of_units": 1.0, "measurement_description": "cup", "calories": 100, "carbohydrate": 10, "protein": 5, "fat": 2}}"#,
    1
)]
#[case::multiple_servings(
    r#"{"serving": [{"serving_id": "1", "serving_description": "1 cup", "serving_url": "http://x", "number_of_units": 1.0, "measurement_description": "cup", "calories": 100, "carbohydrate": 10, "protein": 5, "fat": 2}, {"serving_id": "2", "serving_description": "100g", "serving_url": "http://y", "number_of_units": 1.0, "measurement_description": "gram", "calories": 150, "carbohydrate": 15, "protein": 8, "fat": 3}]}"#,
    2
)]
fn test_servings_single_or_vec(#[case] json: &str, #[case] expected_count: usize) {
    let servings: FoodServings = serde_json::from_str(json).expect("should parse");
    assert_eq!(servings.serving.len(), expected_count);
}

/// Parameterized test for autocomplete suggestions
#[rstest]
#[case::empty_suggestions(r#"{"suggestions": {}}"#, 0)]
#[case::single_suggestion(
    r#"{"suggestions": {"suggestion": {"food_id": "123", "food_name": "Apple"}}}"#,
    1
)]
#[case::multiple_suggestions(
    r#"{"suggestions": {"suggestion": [{"food_id": "1", "food_name": "A"}, {"food_id": "2", "food_name": "B"}]}}"#,
    2
)]
fn test_autocomplete_response_size(#[case] json: &str, #[case] expected_count: usize) {
    let response: FoodAutocompleteResponse = serde_json::from_str(json).expect("should parse");
    assert_eq!(response.suggestions.len(), expected_count);
}

/// Test that invalid JSON consistently fails
#[rstest]
#[case::missing_calories(r#"{"carbohydrate": 10, "protein": 5, "fat": 2}"#)]
#[case::invalid_number(r#"{"calories": "abc", "carbohydrate": 10, "protein": 5, "fat": 2}"#)]
#[case::null_required(r#"{"calories": null, "carbohydrate": 10, "protein": 5, "fat": 2}"#)]
fn test_nutrition_invalid_json_fails(#[case] json: &str) {
    let result: Result<Nutrition, _> = serde_json::from_str(json);
    assert!(result.is_err(), "Expected error for JSON: {}", json);
}
