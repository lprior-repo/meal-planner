//! FatSecret Recipe domain types

use crate::fatsecret::core::serde_utils::{
    deserialize_flexible_float, deserialize_flexible_int, deserialize_optional_flexible_float,
    deserialize_optional_flexible_int, deserialize_single_or_vec,
};
use serde::{Deserialize, Serialize};

// ============================================================================
// Opaque ID Types
// ============================================================================

/// Opaque type for FatSecret recipe IDs
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct RecipeId(String);

impl RecipeId {
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

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
    pub food_id: String,
    pub food_name: String,
    pub serving_id: Option<String>,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_units: f64,
    pub measurement_description: String,
    pub ingredient_description: String,
    pub ingredient_url: Option<String>,
}

/// Direction/step in recipe preparation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipeDirection {
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub direction_number: i32,
    pub direction_description: String,
}

/// Recipe category/type
pub type RecipeType = String;

/// Complete recipe details
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Recipe {
    pub recipe_id: RecipeId,
    pub recipe_name: String,
    pub recipe_url: String,
    pub recipe_description: String,
    pub recipe_image: Option<String>,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_servings: f64,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_int")]
    pub preparation_time_min: Option<i32>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_int")]
    pub cooking_time_min: Option<i32>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub rating: Option<f64>,

    #[serde(rename = "recipe_types", default)]
    pub recipe_types: RecipeTypesWrapper,

    #[serde(rename = "ingredients", default)]
    pub ingredients: RecipeIngredientsWrapper,

    #[serde(rename = "directions", default)]
    pub directions: RecipeDirectionsWrapper,

    // Nutritional information per serving
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub calories: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub carbohydrate: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub protein: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub fat: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub saturated_fat: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub polyunsaturated_fat: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub monounsaturated_fat: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub cholesterol: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub sodium: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub potassium: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub fiber: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub sugar: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub vitamin_a: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub vitamin_c: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub calcium: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub iron: Option<f64>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RecipeTypesWrapper {
    #[serde(
        rename = "recipe_type",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub recipe_types: Vec<RecipeType>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RecipeIngredientsWrapper {
    #[serde(
        rename = "ingredient",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub ingredients: Vec<RecipeIngredient>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RecipeDirectionsWrapper {
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
    pub recipe_id: RecipeId,
    pub recipe_name: String,
    pub recipe_description: String,
    pub recipe_url: String,
    pub recipe_image: Option<String>,
}

/// Response from recipes.search.v3
#[derive(Debug, Deserialize)]
pub struct RecipeSearchResponse {
    #[serde(
        rename = "recipe",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub recipes: Vec<RecipeSearchResult>,
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub max_results: i32,
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub total_results: i32,
    #[serde(deserialize_with = "deserialize_flexible_int")]
    pub page_number: i32,
}

/// Response from recipe_types.get.v2
#[derive(Debug, Deserialize)]
pub struct RecipeTypesResponse {
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
    pub recipe_id: RecipeId,
    pub recipe_name: String,
}

/// Response from recipes.autocomplete.v2 API
#[derive(Debug, Deserialize)]
pub struct RecipeAutocompleteResponse {
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
    pub recipe: Recipe,
}

/// Wrapper for Search response
#[derive(Debug, Deserialize)]
pub struct RecipeSearchResponseWrapper {
    pub recipes: RecipeSearchResponse,
}

/// Wrapper for Autocomplete response
#[derive(Debug, Deserialize)]
pub struct RecipeAutocompleteResponseWrapper {
    pub suggestions: RecipeAutocompleteResponse,
}

/// Wrapper for Recipe Types response
#[derive(Debug, Deserialize)]
pub struct RecipeTypesResponseWrapper {
    pub recipe_types: RecipeTypesResponse,
}
