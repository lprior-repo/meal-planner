//! Unit tests for the `FatSecret` Favorites domain
//!
//! Test coverage:
//! - FavoriteFood, MostEatenFood, RecentlyEatenFood deserialization
//! - FavoriteRecipe deserialization
//! - Response wrappers (single item vs array handling)
//! - MealFilter enum conversion
//! - Flexible numeric parsing

#![allow(clippy::unwrap_used)]
#![allow(clippy::expect_used)]
#![allow(clippy::panic)]

use super::types::*;
use serde_json;

// =============================================================================
// Test Fixtures
// =============================================================================

mod fixtures {
    pub const FAVORITE_FOOD_SINGLE: &str = r#"{
        "food": {
            "food_id": "12345",
            "food_name": "Banana",
            "food_type": "Generic",
            "food_description": "1 medium (118g)",
            "food_url": "https://www.fatsecret.com/banana",
            "serving_id": "67890",
            "number_of_units": "1.0"
        }
    }"#;

    pub const FAVORITE_FOOD_ARRAY: &str = r#"{
        "food": [
            {
                "food_id": "12345",
                "food_name": "Banana",
                "food_type": "Generic",
                "food_description": "1 medium (118g)",
                "food_url": "https://www.fatsecret.com/banana",
                "serving_id": "67890",
                "number_of_units": "1.0"
            },
            {
                "food_id": "54321",
                "food_name": "Apple",
                "food_type": "Generic",
                "brand_name": "Organic",
                "food_description": "1 medium (182g)",
                "food_url": "https://www.fatsecret.com/apple",
                "serving_id": "09876",
                "number_of_units": "1.0"
            }
        ]
    }"#;

    pub const FAVORITE_FOOD_BRAND: &str = r#"{
        "food": {
            "food_id": "99999",
            "food_name": "Special K Cereal",
            "food_type": "Brand",
            "brand_name": "Kellogg's",
            "food_description": "1 cup (30g)",
            "food_url": "https://www.fatsecret.com/specialk",
            "serving_id": "11111",
            "number_of_units": "1.0"
        }
    }"#;

    pub const MOST_EATEN_FOOD: &str = r#"{
        "food": {
            "food_id": "11111",
            "food_name": "Chicken Breast",
            "food_type": "Generic",
            "food_description": "100g",
            "food_url": "https://www.fatsecret.com/chicken",
            "serving_id": "22222",
            "number_of_units": "1.5"
        }
    }"#;

    pub const RECENTLY_EATEN_FOOD: &str = r#"{
        "food": {
            "food_id": "33333",
            "food_name": "Greek Yogurt",
            "food_type": "Generic",
            "food_description": "1 cup (245g)",
            "food_url": "https://www.fatsecret.com/yogurt",
            "serving_id": "44444",
            "number_of_units": "1.0"
        }
    }"#;

    pub const FAVORITE_RECIPE_SINGLE: &str = r#"{
        "recipe": {
            "recipe_id": "123",
            "recipe_name": "Grilled Chicken Salad",
            "recipe_description": "Healthy lunch option",
            "recipe_url": "https://www.fatsecret.com/recipe/123",
            "recipe_image": "https://example.com/image.jpg"
        }
    }"#;

    pub const FAVORITE_RECIPE_ARRAY: &str = r#"{
        "recipe": [
            {
                "recipe_id": "123",
                "recipe_name": "Grilled Chicken Salad",
                "recipe_description": "Healthy lunch option",
                "recipe_url": "https://www.fatsecret.com/recipe/123",
                "recipe_image": "https://example.com/image.jpg"
            },
            {
                "recipe_id": "456",
                "recipe_name": "Banana Smoothie",
                "recipe_description": "Quick breakfast",
                "recipe_url": "https://www.fatsecret.com/recipe/456"
            }
        ]
    }"#;
}

// =============================================================================
// FavoriteFood Tests
// =============================================================================

#[test]
fn test_favorite_food_deserialize_single() {
    let response: FavoriteFoodsResponse =
        serde_json::from_str(fixtures::FAVORITE_FOOD_SINGLE).expect("should deserialize");

    assert_eq!(response.foods.len(), 1);
    let food = &response.foods[0];
    assert_eq!(food.food_id, "12345");
    assert_eq!(food.food_name, "Banana");
    assert_eq!(food.food_type, "Generic");
    assert_eq!(food.brand_name, None);
    assert!((food.number_of_units - 1.0).abs() < f64::EPSILON);
}

#[test]
fn test_favorite_food_deserialize_array() {
    let response: FavoriteFoodsResponse =
        serde_json::from_str(fixtures::FAVORITE_FOOD_ARRAY).expect("should deserialize");

    assert_eq!(response.foods.len(), 2);
    assert_eq!(response.foods[0].food_name, "Banana");
    assert_eq!(response.foods[1].food_name, "Apple");
}

#[test]
fn test_favorite_food_deserialize_brand() {
    let response: FavoriteFoodsResponse =
        serde_json::from_str(fixtures::FAVORITE_FOOD_BRAND).expect("should deserialize");

    assert_eq!(response.foods.len(), 1);
    let food = &response.foods[0];
    assert_eq!(food.food_type, "Brand");
    assert_eq!(food.brand_name, Some("Kellogg's".to_string()));
}

#[test]
fn test_favorite_food_numeric_units() {
    let json = r#"{
        "food": {
            "food_id": "123",
            "food_name": "Test",
            "food_type": "Generic",
            "food_description": "Test",
            "food_url": "https://test.com",
            "serving_id": "456",
            "number_of_units": 2.5
        }
    }"#;
    let response: FavoriteFoodsResponse = serde_json::from_str(json).expect("should deserialize");
    assert!((response.foods[0].number_of_units - 2.5).abs() < f64::EPSILON);
}

#[test]
fn test_favorite_food_string_units() {
    let json = r#"{
        "food": {
            "food_id": "123",
            "food_name": "Test",
            "food_type": "Generic",
            "food_description": "Test",
            "food_url": "https://test.com",
            "serving_id": "456",
            "number_of_units": "2.5"
        }
    }"#;
    let response: FavoriteFoodsResponse = serde_json::from_str(json).expect("should deserialize");
    assert!((response.foods[0].number_of_units - 2.5).abs() < f64::EPSILON);
}

// =============================================================================
// MostEatenFood Tests
// =============================================================================

#[test]
fn test_most_eaten_food_deserialize() {
    let response: MostEatenResponse =
        serde_json::from_str(fixtures::MOST_EATEN_FOOD).expect("should deserialize");

    assert_eq!(response.foods.len(), 1);
    let food = &response.foods[0];
    assert_eq!(food.food_id, "11111");
    assert_eq!(food.food_name, "Chicken Breast");
    assert!((food.number_of_units - 1.5).abs() < f64::EPSILON);
}

#[test]
fn test_most_eaten_food_array() {
    let json = r#"{
        "food": [
            {"food_id": "1", "food_name": "A", "food_type": "Generic", "food_description": "", "food_url": "https://a.com", "serving_id": "s1", "number_of_units": 1.0},
            {"food_id": "2", "food_name": "B", "food_type": "Generic", "food_description": "", "food_url": "https://b.com", "serving_id": "s2", "number_of_units": 2.0}
        ]
    }"#;
    let response: MostEatenResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.foods.len(), 2);
}

// =============================================================================
// RecentlyEatenFood Tests
// =============================================================================

#[test]
fn test_recently_eaten_food_deserialize() {
    let response: RecentlyEatenResponse =
        serde_json::from_str(fixtures::RECENTLY_EATEN_FOOD).expect("should deserialize");

    assert_eq!(response.foods.len(), 1);
    let food = &response.foods[0];
    assert_eq!(food.food_id, "33333");
    assert_eq!(food.food_name, "Greek Yogurt");
}

#[test]
fn test_recently_eaten_food_array() {
    let json = r#"{
        "food": [
            {"food_id": "1", "food_name": "A", "food_type": "Generic", "food_description": "", "food_url": "https://a.com", "serving_id": "s1", "number_of_units": 1.0},
            {"food_id": "2", "food_name": "B", "food_type": "Generic", "food_description": "", "food_url": "https://b.com", "serving_id": "s2", "number_of_units": 1.0},
            {"food_id": "3", "food_name": "C", "food_type": "Generic", "food_description": "", "food_url": "https://c.com", "serving_id": "s3", "number_of_units": 1.0}
        ]
    }"#;
    let response: RecentlyEatenResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.foods.len(), 3);
}

// =============================================================================
// FavoriteRecipe Tests
// =============================================================================

#[test]
fn test_favorite_recipe_single() {
    let response: FavoriteRecipesResponse =
        serde_json::from_str(fixtures::FAVORITE_RECIPE_SINGLE).expect("should deserialize");

    assert_eq!(response.recipes.len(), 1);
    let recipe = &response.recipes[0];
    assert_eq!(recipe.recipe_id, "123");
    assert_eq!(recipe.recipe_name, "Grilled Chicken Salad");
    assert_eq!(recipe.recipe_image, Some("https://example.com/image.jpg".to_string()));
}

#[test]
fn test_favorite_recipe_array() {
    let response: FavoriteRecipesResponse =
        serde_json::from_str(fixtures::FAVORITE_RECIPE_ARRAY).expect("should deserialize");

    assert_eq!(response.recipes.len(), 2);
    assert_eq!(response.recipes[0].recipe_name, "Grilled Chicken Salad");
    assert_eq!(response.recipes[1].recipe_name, "Banana Smoothie");
}

#[test]
fn test_favorite_recipe_missing_image() {
    let json = r#"{
        "recipe": {
            "recipe_id": "789",
            "recipe_name": "Test Recipe",
            "recipe_description": "Test",
            "recipe_url": "https://test.com"
        }
    }"#;
    let response: FavoriteRecipesResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.recipes[0].recipe_image, None);
}

// =============================================================================
// MealFilter Tests
// =============================================================================

#[test]
fn test_meal_filter_to_api_string() {
    assert_eq!(MealFilter::All.to_api_string(), "all");
    assert_eq!(MealFilter::Breakfast.to_api_string(), "breakfast");
    assert_eq!(MealFilter::Lunch.to_api_string(), "lunch");
    assert_eq!(MealFilter::Dinner.to_api_string(), "dinner");
    assert_eq!(MealFilter::Snack.to_api_string(), "snack");
}

#[test]
fn test_meal_filter_from_api_string() {
    assert_eq!(MealFilter::from_api_string("all"), Some(MealFilter::All));
    assert_eq!(MealFilter::from_api_string("breakfast"), Some(MealFilter::Breakfast));
    assert_eq!(MealFilter::from_api_string("lunch"), Some(MealFilter::Lunch));
    assert_eq!(MealFilter::from_api_string("dinner"), Some(MealFilter::Dinner));
    assert_eq!(MealFilter::from_api_string("snack"), Some(MealFilter::Snack));
}

#[test]
fn test_meal_filter_from_api_string_invalid() {
    assert_eq!(MealFilter::from_api_string("invalid"), None);
    assert_eq!(MealFilter::from_api_string(""), None);
}

#[test]
fn test_meal_filter_roundtrip() {
    for filter in [MealFilter::All, MealFilter::Breakfast, MealFilter::Lunch, MealFilter::Dinner, MealFilter::Snack] {
        let s = filter.to_api_string();
        let parsed = MealFilter::from_api_string(s).unwrap();
        assert_eq!(filter, parsed);
    }
}

#[test]
fn test_meal_filter_display() {
    assert_eq!(format!("{}", MealFilter::All), "all");
    assert_eq!(format!("{}", MealFilter::Breakfast), "breakfast");
}

// =============================================================================
// Clone and Debug Tests
// =============================================================================

#[test]
fn test_favorite_food_clone() {
    let response: FavoriteFoodsResponse =
        serde_json::from_str(fixtures::FAVORITE_FOOD_SINGLE).expect("should deserialize");
    let cloned = response.foods[0].clone();
    assert_eq!(response.foods[0].food_id, cloned.food_id);
    assert_eq!(response.foods[0].food_name, cloned.food_name);
}

#[test]
fn test_favorite_recipe_clone() {
    let response: FavoriteRecipesResponse =
        serde_json::from_str(fixtures::FAVORITE_RECIPE_SINGLE).expect("should deserialize");
    let cloned = response.recipes[0].clone();
    assert_eq!(response.recipes[0].recipe_id, cloned.recipe_id);
}

#[test]
fn test_favorite_food_debug_format() {
    let response: FavoriteFoodsResponse =
        serde_json::from_str(fixtures::FAVORITE_FOOD_SINGLE).expect("should deserialize");
    let debug = format!("{:?}", response.foods[0]);
    assert!(debug.contains("Banana"));
    assert!(debug.contains("12345"));
}

// =============================================================================
// Edge Cases
// =============================================================================

#[test]
fn test_empty_response() {
    let json = r#"{}"#;
    let response: FavoriteFoodsResponse = serde_json::from_str(json).expect("should deserialize");
    assert!(response.foods.is_empty());
}

#[test]
fn test_empty_array_response() {
    let json = r#"{"food": []}"#;
    let response: FavoriteFoodsResponse = serde_json::from_str(json).expect("should deserialize");
    assert!(response.foods.is_empty());
}

#[test]
fn test_favorite_food_special_characters() {
    let json = r#"{
        "food": {
            "food_id": "123",
            "food_name": " Häagen-Dazs® ",
            "food_type": "Brand",
            "brand_name": "Unilever",
            "food_description": "Ice Cream",
            "food_url": "https://test.com",
            "serving_id": "456",
            "number_of_units": 1.0
        }
    }"#;
    let response: FavoriteFoodsResponse = serde_json::from_str(json).expect("should deserialize");
    assert!(response.foods[0].food_name.contains("Häagen-Dazs"));
}

#[test]
fn test_favorite_food_unicode() {
    let json = r#"{
        "food": {
            "food_id": "123",
            "food_name": "拉面",
            "food_type": "Generic",
            "food_description": "Ramen",
            "food_url": "https://test.com",
            "serving_id": "456",
            "number_of_units": 1.0
        }
    }"#;
    let response: FavoriteFoodsResponse = serde_json::from_str(json).expect("should deserialize");
    assert_eq!(response.foods[0].food_name, "拉面");
}

// =============================================================================
// Error Cases
// =============================================================================

#[test]
fn test_favorite_food_missing_required_field() {
    let json = r#"{
        "food": [{
            "food_name": "Banana",
            "food_type": "Generic"
        }]
    }"#;
    let result: Result<FavoriteFoodsResponse, _> = serde_json::from_str(json);
    assert!(result.is_err());
}
