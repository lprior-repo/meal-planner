//! FatSecret Favorites Domain Types
//!
//! Types for managing user's favorite foods, recipes, and eating patterns.
//! All API methods require 3-legged OAuth authentication.
//!
//! API Reference: https://platform.fatsecret.com/api/Default.aspx?screen=rapir

use serde::{Deserialize, Serialize};

// ============================================================================
// Favorite Food Types
// ============================================================================

/// A favorite food item
/// API: foods.get_favorites.v2
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FavoriteFood {
    /// FatSecret food ID
    pub food_id: String,
    /// Food name
    pub food_name: String,
    /// Food type (e.g., "Brand", "Generic")
    pub food_type: String,
    /// Brand name (if applicable)
    pub brand_name: Option<String>,
    /// Food description
    pub food_description: String,
    /// URL to food details
    pub food_url: String,
    /// Serving ID
    pub serving_id: String,
    /// Number of units
    pub number_of_units: String,
}

/// A most-eaten food item
/// API: foods.get_most_eaten.v2
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MostEatenFood {
    /// FatSecret food ID
    pub food_id: String,
    /// Food name
    pub food_name: String,
    /// Food type (e.g., "Brand", "Generic")
    pub food_type: String,
    /// Brand name (if applicable)
    pub brand_name: Option<String>,
    /// Food description
    pub food_description: String,
    /// URL to food details
    pub food_url: String,
    /// Serving ID
    pub serving_id: String,
    /// Number of units
    pub number_of_units: String,
}

/// A recently eaten food item
/// API: foods.get_recently_eaten.v2
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecentlyEatenFood {
    /// FatSecret food ID
    pub food_id: String,
    /// Food name
    pub food_name: String,
    /// Food type (e.g., "Brand", "Generic")
    pub food_type: String,
    /// Brand name (if applicable)
    pub brand_name: Option<String>,
    /// Food description
    pub food_description: String,
    /// URL to food details
    pub food_url: String,
    /// Serving ID
    pub serving_id: String,
    /// Number of units
    pub number_of_units: String,
}

// ============================================================================
// Favorite Recipe Types
// ============================================================================

/// A favorite recipe
/// API: recipes.get_favorites.v2
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FavoriteRecipe {
    /// FatSecret recipe ID
    pub recipe_id: String,
    /// Recipe name
    pub recipe_name: String,
    /// Recipe description
    pub recipe_description: String,
    /// URL to recipe on FatSecret
    pub recipe_url: String,
    /// URL to recipe image
    pub recipe_image: Option<String>,
}

// ============================================================================
// Response Types
// ============================================================================

/// Response containing favorite foods (no pagination per API docs)
/// API: foods.get_favorites.v2
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FavoriteFoodsResponse {
    /// List of favorite foods
    pub foods: Vec<FavoriteFood>,
}

/// Response containing most eaten foods (no pagination per API docs)
/// API: foods.get_most_eaten.v2
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MostEatenResponse {
    /// List of most eaten foods
    pub foods: Vec<MostEatenFood>,
}

/// Response containing recently eaten foods (no pagination per API docs)
/// API: foods.get_recently_eaten.v2
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecentlyEatenResponse {
    /// List of recently eaten foods
    pub foods: Vec<RecentlyEatenFood>,
}

/// Response containing favorite recipes (no pagination per API docs)
/// API: recipes.get_favorites.v2
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FavoriteRecipesResponse {
    /// List of favorite recipes
    pub recipes: Vec<FavoriteRecipe>,
}

// ============================================================================
// Filter Types
// ============================================================================

/// Meal type filter for most/recently eaten queries
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum MealFilter {
    /// All meals
    #[default]
    All,
    /// Breakfast only
    Breakfast,
    /// Lunch only
    Lunch,
    /// Dinner only
    Dinner,
    /// Snacks/other
    Snack,
}

impl MealFilter {
    /// Convert to API parameter string
    pub fn as_api_str(&self) -> &'static str {
        match self {
            MealFilter::All => "all",
            MealFilter::Breakfast => "breakfast",
            MealFilter::Lunch => "lunch",
            MealFilter::Dinner => "dinner",
            MealFilter::Snack => "other",
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_meal_filter_to_string() {
        assert_eq!(MealFilter::All.as_api_str(), "all");
        assert_eq!(MealFilter::Breakfast.as_api_str(), "breakfast");
        assert_eq!(MealFilter::Lunch.as_api_str(), "lunch");
        assert_eq!(MealFilter::Dinner.as_api_str(), "dinner");
        assert_eq!(MealFilter::Snack.as_api_str(), "other");
    }

    #[test]
    fn test_favorite_food_serialization() {
        let food = FavoriteFood {
            food_id: "123".to_string(),
            food_name: "Apple".to_string(),
            food_type: "Generic".to_string(),
            brand_name: None,
            food_description: "Per 1 medium - Calories: 95kcal".to_string(),
            food_url: "https://example.com/food/123".to_string(),
            serving_id: "456".to_string(),
            number_of_units: "1".to_string(),
        };

        let json = serde_json::to_string(&food).unwrap();
        let deserialized: FavoriteFood = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.food_name, "Apple");
    }

    #[test]
    fn test_favorite_recipe_serialization() {
        let recipe = FavoriteRecipe {
            recipe_id: "789".to_string(),
            recipe_name: "Grilled Chicken".to_string(),
            recipe_description: "Simple grilled chicken recipe".to_string(),
            recipe_url: "https://example.com/recipe/789".to_string(),
            recipe_image: Some("https://example.com/image.jpg".to_string()),
        };

        let json = serde_json::to_string(&recipe).unwrap();
        let deserialized: FavoriteRecipe = serde_json::from_str(&json).unwrap();
        assert_eq!(deserialized.recipe_name, "Grilled Chicken");
    }

    #[test]
    fn test_meal_filter_default() {
        let filter = MealFilter::default();
        assert_eq!(filter, MealFilter::All);
    }
}
