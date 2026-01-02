//! `FatSecret` Favorites API Client
//!
//! This module provides the HTTP client functions for interacting with the `FatSecret`
//! Platform API's favorites endpoints. All functions perform authenticated requests
//! using 3-legged OAuth and return strongly-typed results.
//!
//! # Key Functions
//!
//! ## Food Favorites
//! - [`add_favorite_food`] - Mark a food as favorite
//! - [`delete_favorite_food`] - Remove a food from favorites
//! - [`get_favorite_foods`] - Retrieve all favorite foods with pagination
//!
//! ## Recipe Favorites
//! - [`add_favorite_recipe`] - Mark a recipe as favorite
//! - [`delete_favorite_recipe`] - Remove a recipe from favorites
//! - [`get_favorite_recipes`] - Retrieve all favorite recipes with pagination
//!
//! ## Usage Analytics
//! - [`get_most_eaten`] - Get frequently consumed foods (optionally filtered by meal)
//! - [`get_recently_eaten`] - Get recently consumed foods (optionally filtered by meal)
//!
//! # Authentication
//!
//! All functions require:
//! - [`FatSecretConfig`] - API credentials and configuration
//! - [`AccessToken`] - 3-legged OAuth access token with user authorization
//!
//! # Error Handling
//!
//! Functions return `Result<T, FatSecretError>` with these possible errors:
//! - Network failures during API communication
//! - OAuth signature validation failures
//! - JSON parsing errors from malformed API responses
//! - API-level errors (invalid `food_id`, unauthorized access, etc.)
//!
//! # Example
//!
//! ```rust,no_run
//! use meal_planner::fatsecret::favorites::client::{
//!     add_favorite_food,
//!     get_favorite_foods,
//!     get_most_eaten,
//! };
//! use meal_planner::fatsecret::favorites::types::MealFilter;
//! use meal_planner::fatsecret::core::config::`FatSecretConfig`;
//! use meal_planner::fatsecret::core::oauth::`AccessToken`;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = `FatSecretConfig`::from_env()?;
//! let access_token = `AccessToken` {
//!     token: "user_token".to_string(),
//!     secret: "user_secret".to_string(),
//! };
//!
//! // Add a food to favorites
//! add_favorite_food(&config, &access_token, "12345").await?;
//!
//! // Get first page of favorites (max 50 results)
//! let favorites = get_favorite_foods(&config, &access_token, Some(50), Some(0)).await?;
//! for food in favorites {
//!     println!("Favorite: {} ({})", food.food_name, food.`food_id`);
//! }
//!
//! // Get breakfast foods sorted by frequency
//! let breakfast = get_most_eaten(&config, &access_token, Some(MealFilter::Breakfast)).await?;
//! println!("Most eaten at breakfast: {:?}", breakfast.first().map(|f| &f.food_name));
//! # Ok(())
//! # }
//! ```
//!
//! # API Methods
//!
//! This client wraps the following `FatSecret` Platform API methods:
//! - `food.add_favorite` - Add food to favorites
//! - `food.delete_favorite` - Remove food from favorites
//! - `foods.get_favorites.v2` - List favorite foods
//! - `foods.get_most_eaten.v2` - Get most eaten foods
//! - `foods.get_recently_eaten.v2` - Get recently eaten foods
//! - `recipe.add_favorite` - Add recipe to favorites
//! - `recipe.delete_favorite` - Remove recipe from favorites
//! - `recipes.get_favorites.v2` - List favorite recipes

use crate::fatsecret::core::config::FatSecretConfig;
use crate::fatsecret::core::errors::FatSecretError;
use crate::fatsecret::core::http::make_authenticated_request;
use crate::fatsecret::core::oauth::AccessToken;
use crate::fatsecret::favorites::types::{
    FavoriteFood, FavoriteFoodsResponse, FavoriteRecipe, FavoriteRecipesResponse, MealFilter,
    MostEatenFood, MostEatenResponse, RecentlyEatenFood, RecentlyEatenResponse,
};
use std::collections::HashMap;

/// Add a food to favorites (food.`add_favorite` - 3-legged)
pub async fn add_favorite_food(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    food_id: &str,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("food_id".to_string(), food_id.to_string());

    make_authenticated_request(config, access_token, "food.add_favorite", params).await?;
    Ok(())
}

/// Remove a food from favorites (food.`delete_favorite` - 3-legged)
pub async fn delete_favorite_food(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    food_id: &str,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("food_id".to_string(), food_id.to_string());

    make_authenticated_request(config, access_token, "food.delete_favorite", params).await?;
    Ok(())
}

/// Get user's favorite foods (`foods.get_favorites.v2` - 3-legged)
pub async fn get_favorite_foods(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    max_results: Option<i32>,
    page_number: Option<i32>,
) -> Result<Vec<FavoriteFood>, FatSecretError> {
    let mut params = HashMap::new();
    if let Some(n) = max_results {
        params.insert("max_results".to_string(), n.to_string());
    }
    if let Some(n) = page_number {
        params.insert("page_number".to_string(), n.to_string());
    }

    let body =
        make_authenticated_request(config, access_token, "foods.get_favorites.v2", params).await?;
    let response: FavoriteFoodsResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse favorite foods: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.foods)
}

/// Get user's most eaten foods (`foods.get_most_eaten.v2` - 3-legged)
pub async fn get_most_eaten(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    meal: Option<MealFilter>,
) -> Result<Vec<MostEatenFood>, FatSecretError> {
    let mut params = HashMap::new();
    if let Some(m) = meal {
        params.insert("meal".to_string(), m.to_api_string().to_string());
    }

    let body =
        make_authenticated_request(config, access_token, "foods.get_most_eaten.v2", params).await?;
    let response: MostEatenResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse most eaten foods: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.foods)
}

/// Get user's recently eaten foods (`foods.get_recently_eaten.v2` - 3-legged)
pub async fn get_recently_eaten(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    meal: Option<MealFilter>,
) -> Result<Vec<RecentlyEatenFood>, FatSecretError> {
    let mut params = HashMap::new();
    if let Some(m) = meal {
        params.insert("meal".to_string(), m.to_api_string().to_string());
    }

    let body =
        make_authenticated_request(config, access_token, "foods.get_recently_eaten.v2", params)
            .await?;
    let response: RecentlyEatenResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse recently eaten foods: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.foods)
}

/// Add a recipe to favorites (recipe.`add_favorite` - 3-legged)
pub async fn add_favorite_recipe(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    recipe_id: &str,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("recipe_id".to_string(), recipe_id.to_string());

    make_authenticated_request(config, access_token, "recipe.add_favorite", params).await?;
    Ok(())
}

/// Remove a recipe from favorites (recipe.`delete_favorite` - 3-legged)
pub async fn delete_favorite_recipe(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    recipe_id: &str,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("recipe_id".to_string(), recipe_id.to_string());

    make_authenticated_request(config, access_token, "recipe.delete_favorite", params).await?;
    Ok(())
}

/// Get user's favorite recipes (`recipes.get_favorites.v2` - 3-legged)
pub async fn get_favorite_recipes(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    max_results: Option<i32>,
    page_number: Option<i32>,
) -> Result<Vec<FavoriteRecipe>, FatSecretError> {
    let mut params = HashMap::new();
    if let Some(n) = max_results {
        params.insert("max_results".to_string(), n.to_string());
    }
    if let Some(n) = page_number {
        params.insert("page_number".to_string(), n.to_string());
    }

    let body = make_authenticated_request(config, access_token, "recipes.get_favorites.v2", params)
        .await?;
    let response: FavoriteRecipesResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse favorite recipes: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.recipes)
}
