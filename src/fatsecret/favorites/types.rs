//! FatSecret Favorites Domain Types

use serde::{Deserialize, Serialize};
use crate::fatsecret::core::serde_utils::{
    deserialize_flexible_float,
    deserialize_single_or_vec,
};

/// A favorite food item
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FavoriteFood {
    pub food_id: String,
    pub food_name: String,
    pub food_type: String,
    pub brand_name: Option<String>,
    pub food_description: String,
    pub food_url: String,
    pub serving_id: String,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_units: f64,
}

/// A most-eaten food item
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MostEatenFood {
    pub food_id: String,
    pub food_name: String,
    pub food_type: String,
    pub brand_name: Option<String>,
    pub food_description: String,
    pub food_url: String,
    pub serving_id: String,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_units: f64,
}

/// A recently eaten food item
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecentlyEatenFood {
    pub food_id: String,
    pub food_name: String,
    pub food_type: String,
    pub brand_name: Option<String>,
    pub food_description: String,
    pub food_url: String,
    pub serving_id: String,
    #[serde(deserialize_with = "deserialize_flexible_float")]
    pub number_of_units: f64,
}

/// A favorite recipe
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FavoriteRecipe {
    pub recipe_id: String,
    pub recipe_name: String,
    pub recipe_description: String,
    pub recipe_url: String,
    pub recipe_image: Option<String>,
}

/// Response containing favorite foods
#[derive(Debug, Deserialize)]
pub struct FavoriteFoodsResponse {
    #[serde(rename = "food", default, deserialize_with = "deserialize_single_or_vec")]
    pub foods: Vec<FavoriteFood>,
}

/// Response containing most eaten foods
#[derive(Debug, Deserialize)]
pub struct MostEatenResponse {
    #[serde(rename = "food", default, deserialize_with = "deserialize_single_or_vec")]
    pub foods: Vec<MostEatenFood>,
}

/// Response containing recently eaten foods
#[derive(Debug, Deserialize)]
pub struct RecentlyEatenResponse {
    #[serde(rename = "food", default, deserialize_with = "deserialize_single_or_vec")]
    pub foods: Vec<RecentlyEatenFood>,
}

/// Response containing favorite recipes
#[derive(Debug, Deserialize)]
pub struct FavoriteRecipesResponse {
    #[serde(rename = "recipe", default, deserialize_with = "deserialize_single_or_vec")]
    pub recipes: Vec<FavoriteRecipe>,
}

/// Meal type filter for most/recently eaten queries
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum MealFilter {
    All,
    Breakfast,
    Lunch,
    Dinner,
    #[serde(rename = "other")]
    Snack,
}

impl MealFilter {
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
