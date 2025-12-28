//! FatSecret Recipes API types
//!
//! API Docs: https://platform.fatsecret.com/api/Default.aspx?screen=rapiref2&method=recipe.get.v2

use serde::{Deserialize, Serialize};
use std::fmt;

// ============================================================================
// Recipe ID (opaque type for type safety)
// ============================================================================

/// Opaque type for recipe IDs to prevent mixing with other ID types
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(transparent)]
pub struct RecipeId(String);

impl RecipeId {
    /// Create a RecipeId from a string
    pub fn new(id: impl Into<String>) -> Self {
        RecipeId(id.into())
    }

    /// Get the underlying string value
    pub fn as_str(&self) -> &str {
        &self.0
    }

    /// Convert to owned String
    pub fn into_string(self) -> String {
        self.0
    }
}

impl fmt::Display for RecipeId {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl From<String> for RecipeId {
    fn from(s: String) -> Self {
        RecipeId(s)
    }
}

impl From<&str> for RecipeId {
    fn from(s: &str) -> Self {
        RecipeId(s.to_string())
    }
}

// ============================================================================
// Recipe Component Types
// ============================================================================

/// Ingredient in a recipe
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipeIngredient {
    /// FatSecret food ID for this ingredient
    pub food_id: String,
    /// Food name
    pub food_name: String,
    /// Serving ID (if applicable)
    pub serving_id: Option<String>,
    /// Number of units of the serving
    pub number_of_units: f64,
    /// Description of the measurement (e.g., "1 cup")
    pub measurement_description: String,
    /// Full ingredient description as shown in recipe
    pub ingredient_description: String,
    /// URL to ingredient details
    pub ingredient_url: Option<String>,
}

/// Direction/step in recipe preparation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipeDirection {
    /// Step number in the recipe
    pub direction_number: i32,
    /// Description of what to do in this step
    pub direction_description: String,
}

/// Recipe category/type (simple string like "Main Dish", "Appetizers", etc.)
pub type RecipeType = String;

// ============================================================================
// Recipe Types
// ============================================================================

/// Complete recipe details (from recipe.get.v2)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Recipe {
    /// Unique recipe identifier
    pub recipe_id: RecipeId,
    /// Recipe name
    pub recipe_name: String,
    /// URL to recipe on FatSecret
    pub recipe_url: String,
    /// Recipe description
    pub recipe_description: String,
    /// URL to recipe image
    pub recipe_image: Option<String>,
    /// Number of servings the recipe makes
    pub number_of_servings: f64,
    /// Preparation time in minutes
    pub preparation_time_min: Option<i32>,
    /// Cooking time in minutes
    pub cooking_time_min: Option<i32>,
    /// User rating (0-5)
    pub rating: Option<f64>,
    /// Recipe categories/types
    pub recipe_types: Vec<RecipeType>,
    /// List of ingredients
    pub ingredients: Vec<RecipeIngredient>,
    /// Cooking directions/steps
    pub directions: Vec<RecipeDirection>,
    // Nutritional information per serving
    /// Calories per serving
    pub calories: Option<f64>,
    /// Carbohydrates per serving (g)
    pub carbohydrate: Option<f64>,
    /// Protein per serving (g)
    pub protein: Option<f64>,
    /// Total fat per serving (g)
    pub fat: Option<f64>,
    /// Saturated fat per serving (g)
    pub saturated_fat: Option<f64>,
    /// Polyunsaturated fat per serving (g)
    pub polyunsaturated_fat: Option<f64>,
    /// Monounsaturated fat per serving (g)
    pub monounsaturated_fat: Option<f64>,
    /// Cholesterol per serving (mg)
    pub cholesterol: Option<f64>,
    /// Sodium per serving (mg)
    pub sodium: Option<f64>,
    /// Potassium per serving (mg)
    pub potassium: Option<f64>,
    /// Fiber per serving (g)
    pub fiber: Option<f64>,
    /// Sugar per serving (g)
    pub sugar: Option<f64>,
    /// Vitamin A per serving (% daily value)
    pub vitamin_a: Option<f64>,
    /// Vitamin C per serving (% daily value)
    pub vitamin_c: Option<f64>,
    /// Calcium per serving (% daily value)
    pub calcium: Option<f64>,
    /// Iron per serving (% daily value)
    pub iron: Option<f64>,
}

/// Recipe search result item (from recipes.search.v3)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipeSearchResult {
    /// Unique recipe identifier
    pub recipe_id: RecipeId,
    /// Recipe name
    pub recipe_name: String,
    /// Recipe description
    pub recipe_description: String,
    /// URL to recipe on FatSecret
    pub recipe_url: String,
    /// URL to recipe image
    pub recipe_image: Option<String>,
}

/// Response from recipes.search.v3
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipeSearchResponse {
    /// List of recipe search results
    pub recipes: Vec<RecipeSearchResult>,
    /// Maximum results per page
    pub max_results: i32,
    /// Total number of matching recipes
    pub total_results: i32,
    /// Current page number (0-indexed)
    pub page_number: i32,
}

/// Response from recipe_types.get.v2
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipeTypesResponse {
    /// Available recipe types/categories
    pub recipe_types: Vec<RecipeType>,
}

/// Single recipe autocomplete suggestion from recipes.autocomplete.v2 API
///
/// This is a lightweight suggestion used for autocomplete dropdowns.
/// Contains minimal information to show in a suggestion list.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipeSuggestion {
    /// Unique recipe identifier
    pub recipe_id: RecipeId,
    /// Recipe name for display
    pub recipe_name: String,
}

/// Response from recipes.autocomplete.v2 API
///
/// Contains autocomplete suggestions for a partial recipe name.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecipeAutocompleteResponse {
    /// List of matching recipe suggestions
    pub suggestions: Vec<RecipeSuggestion>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_recipe_id_creation() {
        let id = RecipeId::new("recipe_123");
        assert_eq!(id.as_str(), "recipe_123");
        assert_eq!(id.to_string(), "recipe_123");
    }

    #[test]
    fn test_recipe_search_result_serialization() {
        let result = RecipeSearchResult {
            recipe_id: RecipeId::new("1"),
            recipe_name: "Chicken Salad".to_string(),
            recipe_description: "A delicious chicken salad".to_string(),
            recipe_url: "https://example.com/recipe/1".to_string(),
            recipe_image: Some("https://example.com/image.jpg".to_string()),
        };

        let json = serde_json::to_string(&result).unwrap();
        let deserialized: RecipeSearchResult = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.recipe_name, "Chicken Salad");
    }

    #[test]
    fn test_recipe_ingredient() {
        let ingredient = RecipeIngredient {
            food_id: "123".to_string(),
            food_name: "Chicken Breast".to_string(),
            serving_id: Some("456".to_string()),
            number_of_units: 1.0,
            measurement_description: "1 piece".to_string(),
            ingredient_description: "1 boneless skinless chicken breast".to_string(),
            ingredient_url: None,
        };

        let json = serde_json::to_string(&ingredient).unwrap();
        assert!(json.contains("Chicken Breast"));
    }

    #[test]
    fn test_recipe_direction() {
        let direction = RecipeDirection {
            direction_number: 1,
            direction_description: "Preheat oven to 350F".to_string(),
        };

        assert_eq!(direction.direction_number, 1);
    }
}
