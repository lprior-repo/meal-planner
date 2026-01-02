#![allow(clippy::unwrap_used)]

use meal_planner::fatsecret::foods::types::Food;
use std::fs;

#[allow(clippy::panic)]
fn load_fixture(name: &str) -> String {
    fs::read_to_string(format!("tests/fixtures/foods/{}.json", name))
        .unwrap_or_else(|e| panic!("Failed to load fixture {}: {}", name, e))
}

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

    assert_eq!(serving.serving_id.as_str(), "67890");
    assert_eq!(serving.serving_description, "1 cup, chopped or diced");
    assert_eq!(serving.metric_serving_amount, Some(140.0));
    assert_eq!(serving.metric_serving_unit, Some("g".to_string()));
    assert!((serving.number_of_units - 1.0).abs() < f64::EPSILON);
    assert_eq!(serving.measurement_description, "cup, chopped or diced");
    assert_eq!(serving.is_default, Some(1));

    assert!((serving.nutrition.calories - 231.0).abs() < f64::EPSILON);
    assert!((serving.nutrition.carbohydrate - 0.0).abs() < f64::EPSILON);
    assert!((serving.nutrition.protein - 43.4).abs() < f64::EPSILON);
    assert!((serving.nutrition.fat - 5.04).abs() < f64::EPSILON);

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
    let json = load_fixture("food_complete");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize food");

    let serving1 = &food.servings.serving[0];
    assert!((serving1.nutrition.calories - 231.0).abs() < f64::EPSILON);
    assert!((serving1.nutrition.protein - 43.4).abs() < f64::EPSILON);

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

    assert!((serving.nutrition.calories - 95.0).abs() < f64::EPSILON);
    assert!((serving.nutrition.protein - 0.5).abs() < f64::EPSILON);

    assert!(serving.metric_serving_amount.is_none());
    assert!(serving.metric_serving_unit.is_none());
    assert!(serving.is_default.is_none());
    assert!(serving.nutrition.saturated_fat.is_none());
    assert!(serving.nutrition.fiber.is_none());
    assert!(serving.nutrition.cholesterol.is_none());
    assert!(serving.nutrition.sodium.is_none());
    assert!(serving.nutrition.vitamin_a.is_none());
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing, clippy::unwrap_used)]
fn test_find_default_serving() {
    let json = load_fixture("food_complete");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize food");

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

    let serving1 = &food.servings.serving[0];
    assert_eq!(serving1.metric_serving_amount, Some(140.0));
    assert_eq!(serving1.metric_serving_unit, Some("g".to_string()));

    let serving2 = &food.servings.serving[1];
    assert_eq!(serving2.metric_serving_amount, Some(100.0));
    assert_eq!(serving2.metric_serving_unit, Some("g".to_string()));

    let ratio = serving1.metric_serving_amount.unwrap() / serving2.metric_serving_amount.unwrap();
    assert!((ratio - 1.4).abs() < f64::EPSILON);
}
