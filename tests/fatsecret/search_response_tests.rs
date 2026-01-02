#![allow(clippy::unwrap_used)]

use meal_planner::fatsecret::foods::types::FoodSearchResponse;
use std::fs;

#[allow(clippy::panic)]
fn load_fixture(name: &str) -> String {
    fs::read_to_string(format!("tests/fixtures/foods/{}.json", name))
        .unwrap_or_else(|e| panic!("Failed to load fixture {}: {}", name, e))
}

#[test]
#[allow(clippy::expect_used, clippy::indexing_slicing, clippy::cognitive_complexity)]
fn test_deserialize_search_response() {
    let json = load_fixture("search_response");
    let response: FoodSearchResponse = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["foods"].clone()))
        .expect("Failed to deserialize search response");

    assert_eq!(response.max_results, 20);
    assert_eq!(response.total_results, 150);
    assert_eq!(response.page_number, 0);
    assert_eq!(response.foods.len(), 2);

    let first = &response.foods[0];
    assert_eq!(first.food_id.as_str(), "12345");
    assert_eq!(first.food_name, "Chicken Breast");
    assert_eq!(first.food_type, "Generic");
    assert!(first.brand_name.is_none());

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
#[allow(clippy::expect_used, clippy::indexing_slicing, clippy::integer_division)]
fn test_search_response_pagination_calculation() {
    let json = load_fixture("search_response");
    let response: FoodSearchResponse = serde_json::from_str(&json)
        .and_then(|v: serde_json::Value| serde_json::from_value(v["foods"].clone()))
        .expect("Failed to deserialize search response");

    let total_pages = (response.total_results / response.max_results) + 1;
    let current_page = response.page_number + 1;

    assert_eq!(current_page, 1);
    assert_eq!(total_pages, 8);
}
