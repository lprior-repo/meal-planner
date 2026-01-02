#![allow(clippy::unwrap_used)]

use meal_planner::fatsecret::foods::types::FoodAutocompleteResponse;
use std::fs;

#[allow(clippy::panic)]
fn load_fixture(name: &str) -> String {
    fs::read_to_string(format!("tests/fixtures/foods/{}.json", name))
        .unwrap_or_else(|e| panic!("Failed to load fixture {}: {}", name, e))
}

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
    let json = load_fixture("autocomplete_single");
    let response: FoodAutocompleteResponse = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["suggestions"].clone()))
        .expect("Failed to deserialize single autocomplete");

    assert_eq!(response.suggestions.len(), 1);
    assert_eq!(response.suggestions[0].food_id.as_str(), "11111");
    assert_eq!(response.suggestions[0].food_name, "Chicken Breast");
}
