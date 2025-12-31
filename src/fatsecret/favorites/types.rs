//! FatSecret Favorites Domain Types
//!
//! This module defines the data structures for the FatSecret favorites domain,
//! including favorite foods, recipes, usage analytics, and API response wrappers.
//!
//! # Core Types
//!
//! ## Food Types
//! - [`FavoriteFood`] - A food marked as favorite by the user
//! - [`MostEatenFood`] - A frequently consumed food with usage metrics
//! - [`RecentlyEatenFood`] - A food from recent consumption history
//!
//! ## Recipe Types
//! - [`FavoriteRecipe`] - A recipe marked as favorite by the user
//!
//! ## Response Wrappers
//! - [`FavoriteFoodsResponse`] - API response containing favorite foods
//! - [`MostEatenResponse`] - API response containing most eaten foods
//! - [`RecentlyEatenResponse`] - API response containing recently eaten foods
//! - [`FavoriteRecipesResponse`] - API response containing favorite recipes
//!
//! ## Filters
//! - [`MealFilter`] - Filter for meal types (breakfast, lunch, dinner, snack, all)
//!
//! # Data Handling
//!
//! ## Flexible Parsing
//! - Numeric fields use `deserialize_flexible_float` to handle string/number variants
//! - Collection fields use `deserialize_single_or_vec` to handle single items or arrays
//! - Optional fields gracefully handle missing data from API responses
//!
//! ## Field Mapping
//! - Response wrappers rename API fields (e.g., `"food"` → `foods`)
//! - Enum variants map to API strings via `to_api_string()` method
//!
//! # Example
//!
//! ```rust
//! use meal_planner::fatsecret::favorites::types::{
//!     FavoriteFood,
//!     MealFilter,
//! };
//!
//! // Create a meal filter
//! let filter = MealFilter::Breakfast;
//! assert_eq!(filter.to_api_string(), "breakfast");
//!
//! // All filters available
//! let filters = vec![
//!     MealFilter::All,
//!     MealFilter::Breakfast,
//!     MealFilter::Lunch,
//!     MealFilter::Dinner,
//!     MealFilter::Snack,
//! ];
//! ```
//!
//! # JSON Serialization
//!
//! All types implement `Serialize` and `Deserialize` for JSON handling:
//!
//! ```rust,no_run
//! use meal_planner::fatsecret::favorites::types::FavoriteFoodsResponse;
//!
//! # fn example() -> Result<(), Box<dyn std::error::Error>> {
//! // Parse API response
//! let json = r#"{"food": [{"food_id": "123", "food_name": "Apple", ...}]}"#;
//! let response: FavoriteFoodsResponse = serde_json::from_str(json)?;
//!
//! // Handle single item or array
//! let json_single = r#"{"food": {"food_id": "123", "food_name": "Apple", ...}}"#;
//! let response_single: FavoriteFoodsResponse = serde_json::from_str(json_single)?;
//! # Ok(())
//! # }
//! ```
//!
//! # Special Handling
//!
//! ## Number Parsing
//! The `number_of_units` field can appear as either a string or number in API responses.
//! The `deserialize_flexible_float` deserializer handles both cases automatically.
//!
//! ## Array Normalization
//! API responses return single items as objects, not arrays. The `deserialize_single_or_vec`
//! deserializer normalizes both cases to `Vec<T>` for consistent handling.

use crate::fatsecret::core::serde_utils::{deserialize_flexible_float, deserialize_single_or_vec};
use serde::{Deserialize, Serialize};

/// A favorite food item
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FavoriteFood {
    /// Unique identifier for the food item
    pub food_id: String,
    /// Display name of the food
    pub food_name: String,
    /// Type of food (e.g., "Generic", "Brand")
    pub food_type: String,
    /// Brand name if applicable (for branded foods)
    pub brand_name: Option<String>,
    /// Nutritional description (e.g., "Per 100g - Calories: 250kcal")
    pub food_description: String,
    /// URL to the food details page on FatSecret
    pub food_url: String,
    /// Identifier for the specific serving size
    pub serving_id: String,
    /// Number of serving units
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_units: f64,
}

/// A most-eaten food item
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MostEatenFood {
    /// Unique identifier for the food item
    pub food_id: String,
    /// Display name of the food
    pub food_name: String,
    /// Type of food (e.g., "Generic", "Brand")
    pub food_type: String,
    /// Brand name if applicable (for branded foods)
    pub brand_name: Option<String>,
    /// Nutritional description (e.g., "Per 100g - Calories: 250kcal")
    pub food_description: String,
    /// URL to the food details page on FatSecret
    pub food_url: String,
    /// Identifier for the specific serving size
    pub serving_id: String,
    /// Number of serving units
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_units: f64,
}

/// A recently eaten food item
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecentlyEatenFood {
    /// Unique identifier for the food item
    pub food_id: String,
    /// Display name of the food
    pub food_name: String,
    /// Type of food (e.g., "Generic", "Brand")
    pub food_type: String,
    /// Brand name if applicable (for branded foods)
    pub brand_name: Option<String>,
    /// Nutritional description (e.g., "Per 100g - Calories: 250kcal")
    pub food_description: String,
    /// URL to the food details page on FatSecret
    pub food_url: String,
    /// Identifier for the specific serving size
    pub serving_id: String,
    /// Number of serving units
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_units: f64,
}

/// A favorite recipe
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FavoriteRecipe {
    /// Unique identifier for the recipe
    pub recipe_id: String,
    /// Display name of the recipe
    pub recipe_name: String,
    /// Brief description of the recipe
    pub recipe_description: String,
    /// URL to the recipe details page on FatSecret
    pub recipe_url: String,
    /// Optional URL to the recipe image
    pub recipe_image: Option<String>,
}

/// Response containing favorite foods
#[derive(Debug, Deserialize)]
pub struct FavoriteFoodsResponse {
    /// List of favorite foods (API returns single item or array)
    #[serde(
        rename = "food",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub foods: Vec<FavoriteFood>,
}

/// Response containing most eaten foods
#[derive(Debug, Deserialize)]
pub struct MostEatenResponse {
    /// List of most eaten foods (API returns single item or array)
    #[serde(
        rename = "food",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub foods: Vec<MostEatenFood>,
}

/// Response containing recently eaten foods
#[derive(Debug, Deserialize)]
pub struct RecentlyEatenResponse {
    /// List of recently eaten foods (API returns single item or array)
    #[serde(
        rename = "food",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub foods: Vec<RecentlyEatenFood>,
}

/// Response containing favorite recipes
#[derive(Debug, Deserialize)]
pub struct FavoriteRecipesResponse {
    /// List of favorite recipes (API returns single item or array)
    #[serde(
        rename = "recipe",
        default,
        deserialize_with = "deserialize_single_or_vec"
    )]
    pub recipes: Vec<FavoriteRecipe>,
}

/// Meal type filter for most/recently eaten queries
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum MealFilter {
    /// All meals (no filter)
    All,
    /// Breakfast meals only
    Breakfast,
    /// Lunch meals only
    Lunch,
    /// Dinner meals only
    Dinner,
    /// Snacks and other meals
    #[serde(rename = "other")]
    Snack,
}

impl MealFilter {
    /// Convert meal filter to API parameter string
    pub fn to_api_string(&self) -> &'static str {
        match self {
            MealFilter::All => "all",
            MealFilter::Breakfast => "breakfast",
            MealFilter::Lunch => "lunch",
            MealFilter::Dinner => "dinner",
            MealFilter::Snack => "other",
        }
    }
}
