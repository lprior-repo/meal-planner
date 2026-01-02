//! Unit tests for the `FatSecret` Recipes domain

#![allow(clippy::unwrap_used)]
#![allow(clippy::expect_used)]
#![allow(clippy::panic)]

use super::types::*;
use serde_json;

// =============================================================================
// RecipeId Tests
// =============================================================================

#[test]
fn test_recipe_id_new() {
    let id = RecipeId::new("12345");
    assert_eq!(id.as_str(), "12345");
}

#[test]
fn test_recipe_id_from_string() {
    let id = RecipeId::new(String::from("67890"));
    assert_eq!(id.as_str(), "67890");
}

#[test]
fn test_recipe_id_from_str() {
    let id = RecipeId::from("12345");
    assert_eq!(id.as_str(), "12345");
}

#[test]
fn test_recipe_id_serialize() {
    let id = RecipeId::new("12345");
    let json = serde_json::to_string(&id).expect("should serialize");
    assert_eq!(json, r#""12345""#);
}

#[test]
fn test_recipe_id_deserialize() {
    let json = r#""12345""#;
    let id: RecipeId = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(id.as_str(), "12345");
}

#[test]
fn test_recipe_id_display() {
    let id = RecipeId::new("12345");
    let display = format!("{}", id);
    assert_eq!(display, "12345");
}

#[test]
fn test_recipe_id_equality() {
    let id1 = RecipeId::new("12345");
    let id2 = RecipeId::new("12345");
    let id3 = RecipeId::new("67890");
    assert_eq!(id1, id2);
    assert_ne!(id1, id3);
}

// =============================================================================
// Recipe Search Tests
// =============================================================================

#[test]
fn test_recipe_search_response() {
    let json = r#"{
        "recipes": {
            "recipe": [
                {
                    "recipe_id": "123",
                    "recipe_name": "Chicken Salad",
                    "recipe_description": "Healthy lunch option",
                    "recipe_url": "https://example.com/123"
                },
                {
                    "recipe_id": "456",
                    "recipe_name": "Banana Smoothie",
                    "recipe_description": "Quick breakfast",
                    "recipe_url": "https://example.com/456"
                }
            ],
            "max_results": "20",
            "total_results": "50",
            "page_number": "0"
        }
    }"#;
    let response: RecipeSearchResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.recipes.len(), 2);
    assert_eq!(response.total_results, 50);
    assert_eq!(response.page_number, 0);
}

#[test]
fn test_recipe_search_response_single() {
    let json = r#"{
        "recipes": {
            "recipe": {
                "recipe_id": "123",
                "recipe_name": "Single Recipe",
                "recipe_description": "Only one",
                "recipe_url": "https://example.com/123"
            },
            "max_results": 20,
            "total_results": 1,
            "page_number": 0
        }
    }"#;
    let response: RecipeSearchResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.recipes.len(), 1);
    assert_eq!(response.recipes[0].recipe_name, "Single Recipe");
}

#[test]
fn test_recipe_search_result_fields() {
    let json = r#"{
        "recipes": {
            "recipe": {
                "recipe_id": "999",
                "recipe_name": "Test Recipe",
                "recipe_description": "A test recipe",
                "recipe_url": "https://test.com"
            },
            "max_results": 10,
            "total_results": 1,
            "page_number": 0
        }
    }"#;
    let response: RecipeSearchResponse = serde_json::from_str(json).expect("should deserialize");
    let result = &response.recipes[0];
    assert_eq!(result.recipe_id.as_str(), "999");
    assert_eq!(result.recipe_name, "Test Recipe");
}

// =============================================================================
// Recipe Types Tests
// =============================================================================

#[test]
fn test_recipe_types_single() {
    let json = r#"{
        "recipe_types": {
            "recipe_type": {
                "recipe_type_code": "vegetarian",
                "recipe_type_name": "Vegetarian"
            }
        }
    }"#;
    let response: RecipeTypesResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.types.len(), 1);
    assert_eq!(response.types[0].recipe_type_code, "vegetarian");
    assert_eq!(response.types[0].recipe_type_name, "Vegetarian");
}

#[test]
fn test_recipe_types_array() {
    let json = r#"{
        "recipe_types": {
            "recipe_type": [
                {"recipe_type_code": "vegetarian", "recipe_type_name": "Vegetarian"},
                {"recipe_type_code": "main_dish", "recipe_type_name": "Main Dish"}
            ]
        }
    }"#;
    let response: RecipeTypesResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.types.len(), 2);
}

#[test]
fn test_recipe_type_from_api_string() {
    assert_eq!(RecipeType::from_api_string("vegetarian"), Some(RecipeType::Vegetarian));
    assert_eq!(RecipeType::from_api_string("main_dish"), Some(RecipeType::MainDish));
    assert_eq!(RecipeType::from_api_string("invalid"), None);
}

// =============================================================================
// Recipe Autocomplete Tests
// =============================================================================

#[test]
fn test_recipe_autocomplete_multiple() {
    let json = r#"{
        "suggestions": {
            "suggestion": [
                {"recipe_id": "1", "recipe_name": "Chicken Soup"},
                {"recipe_id": "2", "recipe_name": "Chicken Curry"}
            ]
        }
    }"#;
    let response: RecipeAutocompleteResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.suggestions.len(), 2);
    assert_eq!(response.suggestions[0].recipe_name, "Chicken Soup");
}

#[test]
fn test_recipe_autocomplete_single() {
    let json = r#"{
        "suggestions": {
            "suggestion": {"recipe_id": "1", "recipe_name": "Pasta"}
        }
    }"#;
    let response: RecipeAutocompleteResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.suggestions.len(), 1);
    assert_eq!(response.suggestions[0].recipe_name, "Pasta");
}

// =============================================================================
// Recipe Ingredient Tests
// =============================================================================

#[test]
fn test_recipe_ingredient_deserialize() {
    let json = r#"{
        "food_id": "123",
        "food_name": "Chicken Breast",
        "serving_id": "456",
        "number_of_units": "2.0",
        "measurement_description": "cup",
        "ingredient_description": "2 cups diced chicken breast",
        "ingredient_url": "https://example.com"
    }"#;
    let ingredient: RecipeIngredient = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(ingredient.food_id, "123");
    assert_eq!(ingredient.food_name, "Chicken Breast");
    assert_eq!(ingredient.serving_id, Some("456".to_string()));
    assert!((ingredient.number_of_units - 2.0).abs() < f64::EPSILON);
}

#[test]
fn test_recipe_ingredient_optional_fields() {
    let json = r#"{
        "food_id": "123",
        "food_name": "Salt",
        "number_of_units": "1.0",
        "measurement_description": "tsp",
        "ingredient_description": "1 tsp salt"
    }"#;
    let ingredient: RecipeIngredient = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(ingredient.serving_id, None);
    assert_eq!(ingredient.ingredient_url, None);
}

// =============================================================================
// Recipe Direction Tests
// =============================================================================

#[test]
fn test_recipe_direction_deserialize() {
    let json = r#"{
        "direction_number": "1",
        "direction_description": "Preheat oven to 350F"
    }"#;
    let direction: RecipeDirection = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(direction.direction_number, 1);
    assert_eq!(direction.direction_description, "Preheat oven to 350F");
}

#[test]
fn test_recipe_direction_numeric() {
    let json = r#"{
        "direction_number": 5,
        "direction_description": "Let it rest for 5 minutes"
    }"#;
    let direction: RecipeDirection = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(direction.direction_number, 5);
}

// =============================================================================
// Clone and Debug Tests
// =============================================================================

#[test]
fn test_recipe_id_clone() {
    let id1 = RecipeId::new("12345");
    let id2 = id1.clone();
    assert_eq!(id1, id2);
}

#[test]
fn test_recipe_search_result_clone() {
    let json = r#"{
        "recipes": {
            "recipe": {"recipe_id": "123", "recipe_name": "Test", "recipe_description": "", "recipe_url": "https://test.com"},
            "max_results": 10,
            "total_results": 1,
            "page_number": 0
        }
    }"#;
    let response: RecipeSearchResponse = serde_json::from_str(json).expect("should deserialize");
    let cloned = response.recipes[0].clone();
    assert_eq!(response.recipes[0].recipe_id, cloned.recipe_id);
}

#[test]
fn test_recipe_id_debug_format() {
    let id = RecipeId::new("12345");
    let debug = format!("{:?}", id);
    assert!(debug.contains("12345"));
}

// =============================================================================
// Edge Cases
// =============================================================================

#[test]
fn test_recipe_search_empty() {
    let json = r#"{
        "recipes": {
            "recipe": [],
            "max_results": "20",
            "total_results": "0",
            "page_number": "0"
        }
    }"#;
    let response: RecipeSearchResponse = serde_json::from_str(json).expect("should deserialize");
    assert!(response.recipes.is_empty());
}

#[test]
fn test_recipe_autocomplete_empty() {
    let json = r#"{"suggestions": {}}"#;
    let response: RecipeAutocompleteResponse = serde_json::from_str(json).expect("should deserialize");
    assert!(response.suggestions.is_empty());
}

#[test]
fn test_recipe_direction_large_number() {
    let json = r#"{
        "direction_number": 99,
        "direction_description": "Final step"
    }"#;
    let direction: RecipeDirection = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(direction.direction_number, 99);
}

#[test]
fn test_recipe_types_empty() {
    let json = r#"{"recipe_types": {}}"#;
    let response: RecipeTypesResponse = serde_json::from_str(json).expect("should deserialize");
    assert!(response.types.is_empty());
}

#[test]
fn test_recipe_ingredient_decimal_units() {
    let json = r#"{
        "food_id": "123",
        "food_name": "Sugar",
        "number_of_units": "0.5",
        "measurement_description": "cup",
        "ingredient_description": "0.5 cup sugar"
    }"#;
    let ingredient: RecipeIngredient = serde_json::from_str(json).expect("should deserialize");
    assert!((ingredient.number_of_units - 0.5).abs() < f64::EPSILON);
}

// =============================================================================
// Error Cases
// =============================================================================

#[test]
fn test_recipe_id_invalid_json() {
    let json = r#"not_a_string"#;
    let result: Result<RecipeId, _> = serde_json::from_str(json);
    assert!(result.is_err());
}

#[test]
fn test_recipe_direction_missing_number() {
    let json = r#"{"direction_description": "Test"}"#;
    let result: Result<RecipeDirection, _> = serde_json::from_str(json);
    assert!(result.is_err());
}
