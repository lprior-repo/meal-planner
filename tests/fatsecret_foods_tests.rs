//! Unit tests for `FatSecret` Foods domain
//!
//! This module provides comprehensive test coverage for the foods domain including:
//! - Food type deserialization from JSON fixtures
//! - Serving calculation logic
//! - Nutrition data handling
//! - Error cases (missing fields, invalid data)
//! - Opaque ID type safety

use meal_planner::fatsecret::foods::types::{
    Food, FoodAutocompleteResponse, FoodId, FoodSearchResponse, ServingId,
};
use std::fs;

// ============================================================================
// Test Fixtures
// ============================================================================

#[allow(clippy::panic)]
fn load_fixture(name: &str) -> String {
    fs::read_to_string(format!("tests/fixtures/foods/{}.json", name))
        .unwrap_or_else(|e| panic!("Failed to load fixture {}: {}", name, e))
}

// ============================================================================
// Opaque ID Type Tests
// ============================================================================

#[test]
fn test_food_id_creation() {
    let id1 = FoodId::new("12345");
    let id2 = FoodId::from("12345");
    let id3 = FoodId::from("12345".to_string());

    assert_eq!(id1.as_str(), "12345");
    assert_eq!(id2.as_str(), "12345");
    assert_eq!(id3.as_str(), "12345");
    assert_eq!(id1, id2);
    assert_eq!(id2, id3);
}

#[test]
fn test_food_id_display() {
    let id = FoodId::new("98765");
    assert_eq!(format!("{}", id), "98765");
    assert_eq!(id.to_string(), "98765");
}

#[test]
fn test_food_id_hash_equality() {
    use std::collections::HashSet;

    let id1 = FoodId::new("12345");
    let id2 = FoodId::new("12345");
    let id3 = FoodId::new("67890");

    let mut set = HashSet::new();
    set.insert(id1.clone());
    set.insert(id2);
    set.insert(id3.clone());

    // Should only have 2 unique IDs
    assert_eq!(set.len(), 2);
    assert!(set.contains(&id1));
    assert!(set.contains(&id3));
}

#[test]
fn test_serving_id_creation() {
    let id1 = ServingId::new("67890");
    let id2 = ServingId::from("67890");

    assert_eq!(id1.as_str(), "67890");
    assert_eq!(id2.as_str(), "67890");
    assert_eq!(id1, id2);
}

#[test]
fn test_serving_id_display() {
    let id = ServingId::new("11111");
    assert_eq!(format!("{}", id), "11111");
}

// Type safety test: This should not compile
// #[test]
// fn test_food_id_serving_id_not_interchangeable() {
//     let food_id = FoodId::new("123");
//     let _serving_id: ServingId = food_id; // Compile error!
// }

// ============================================================================
// Food Deserialization Tests
// ============================================================================

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
    // Minimal nutrition - optional fields should be None
    assert!(serving.nutrition.saturated_fat.is_none());
    assert!(serving.nutrition.fiber.is_none());
    assert!(serving.nutrition.cholesterol.is_none());
}

// ============================================================================
// Serving Deserialization Tests
// ============================================================================

#[test]
#[allow(
    clippy::expect_used,
    clippy::indexing_slicing,
    clippy::cognitive_complexity
)]
fn test_deserialize_serving_with_all_nutrition() {
    let json = load_fixture("food_complete");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize food");

    let serving = &food.servings.serving[0];

    // Verify serving metadata
    assert_eq!(serving.serving_id.as_str(), "67890");
    assert_eq!(serving.serving_description, "1 cup, chopped or diced");
    assert_eq!(serving.metric_serving_amount, Some(140.0));
    assert_eq!(serving.metric_serving_unit, Some("g".to_string()));
    assert!((serving.number_of_units - 1.0).abs() < f64::EPSILON);
    assert_eq!(serving.measurement_description, "cup, chopped or diced");
    assert_eq!(serving.is_default, Some(1));

    // Verify required nutrition fields
    assert!((serving.nutrition.calories - 231.0).abs() < f64::EPSILON);
    assert!((serving.nutrition.carbohydrate - 0.0).abs() < f64::EPSILON);
    assert!((serving.nutrition.protein - 43.4).abs() < f64::EPSILON);
    assert!((serving.nutrition.fat - 5.04).abs() < f64::EPSILON);

    // Verify optional nutrition fields
    assert_eq!(serving.nutrition.saturated_fat, Some(1.427));
    assert_eq!(serving.nutrition.polyunsaturated_fat, Some(1.123));
    assert_eq!(serving.nutrition.monounsaturated_fat, Some(1.850));
    assert_eq!(serving.nutrition.trans_fat, Some(0.0));
    assert_eq!(serving.nutrition.cholesterol, Some(119.0));
    assert_eq!(serving.nutrition.sodium, Some(104.0));
    assert_eq!(serving.nutrition.potassium, Some(358.0));
    assert_eq!(serving.nutrition.fiber, Some(0.0));
    assert_eq!(serving.nutrition.sugar, Some(0.0));
    assert_eq!(serving.nutrition.vitamin_a, Some(1.0));
    assert_eq!(serving.nutrition.vitamin_c, Some(0.0));
    assert_eq!(serving.nutrition.calcium, Some(2.0));
    assert_eq!(serving.nutrition.iron, Some(6.0));
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing)]
fn test_deserialize_serving_flexible_number_types() {
    // Test that we handle both string and numeric values for nutrition fields
    let json = load_fixture("food_complete");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize food");

    // First serving has all string values
    let serving1 = &food.servings.serving[0];
    assert!((serving1.nutrition.calories - 231.0).abs() < f64::EPSILON);
    assert!((serving1.nutrition.protein - 43.4).abs() < f64::EPSILON);

    // Second serving has numeric values
    let serving2 = &food.servings.serving[1];
    assert!((serving2.nutrition.calories - 165.0).abs() < f64::EPSILON);
    assert!((serving2.nutrition.protein - 31.0).abs() < f64::EPSILON);
}

#[test]
#[allow(
    clippy::expect_used,
    clippy::indexing_slicing,
    clippy::cognitive_complexity
)]
fn test_deserialize_serving_missing_optional_fields() {
    let json = load_fixture("food_minimal");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize food");

    let serving = &food.servings.serving[0];

    // Required fields should exist
    assert!((serving.nutrition.calories - 95.0).abs() < f64::EPSILON);
    assert!((serving.nutrition.protein - 0.5).abs() < f64::EPSILON);

    // Optional fields should be None
    assert!(serving.metric_serving_amount.is_none());
    assert!(serving.metric_serving_unit.is_none());
    assert!(serving.is_default.is_none());
    assert!(serving.nutrition.saturated_fat.is_none());
    assert!(serving.nutrition.fiber.is_none());
    assert!(serving.nutrition.cholesterol.is_none());
    assert!(serving.nutrition.sodium.is_none());
    assert!(serving.nutrition.vitamin_a.is_none());
}

// ============================================================================
// Search Response Tests
// ============================================================================

#[test]
#[allow(
    clippy::expect_used,
    clippy::indexing_slicing,
    clippy::cognitive_complexity
)]
fn test_deserialize_search_response() {
    let json = load_fixture("search_response");
    let response: FoodSearchResponse = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["foods"].clone()))
        .expect("Failed to deserialize search response");

    assert_eq!(response.max_results, 20);
    assert_eq!(response.total_results, 150);
    assert_eq!(response.page_number, 0);
    assert_eq!(response.foods.len(), 2);

    // Check first result
    let first = &response.foods[0];
    assert_eq!(first.food_id.as_str(), "12345");
    assert_eq!(first.food_name, "Chicken Breast");
    assert_eq!(first.food_type, "Generic");
    assert!(first.brand_name.is_none());

    // Check second result (branded)
    let second = &response.foods[1];
    assert_eq!(second.food_id.as_str(), "98765");
    assert_eq!(second.brand_name, Some("Tyson".to_string()));
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing)]
fn test_deserialize_search_response_empty() {
    let json = load_fixture("search_response_empty");
    let response: FoodSearchResponse = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["foods"].clone()))
        .expect("Failed to deserialize empty search response");

    assert_eq!(response.total_results, 0);
    assert_eq!(response.foods.len(), 0);
}

#[test]
#[allow(
    clippy::expect_used,
    clippy::indexing_slicing,
    clippy::integer_division
)]
fn test_search_response_pagination_calculation() {
    let json = load_fixture("search_response");
    let response: FoodSearchResponse = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["foods"].clone()))
        .expect("Failed to deserialize search response");

    let total_pages = (response.total_results / response.max_results) + 1;
    let current_page = response.page_number + 1; // API is 0-indexed

    assert_eq!(current_page, 1);
    assert_eq!(total_pages, 8); // 150 / 20 + 1 = 8
}

// ============================================================================
// Autocomplete Response Tests
// ============================================================================

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing)]
fn test_deserialize_autocomplete_response() {
    let json = load_fixture("autocomplete_response");
    let response: FoodAutocompleteResponse = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["suggestions"].clone()))
        .expect("Failed to deserialize autocomplete response");

    assert_eq!(response.suggestions.len(), 3);

    let first = &response.suggestions[0];
    assert_eq!(first.food_id.as_str(), "11111");
    assert_eq!(first.food_name, "Chicken Breast");
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing)]
fn test_deserialize_autocomplete_single_result() {
    // Test single_or_vec deserialization for single suggestion
    let json = load_fixture("autocomplete_single");
    let response: FoodAutocompleteResponse = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["suggestions"].clone()))
        .expect("Failed to deserialize single autocomplete");

    assert_eq!(response.suggestions.len(), 1);
    assert_eq!(response.suggestions[0].food_id.as_str(), "11111");
    assert_eq!(response.suggestions[0].food_name, "Chicken Breast");
}

// ============================================================================
// Nutrition Calculation Tests
// ============================================================================

#[test]
#[allow(
    clippy::expect_used,
    clippy::indexing_slicing,
    clippy::suboptimal_flops
)]
fn test_nutrition_macros_calculation() {
    let json = load_fixture("food_complete");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize food");

    let serving = &food.servings.serving[0];
    let nutrition = &serving.nutrition;

    // Verify basic macros
    assert!((nutrition.calories - 231.0).abs() < f64::EPSILON);
    assert!((nutrition.protein - 43.4).abs() < f64::EPSILON);
    assert!((nutrition.carbohydrate - 0.0).abs() < f64::EPSILON);
    assert!((nutrition.fat - 5.04).abs() < f64::EPSILON);

    // Calculate calories from macros (4 cal/g protein, 4 cal/g carb, 9 cal/g fat)
    let calculated_calories =
        (nutrition.protein * 4.0) + (nutrition.carbohydrate * 4.0) + (nutrition.fat * 9.0);

    // Allow rounding difference (FatSecret rounds nutrition values)
    let diff = (calculated_calories - nutrition.calories).abs();
    assert!(
        diff < 15.0,
        "Calculated calories {} differs from reported {} by {}",
        calculated_calories,
        nutrition.calories,
        diff
    );
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing, clippy::unwrap_used)]
fn test_nutrition_fat_breakdown() {
    let json = load_fixture("food_complete");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize food");

    let serving = &food.servings.serving[0];
    let nutrition = &serving.nutrition;

    // Verify fat breakdown components
    let saturated = nutrition.saturated_fat.unwrap();
    let poly = nutrition.polyunsaturated_fat.unwrap();
    let mono = nutrition.monounsaturated_fat.unwrap();
    let trans = nutrition.trans_fat.unwrap();

    // Sum of fat components should be close to total fat (but may not equal due to rounding)
    let fat_sum = saturated + poly + mono + trans;
    let diff = (fat_sum - nutrition.fat).abs();
    // Note: FatSecret data may not have all fat types (e.g., missing omega-3/6 breakdown)
    assert!(
        diff < 1.0,
        "Fat components sum {} differs from total fat {} by {}",
        fat_sum,
        nutrition.fat,
        diff
    );
}

// ============================================================================
// Serving Logic Tests
// ============================================================================

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing, clippy::unwrap_used)]
fn test_find_default_serving() {
    let json = load_fixture("food_complete");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize food");

    // Find default serving
    let default_serving = food
        .servings
        .serving
        .iter()
        .find(|s| s.is_default == Some(1));

    assert!(default_serving.is_some());
    let serving = default_serving.unwrap();
    assert_eq!(serving.serving_description, "1 cup, chopped or diced");
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing, clippy::unwrap_used)]
fn test_fallback_to_first_serving_when_no_default() {
    let json = load_fixture("food_minimal");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize food");

    // No default specified, should use first serving
    let serving = food
        .servings
        .serving
        .iter()
        .find(|s| s.is_default == Some(1))
        .or_else(|| food.servings.serving.first());

    assert!(serving.is_some());
    assert_eq!(serving.unwrap().serving_description, "1 medium");
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing, clippy::unwrap_used)]
fn test_metric_serving_conversion() {
    let json = load_fixture("food_complete");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize food");

    // First serving has metric data
    let serving1 = &food.servings.serving[0];
    assert_eq!(serving1.metric_serving_amount, Some(140.0));
    assert_eq!(serving1.metric_serving_unit, Some("g".to_string()));

    // Second serving also has metric data
    let serving2 = &food.servings.serving[1];
    assert_eq!(serving2.metric_serving_amount, Some(100.0));
    assert_eq!(serving2.metric_serving_unit, Some("g".to_string()));

    // Can calculate scaling factor between servings
    let ratio = serving1.metric_serving_amount.unwrap() / serving2.metric_serving_amount.unwrap();
    assert!((ratio - 1.4).abs() < f64::EPSILON);
}

// ============================================================================
// Error Handling Tests
// ============================================================================

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

    // Missing required "calories" field should fail
    let result: Result<serde_json::Value, _> = serde_json::from_str(invalid_json);
    assert!(result.is_ok()); // JSON is valid

    let value = result.unwrap();
    let food_result: Result<Food, _> = serde_json::from_value(value["food"].clone());
    assert!(
        food_result.is_err(),
        "Should fail when missing required calories field"
    );
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
    assert!(
        food_result.is_err(),
        "Should fail with invalid number format"
    );
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing, clippy::unwrap_used)]
fn test_deserialize_empty_string_as_zero() {
    // FatSecret sometimes returns empty strings for zero values
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
                    "number_of_units": "",
                    "measurement_description": "cup",
                    "calories": "100",
                    "protein": "10.0",
                    "carbohydrate": "",
                    "fat": "5.0"
                }
            }
        }
    }"#;

    let value: serde_json::Value = serde_json::from_str(json).unwrap();
    let food: Food =
        serde_json::from_value(value["food"].clone()).expect("Should handle empty strings as zero");

    let serving = &food.servings.serving[0];
    assert!((serving.number_of_units - 0.0).abs() < f64::EPSILON);
    assert!((serving.nutrition.carbohydrate - 0.0).abs() < f64::EPSILON);
}

// ============================================================================
// Serialization Tests
// ============================================================================

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing)]
fn test_serialize_food_roundtrip() {
    let json = load_fixture("food_complete");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize food");

    // Serialize and deserialize
    let serialized = serde_json::to_string(&food).expect("Failed to serialize");
    let deserialized: Food = serde_json::from_str(&serialized).expect("Failed to deserialize");

    assert_eq!(food.food_id, deserialized.food_id);
    assert_eq!(food.food_name, deserialized.food_name);
    assert_eq!(
        food.servings.serving.len(),
        deserialized.servings.serving.len()
    );
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing)]
fn test_serialize_opaque_ids() {
    let food_id = FoodId::new("12345");
    let serving_id = ServingId::new("67890");

    let food_json = serde_json::to_string(&food_id).expect("Failed to serialize FoodId");
    let serving_json = serde_json::to_string(&serving_id).expect("Failed to serialize ServingId");

    // Should serialize as plain strings (transparent)
    assert_eq!(food_json, r#""12345""#);
    assert_eq!(serving_json, r#""67890""#);

    // Should deserialize back
    let food_id_back: FoodId = serde_json::from_str(&food_json).expect("Failed to deserialize");
    let serving_id_back: ServingId =
        serde_json::from_str(&serving_json).expect("Failed to deserialize");

    assert_eq!(food_id, food_id_back);
    assert_eq!(serving_id, serving_id_back);
}

// ============================================================================
// Integration Tests
// ============================================================================

#[test]
#[allow(
    clippy::expect_used,
    clippy::indexing_slicing,
    clippy::cognitive_complexity,
    clippy::unwrap_used
)]
fn test_complete_food_workflow() {
    // Load a food, find default serving, verify nutrition
    let json = load_fixture("food_complete");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize food");

    // 1. Verify food metadata
    assert_eq!(food.food_name, "Chicken Breast");
    assert_eq!(food.food_type, "Generic");

    // 2. Find default serving
    let default_serving = food
        .servings
        .serving
        .iter()
        .find(|s| s.is_default == Some(1))
        .expect("Should have default serving");

    // 3. Verify serving metadata
    assert_eq!(
        default_serving.serving_description,
        "1 cup, chopped or diced"
    );
    assert_eq!(default_serving.metric_serving_amount, Some(140.0));

    // 4. Verify nutrition is complete
    let nutrition = &default_serving.nutrition;
    assert!(nutrition.calories > 0.0);
    assert!(nutrition.protein > 0.0);
    assert!(nutrition.saturated_fat.is_some());
    assert!(nutrition.cholesterol.is_some());

    // 5. Calculate serving for custom amount (e.g., 200g)
    let target_grams = 200.0;
    let serving_grams = default_serving.metric_serving_amount.unwrap();
    let multiplier = target_grams / serving_grams;

    let scaled_calories = nutrition.calories * multiplier;
    let scaled_protein = nutrition.protein * multiplier;

    assert!((scaled_calories - 330.0).abs() < 1.0); // ~330 cal for 200g
    assert!((scaled_protein - 62.0).abs() < 1.0); // ~62g protein for 200g
}
