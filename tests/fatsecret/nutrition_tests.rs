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
    clippy::suboptimal_flops
)]
fn test_nutrition_macros_calculation() {
    let json = load_fixture("food_complete");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize food");

    let serving = &food.servings.serving[0];
    let nutrition = &serving.nutrition;

    assert!((nutrition.calories - 231.0).abs() < f64::EPSILON);
    assert!((nutrition.protein - 43.4).abs() < f64::EPSILON);
    assert!((nutrition.carbohydrate - 0.0).abs() < f64::EPSILON);
    assert!((nutrition.fat - 5.04).abs() < f64::EPSILON);

    let calculated_calories =
        (nutrition.protein * 4.0) + (nutrition.carbohydrate * 4.0) + (nutrition.fat * 9.0);

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

    let saturated = nutrition.saturated_fat.unwrap();
    let poly = nutrition.polyunsaturated_fat.unwrap();
    let mono = nutrition.monounsaturated_fat.unwrap();
    let trans = nutrition.trans_fat.unwrap();

    let fat_sum = saturated + poly + mono + trans;
    let diff = (fat_sum - nutrition.fat).abs();
    assert!(
        diff < 1.0,
        "Fat components sum {} differs from total fat {} by {}",
        fat_sum,
        nutrition.fat,
        diff
    );
}

#[test]
#[allow(
    clippy::expect_used,
    clippy::indexing_slicing,
    clippy::cognitive_complexity,
    clippy::unwrap_used
)]
fn test_complete_food_workflow() {
    let json = load_fixture("food_complete");
    let food: Food = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["food"].clone()))
        .expect("Failed to deserialize food");

    assert_eq!(food.food_name, "Chicken Breast");
    assert_eq!(food.food_type, "Generic");

    let default_serving = food
        .servings
        .serving
        .iter()
        .find(|s| s.is_default == Some(1))
        .expect("Should have default serving");

    assert_eq!(
        default_serving.serving_description,
        "1 cup, chopped or diced"
    );
    assert_eq!(default_serving.metric_serving_amount, Some(140.0));

    let nutrition = &default_serving.nutrition;
    assert!(nutrition.calories > 0.0);
    assert!(nutrition.protein > 0.0);
    assert!(nutrition.saturated_fat.is_some());
    assert!(nutrition.cholesterol.is_some());

    let target_grams = 200.0;
    let serving_grams = default_serving.metric_serving_amount.unwrap();
    let multiplier = target_grams / serving_grams;

    let scaled_calories = nutrition.calories * multiplier;
    let scaled_protein = nutrition.protein * multiplier;

    assert!((scaled_calories - 330.0).abs() < 1.0);
    assert!((scaled_protein - 62.0).abs() < 1.0);
}
