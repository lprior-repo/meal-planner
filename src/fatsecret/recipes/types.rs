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
//! println!("ID: {}", recipe.recipe_id);
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

/// Recipe type/category from the API (e.g., "Vegetarian", "Main Dish")
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(from = "RecipeTypeHelper", into = "RecipeTypeHelper")]
pub struct RecipeType {
    pub code: String,
    pub name: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
enum RecipeTypeHelper {
    StringValue(String),
    ObjectValue {
        #[serde(default)]
        recipe_type_code: Option<String>,
        #[serde(default)]
        recipe_type_name: Option<String>,
    },
}

impl From<RecipeTypeHelper> for RecipeType {
    fn from(h: RecipeTypeHelper) -> Self {
        match h {
            RecipeTypeHelper::StringValue(name) => Self {
                code: name.to_lowercase().replace(' ', "_"),
                name,
            },
            RecipeTypeHelper::ObjectValue {
                recipe_type_code,
                recipe_type_name,
            } => {
                if let Some(code) = recipe_type_code {
                    Self {
                        code,
                        name: recipe_type_name.unwrap_or_default(),
                    }
                } else if let Some(name) = recipe_type_name {
                    Self {
                        code: name.to_lowercase().replace(' ', "_"),
                        name,
                    }
                } else {
                    Self {
                        code: "unknown".to_string(),
                        name: "Unknown".to_string(),
                    }
                }
            }
        }
    }
}

impl From<RecipeType> for RecipeTypeHelper {
    fn from(t: RecipeType) -> Self {
        Self::ObjectValue {
            recipe_type_code: Some(t.code),
            recipe_type_name: Some(t.name),
        }
    }
}

/// Legacy type alias for backward compatibility
pub type RecipeTypeString = String;

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

/// Wrapper for deserializing ingredients from `FatSecret` API (full objects)
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

/// Wrapper for deserializing recipe types from `FatSecret` search API (strings)
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RecipeTypesStringWrapper {
    #[serde(
        rename = "recipe_type",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub recipe_types: Vec<String>,
}

/// Wrapper for deserializing ingredients from `FatSecret` search API (strings)
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RecipeIngredientsStringWrapper {
    #[serde(
        rename = "ingredient",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub ingredients: Vec<String>,
}

/// Wrapper for deserializing nutrition from `FatSecret` search API (strings)
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct RecipeNutritionStringWrapper {
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub calories: Option<f64>,
    #[serde(
        default,
        rename = "carbohydrate",
        deserialize_with = "deserialize_optional_flexible_float"
    )]
    pub carbohydrate: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub protein: Option<f64>,
    #[serde(default, deserialize_with = "deserialize_optional_flexible_float")]
    pub fat: Option<f64>,
}

/// Recipe as returned by search API (simplified with string ingredients/types)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipeSearchApiResponse {
    pub recipe_id: RecipeId,
    pub recipe_name: String,
    pub recipe_description: String,
    #[serde(default)]
    pub recipe_url: Option<String>,
    #[serde(default)]
    pub recipe_image: Option<String>,
    #[serde(default)]
    pub recipe_types: RecipeTypesStringWrapper,
    #[serde(default)]
    pub recipe_ingredients: RecipeIngredientsStringWrapper,
    #[serde(default)]
    pub recipe_nutrition: RecipeNutritionStringWrapper,
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
    /// List of matching recipes (API returns simplified objects with string ingredients)
    #[serde(
        rename = "recipe",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub recipes: Vec<RecipeSearchApiResponse>,
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
