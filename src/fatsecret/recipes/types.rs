//! `FatSecret` Recipe API domain types.
//!
//! This module defines the type system for `FatSecret` Recipe API responses.
//! All types are designed for robust deserialization of the `FatSecret` API's
//! sometimes-inconsistent JSON format.
//!
//! # Key Types
//!
//! ## Core Domain Types
//!
//! - [`Recipe`] - Complete recipe with ingredients, directions, and nutrition facts
//! - [`RecipeId`] - Type-safe opaque wrapper for recipe identifiers
//! - [`RecipeIngredient`] - Single ingredient with quantity and food ID
//! - [`RecipeDirection`] - Numbered cooking step/instruction
//!
//! ## Search & Discovery
//!
//! - [`RecipeSearchResult`] - Lightweight recipe summary from search
//! - [`RecipeSearchResponse`] - Paginated search results with metadata
//! - [`RecipeSuggestion`] - Autocomplete suggestion for recipe names
//! - [`RecipeType`] - Recipe category/classification (e.g., "Vegetarian", "Main Dish")
//!
//! ## Wrapper Types
//!
//! The API uses inconsistent nesting and can return single items or arrays.
//! Wrapper types handle this with custom deserializers:
//!
//! - [`RecipeTypesWrapper`] - Handles `recipe_type` as string or array
//! - [`RecipeIngredientsWrapper`] - Handles `ingredient` as object or array
//! - [`RecipeDirectionsWrapper`] - Handles `direction` as object or array
//!
//! # Usage Example
//!
//! ```no_run
//! use meal_planner::fatsecret::recipes::types::{Recipe, RecipeId, RecipeIngredient};
//!
//! # fn example(recipe: Recipe) {
//! // Access recipe metadata
//! println!("Recipe: {}", recipe.recipe_name);
//! println!("ID: {}", recipe.`recipe_id`);
//! println!("Servings: {}", recipe.number_of_servings);
//!
//! // Iterate over ingredients
//! for ingredient in &recipe.ingredients.ingredients {
//!     println!(
//!         "- {} {} {}",
//!         ingredient.number_of_units,
//!         ingredient.measurement_description,
//!         ingredient.food_name
//!     );
//! }
//!
//! // Iterate over cooking steps
//! for direction in &recipe.directions.directions {
//!     println!("{}. {}", direction.direction_number, direction.direction_description);
//! }
//!
//! // Access nutrition data (all optional)
//! if let Some(cal) = recipe.calories {
//!     println!("Calories per serving: {}", cal);
//! }
//! # }
//! ```
//!
//! # Flexible Deserialization
//!
//! The `FatSecret` API returns numeric values as both strings and numbers.
//! This module uses custom deserializers from [`crate::fatsecret::core::serde_utils`]:
//!
//! - `deserialize_flexible_int` - Accepts "123" or 123
//! - `deserialize_flexible_float` - Accepts "12.5" or 12.5
//! - `deserialize_single_or_vec` - Accepts single item or array
//!
//! This ensures robust parsing regardless of API response format variations.

use crate::fatsecret::core::serde_utils::{
    deserialize_flexible_float, deserialize_flexible_int, deserialize_optional_flexible_float,
    deserialize_optional_flexible_int, deserialize_single_or_vec,
};
use serde::{Deserialize, Serialize};

// ============================================================================
// Opaque ID Types
// ============================================================================

/// Opaque type for `FatSecret` recipe IDs
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct RecipeId(String);

impl RecipeId {
    /// Creates a new `RecipeId` from any string-like value
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    /// Returns the recipe ID as a string slice
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl From<String> for RecipeId {
    fn from(s: String) -> Self {
        Self(s)
    }
}

impl From<&str> for RecipeId {
    fn from(s: &str) -> Self {
        Self(s.to_string())
    }
}

impl std::fmt::Display for RecipeId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

// ============================================================================
// Recipe Domain Types
// ============================================================================

/// Ingredient in a recipe
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipeIngredient {
    /// `FatSecret` food ID for this ingredient
    pub food_id: String,
    /// Name of the food item
    pub food_name: String,
    /// Optional serving ID for portion tracking
    pub serving_id: Option<String>,
    /// Quantity of the ingredient in the specified units
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_units: f64,
    /// Unit of measurement (e.g., "cup", "tbsp", "oz")
    pub measurement_description: String,
    /// Full description of the ingredient as displayed in the recipe
    pub ingredient_description: String,
    /// Optional URL to the ingredient details on `FatSecret`
    pub ingredient_url: Option<String>,
}

/// Direction/step in recipe preparation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipeDirection {
    /// Step number in the cooking sequence (1-indexed)
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub direction_number: i32,
    /// Instructions for this step
    pub direction_description: String,
}

/// Recipe category/type
pub type RecipeType = String;

/// Complete recipe details
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Recipe {
    /// Unique recipe ID from `FatSecret`
    pub recipe_id: RecipeId,
    /// Name of the recipe
    pub recipe_name: String,
    /// URL to the recipe on `FatSecret` website
    pub recipe_url: String,
    /// Brief description of the recipe
    pub recipe_description: String,
    /// Optional URL to the recipe image
    pub recipe_image: Option<String>,
    /// Number of servings the recipe yields
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_servings: f64,
    /// Preparation time in minutes (before cooking)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_int")]
    pub preparation_time_min: Option<i32>,
    /// Cooking time in minutes
    #[serde(default, deserialize_with = "deserialize_optional_flexible_int")]
    pub cooking_time_min: Option<i32>,
    /// User rating (0-5 scale)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub rating: Option<f64>,

    /// Recipe categories/types (e.g., "Main Dish", "Vegetarian")
    #[serde(rename = "recipe_types", default)]
    pub recipe_types: RecipeTypesWrapper,

    /// List of ingredients required for the recipe
    #[serde(rename = "ingredients", default)]
    pub ingredients: RecipeIngredientsWrapper,

    /// Step-by-step cooking directions
    #[serde(rename = "directions", default)]
    pub directions: RecipeDirectionsWrapper,

    /// Calories per serving (kcal)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub calories: Option<f64>,
    /// Carbohydrates per serving (g)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub carbohydrate: Option<f64>,
    /// Protein per serving (g)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub protein: Option<f64>,
    /// Total fat per serving (g)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub fat: Option<f64>,
    /// Saturated fat per serving (g)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub saturated_fat: Option<f64>,
    /// Polyunsaturated fat per serving (g)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub polyunsaturated_fat: Option<f64>,
    /// Monounsaturated fat per serving (g)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub monounsaturated_fat: Option<f64>,
    /// Cholesterol per serving (mg)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub cholesterol: Option<f64>,
    /// Sodium per serving (mg)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub sodium: Option<f64>,
    /// Potassium per serving (mg)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub potassium: Option<f64>,
    /// Dietary fiber per serving (g)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub fiber: Option<f64>,
    /// Sugar per serving (g)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub sugar: Option<f64>,
    /// Vitamin A per serving (% daily value)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub vitamin_a: Option<f64>,
    /// Vitamin C per serving (% daily value)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub vitamin_c: Option<f64>,
    /// Calcium per serving (% daily value)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub calcium: Option<f64>,
    /// Iron per serving (% daily value)
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub iron: Option<f64>,
}

/// Wrapper for deserializing recipe types from `FatSecret` API
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RecipeTypesWrapper {
    /// List of recipe type/category names
    #[serde(
        rename = "recipe_type",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub recipe_types: Vec<RecipeType>,
}

/// Wrapper for deserializing ingredients from `FatSecret` API
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RecipeIngredientsWrapper {
    /// List of recipe ingredients
    #[serde(
        rename = "ingredient",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub ingredients: Vec<RecipeIngredient>,
}

/// Wrapper for deserializing directions from `FatSecret` API
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RecipeDirectionsWrapper {
    /// List of cooking directions/steps
    #[serde(
        rename = "direction",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub directions: Vec<RecipeDirection>,
}

/// Recipe search result item
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipeSearchResult {
    /// Unique recipe ID from `FatSecret`
    pub recipe_id: RecipeId,
    /// Name of the recipe
    pub recipe_name: String,
    /// Brief description of the recipe
    pub recipe_description: String,
    /// URL to the recipe on `FatSecret` website
    pub recipe_url: String,
    /// Optional URL to the recipe image
    pub recipe_image: Option<String>,
}

/// Response from recipes.search.v3
#[derive(Debug, Deserialize, Serialize)]
pub struct RecipeSearchResponse {
    /// List of matching recipes
    #[serde(
        rename = "recipe",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub recipes: Vec<RecipeSearchResult>,
    /// Maximum results per page
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub max_results: i32,
    /// Total number of matching recipes
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub total_results: i32,
    /// Current page number (0-indexed)
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub page_number: i32,
}

/// Response from `recipe_types.get.v2`
#[derive(Debug, Deserialize)]
pub struct RecipeTypesResponse {
    /// List of available recipe types/categories
    #[serde(
        rename = "recipe_type",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub recipe_types: Vec<RecipeType>,
}

/// Single recipe autocomplete suggestion
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipeSuggestion {
    /// Unique recipe ID from `FatSecret`
    pub recipe_id: RecipeId,
    /// Name of the suggested recipe
    pub recipe_name: String,
}

/// Response from recipes.autocomplete.v2 API
#[derive(Debug, Deserialize)]
pub struct RecipeAutocompleteResponse {
    /// List of autocomplete suggestions
    #[serde(
        rename = "suggestion",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub suggestions: Vec<RecipeSuggestion>,
}

/// Wrapper for Recipe response (recipe.get.v2)
#[derive(Debug, Deserialize)]
pub struct RecipeResponseWrapper {
    /// The recipe details
    pub recipe: Recipe,
}

/// Wrapper for Search response
#[derive(Debug, Deserialize)]
pub struct RecipeSearchResponseWrapper {
    /// The search response containing results and pagination
    pub recipes: RecipeSearchResponse,
}

/// Wrapper for Autocomplete response
#[derive(Debug, Deserialize)]
pub struct RecipeAutocompleteResponseWrapper {
    /// The autocomplete response containing suggestions
    pub suggestions: RecipeAutocompleteResponse,
}

/// Wrapper for Recipe Types response
#[derive(Debug, Deserialize)]
pub struct RecipeTypesResponseWrapper {
    /// The response containing available recipe types
    pub recipe_types: RecipeTypesResponse,
}

#[cfg(test)]
mod tests {
    use super::*;

    // ============================================================================
    // RecipeId tests
    // ============================================================================

    #[test]
    fn test_recipe_id_new() {
        let id = RecipeId::new("12345");
        assert_eq!(id.as_str(), "12345");
    }

    #[test]
    fn test_recipe_id_from_string() {
        let id: RecipeId = String::from("67890").into();
        assert_eq!(id.as_str(), "67890");
    }

    #[test]
    fn test_recipe_id_from_str() {
        let id: RecipeId = "abc123".into();
        assert_eq!(id.as_str(), "abc123");
    }

    #[test]
    fn test_recipe_id_display() {
        let id = RecipeId::new("recipe-id");
        assert_eq!(format!("{}", id), "recipe-id");
    }

    #[test]
    fn test_recipe_id_equality() {
        let id1 = RecipeId::new("same");
        let id2 = RecipeId::new("same");
        let id3 = RecipeId::new("different");
        assert_eq!(id1, id2);
        assert_ne!(id1, id3);
    }

    #[test]
    fn test_recipe_id_hash() {
        use std::collections::HashSet;
        let mut set = HashSet::new();
        set.insert(RecipeId::new("id1"));
        set.insert(RecipeId::new("id2"));
        set.insert(RecipeId::new("id1")); // duplicate
        assert_eq!(set.len(), 2);
    }

    #[test]
    fn test_recipe_id_serde() {
        let id = RecipeId::new("serde-test");
        let json = serde_json::to_string(&id).unwrap();
        assert_eq!(json, "\"serde-test\"");
        let parsed: RecipeId = serde_json::from_str(&json).unwrap();
        assert_eq!(id, parsed);
    }

    // ============================================================================
    // RecipeIngredient tests
    // ============================================================================

    #[test]
    fn test_recipe_ingredient_deserialize() {
        let json = r#"{
            "food_id": "123",
            "food_name": "Flour",
            "number_of_units": "2.5",
            "measurement_description": "cups",
            "ingredient_description": "2.5 cups all-purpose flour"
        }"#;
        let ingredient: RecipeIngredient = serde_json::from_str(json).unwrap();
        assert_eq!(ingredient.food_id, "123");
        assert_eq!(ingredient.food_name, "Flour");
        assert!((ingredient.number_of_units - 2.5).abs() < 0.01);
        assert_eq!(ingredient.measurement_description, "cups");
        assert!(ingredient.serving_id.is_none());
        assert!(ingredient.ingredient_url.is_none());
    }

    #[test]
    fn test_recipe_ingredient_with_optional_fields() {
        let json = r#"{
            "food_id": "456",
            "food_name": "Sugar",
            "serving_id": "789",
            "number_of_units": 1.0,
            "measurement_description": "tbsp",
            "ingredient_description": "1 tablespoon sugar",
            "ingredient_url": "https://fatsecret.com/ingredient/456"
        }"#;
        let ingredient: RecipeIngredient = serde_json::from_str(json).unwrap();
        assert_eq!(ingredient.serving_id, Some("789".to_string()));
        assert_eq!(
            ingredient.ingredient_url,
            Some("https://fatsecret.com/ingredient/456".to_string())
        );
    }

    // ============================================================================
    // RecipeDirection tests
    // ============================================================================

    #[test]
    fn test_recipe_direction_deserialize() {
        let json = r#"{
            "direction_number": "1",
            "direction_description": "Preheat oven to 350°F"
        }"#;
        let direction: RecipeDirection = serde_json::from_str(json).unwrap();
        assert_eq!(direction.direction_number, 1);
        assert_eq!(direction.direction_description, "Preheat oven to 350°F");
    }

    #[test]
    fn test_recipe_direction_numeric_number() {
        let json = r#"{
            "direction_number": 2,
            "direction_description": "Mix ingredients"
        }"#;
        let direction: RecipeDirection = serde_json::from_str(json).unwrap();
        assert_eq!(direction.direction_number, 2);
    }

    // ============================================================================
    // Wrapper tests
    // ============================================================================

    #[test]
    fn test_recipe_types_wrapper_single() {
        let json = r#"{
            "recipe_type": "Dessert"
        }"#;
        let wrapper: RecipeTypesWrapper = serde_json::from_str(json).unwrap();
        assert_eq!(wrapper.recipe_types.len(), 1);
        assert_eq!(wrapper.recipe_types[0], "Dessert");
    }

    #[test]
    fn test_recipe_types_wrapper_multiple() {
        let json = r#"{
            "recipe_type": ["Dessert", "Vegetarian", "Quick & Easy"]
        }"#;
        let wrapper: RecipeTypesWrapper = serde_json::from_str(json).unwrap();
        assert_eq!(wrapper.recipe_types.len(), 3);
    }

    #[test]
    fn test_recipe_types_wrapper_empty() {
        let json = r#"{}"#;
        let wrapper: RecipeTypesWrapper = serde_json::from_str(json).unwrap();
        assert!(wrapper.recipe_types.is_empty());
    }

    #[test]
    fn test_recipe_ingredients_wrapper_single() {
        let json = r#"{
            "ingredient": {
                "food_id": "1",
                "food_name": "Egg",
                "number_of_units": "1",
                "measurement_description": "large",
                "ingredient_description": "1 large egg"
            }
        }"#;
        let wrapper: RecipeIngredientsWrapper = serde_json::from_str(json).unwrap();
        assert_eq!(wrapper.ingredients.len(), 1);
    }

    #[test]
    fn test_recipe_directions_wrapper_multiple() {
        let json = r#"{
            "direction": [
                {"direction_number": "1", "direction_description": "Step 1"},
                {"direction_number": "2", "direction_description": "Step 2"}
            ]
        }"#;
        let wrapper: RecipeDirectionsWrapper = serde_json::from_str(json).unwrap();
        assert_eq!(wrapper.directions.len(), 2);
    }

    // ============================================================================
    // RecipeSearchResult tests
    // ============================================================================

    #[test]
    fn test_recipe_search_result_deserialize() {
        let json = r#"{
            "recipe_id": "12345",
            "recipe_name": "Chocolate Cake",
            "recipe_description": "A delicious chocolate cake",
            "recipe_url": "https://fatsecret.com/recipe/12345"
        }"#;
        let result: RecipeSearchResult = serde_json::from_str(json).unwrap();
        assert_eq!(result.recipe_id.as_str(), "12345");
        assert_eq!(result.recipe_name, "Chocolate Cake");
        assert!(result.recipe_image.is_none());
    }

    #[test]
    fn test_recipe_search_result_with_image() {
        let json = r#"{
            "recipe_id": "12345",
            "recipe_name": "Cake",
            "recipe_description": "A cake",
            "recipe_url": "https://fatsecret.com/recipe/12345",
            "recipe_image": "https://fatsecret.com/images/12345.jpg"
        }"#;
        let result: RecipeSearchResult = serde_json::from_str(json).unwrap();
        assert!(result.recipe_image.is_some());
    }

    // ============================================================================
    // RecipeSearchResponse tests
    // ============================================================================

    #[test]
    fn test_recipe_search_response() {
        let json = r#"{
            "recipe": [
                {
                    "recipe_id": "1",
                    "recipe_name": "Recipe 1",
                    "recipe_description": "Desc 1",
                    "recipe_url": "https://example.com/1"
                },
                {
                    "recipe_id": "2",
                    "recipe_name": "Recipe 2",
                    "recipe_description": "Desc 2",
                    "recipe_url": "https://example.com/2"
                }
            ],
            "max_results": "20",
            "total_results": "100",
            "page_number": "0"
        }"#;
        let response: RecipeSearchResponse = serde_json::from_str(json).unwrap();
        assert_eq!(response.recipes.len(), 2);
        assert_eq!(response.max_results, 20);
        assert_eq!(response.total_results, 100);
        assert_eq!(response.page_number, 0);
    }

    #[test]
    fn test_recipe_search_response_numeric() {
        let json = r#"{
            "recipe": [],
            "max_results": 10,
            "total_results": 0,
            "page_number": 0
        }"#;
        let response: RecipeSearchResponse = serde_json::from_str(json).unwrap();
        assert!(response.recipes.is_empty());
        assert_eq!(response.max_results, 10);
    }

    // ============================================================================
    // RecipeTypesResponse tests
    // ============================================================================

    #[test]
    fn test_recipe_types_response() {
        let json = r#"{
            "recipe_type": ["Appetizer", "Main Dish", "Dessert", "Side Dish"]
        }"#;
        let response: RecipeTypesResponse = serde_json::from_str(json).unwrap();
        assert_eq!(response.recipe_types.len(), 4);
    }

    // ============================================================================
    // RecipeSuggestion tests
    // ============================================================================

    #[test]
    fn test_recipe_suggestion() {
        let json = r#"{
            "recipe_id": "999",
            "recipe_name": "Chicken Parmesan"
        }"#;
        let suggestion: RecipeSuggestion = serde_json::from_str(json).unwrap();
        assert_eq!(suggestion.recipe_id.as_str(), "999");
        assert_eq!(suggestion.recipe_name, "Chicken Parmesan");
    }

    // ============================================================================
    // RecipeAutocompleteResponse tests
    // ============================================================================

    #[test]
    fn test_recipe_autocomplete_response() {
        let json = r#"{
            "suggestion": [
                {"recipe_id": "1", "recipe_name": "Chicken Alfredo"},
                {"recipe_id": "2", "recipe_name": "Chicken Curry"}
            ]
        }"#;
        let response: RecipeAutocompleteResponse = serde_json::from_str(json).unwrap();
        assert_eq!(response.suggestions.len(), 2);
    }

    // ============================================================================
    // Response wrapper tests
    // ============================================================================

    #[test]
    fn test_recipe_search_response_wrapper() {
        let json = r#"{
            "recipes": {
                "recipe": [],
                "max_results": "10",
                "total_results": "0",
                "page_number": "0"
            }
        }"#;
        let wrapper: RecipeSearchResponseWrapper = serde_json::from_str(json).unwrap();
        assert!(wrapper.recipes.recipes.is_empty());
    }

    #[test]
    fn test_recipe_autocomplete_response_wrapper() {
        let json = r#"{
            "suggestions": {
                "suggestion": []
            }
        }"#;
        let wrapper: RecipeAutocompleteResponseWrapper = serde_json::from_str(json).unwrap();
        assert!(wrapper.suggestions.suggestions.is_empty());
    }

    #[test]
    fn test_recipe_types_response_wrapper() {
        let json = r#"{
            "recipe_types": {
                "recipe_type": ["Breakfast", "Lunch"]
            }
        }"#;
        let wrapper: RecipeTypesResponseWrapper = serde_json::from_str(json).unwrap();
        assert_eq!(wrapper.recipe_types.recipe_types.len(), 2);
    }

    // ============================================================================
    // Recipe (full) tests
    // ============================================================================

    #[test]
    fn test_recipe_minimal() {
        let json = r#"{
            "recipe_id": "12345",
            "recipe_name": "Simple Recipe",
            "recipe_url": "https://fatsecret.com/recipe/12345",
            "recipe_description": "A simple recipe",
            "number_of_servings": "4"
        }"#;
        let recipe: Recipe = serde_json::from_str(json).unwrap();
        assert_eq!(recipe.recipe_id.as_str(), "12345");
        assert_eq!(recipe.recipe_name, "Simple Recipe");
        assert!((recipe.number_of_servings - 4.0).abs() < 0.01);
        assert!(recipe.recipe_image.is_none());
        assert!(recipe.preparation_time_min.is_none());
        assert!(recipe.cooking_time_min.is_none());
        assert!(recipe.rating.is_none());
        assert!(recipe.calories.is_none());
    }

    #[test]
    fn test_recipe_with_times() {
        let json = r#"{
            "recipe_id": "12345",
            "recipe_name": "Recipe with times",
            "recipe_url": "https://example.com",
            "recipe_description": "Desc",
            "number_of_servings": "2",
            "preparation_time_min": "15",
            "cooking_time_min": "30"
        }"#;
        let recipe: Recipe = serde_json::from_str(json).unwrap();
        assert_eq!(recipe.preparation_time_min, Some(15));
        assert_eq!(recipe.cooking_time_min, Some(30));
    }

    #[test]
    fn test_recipe_with_nutrition() {
        let json = r#"{
            "recipe_id": "12345",
            "recipe_name": "Nutritious Recipe",
            "recipe_url": "https://example.com",
            "recipe_description": "Desc",
            "number_of_servings": "2",
            "calories": "350",
            "carbohydrate": "45.5",
            "protein": "25",
            "fat": "12.3"
        }"#;
        let recipe: Recipe = serde_json::from_str(json).unwrap();
        assert!((recipe.calories.unwrap() - 350.0).abs() < 0.01);
        assert!((recipe.carbohydrate.unwrap() - 45.5).abs() < 0.01);
        assert!((recipe.protein.unwrap() - 25.0).abs() < 0.01);
        assert!((recipe.fat.unwrap() - 12.3).abs() < 0.01);
    }

    #[test]
    fn test_recipe_with_rating() {
        let json = r#"{
            "recipe_id": "12345",
            "recipe_name": "Rated Recipe",
            "recipe_url": "https://example.com",
            "recipe_description": "Desc",
            "number_of_servings": 4,
            "rating": 4.5
        }"#;
        let recipe: Recipe = serde_json::from_str(json).unwrap();
        assert!((recipe.rating.unwrap() - 4.5).abs() < 0.01);
    }

    #[test]
    fn test_recipe_response_wrapper() {
        let json = r#"{
            "recipe": {
                "recipe_id": "12345",
                "recipe_name": "Wrapped Recipe",
                "recipe_url": "https://example.com",
                "recipe_description": "Desc",
                "number_of_servings": "1"
            }
        }"#;
        let wrapper: RecipeResponseWrapper = serde_json::from_str(json).unwrap();
        assert_eq!(wrapper.recipe.recipe_name, "Wrapped Recipe");
    }
}
