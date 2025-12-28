//! FatSecret Favorites API Client

use std::collections::HashMap;
use crate::fatsecret::core::config::FatSecretConfig;
use crate::fatsecret::core::errors::FatSecretError;
use crate::fatsecret::core::http::make_authenticated_request;
use crate::fatsecret::core::oauth::AccessToken;
use crate::fatsecret::favorites::types::{
    FavoriteFood, FavoriteFoodsResponse, FavoriteRecipe, FavoriteRecipesResponse,
    MealFilter, MostEatenFood, MostEatenResponse, RecentlyEatenFood, RecentlyEatenResponse,
};

/// Add a food to favorites (food.add_favorite - 3-legged)
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

/// Remove a food from favorites (food.delete_favorite - 3-legged)
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

/// Get user's favorite foods (foods.get_favorites.v2 - 3-legged)
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

    let body = make_authenticated_request(config, access_token, "foods.get_favorites.v2", params).await?;
    let response: FavoriteFoodsResponse = serde_json::from_str(&body)
        .map_err(|e| FatSecretError::ParseError(format!("Failed to parse favorite foods: {}. Body: {}", e, body)))?;

    Ok(response.foods)
}

/// Get user's most eaten foods (foods.get_most_eaten.v2 - 3-legged)
pub async fn get_most_eaten(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    meal: Option<MealFilter>,
) -> Result<Vec<MostEatenFood>, FatSecretError> {
    let mut params = HashMap::new();
    if let Some(m) = meal {
        params.insert("meal".to_string(), m.to_api_string().to_string());
    }

    let body = make_authenticated_request(config, access_token, "foods.get_most_eaten.v2", params).await?;
    let response: MostEatenResponse = serde_json::from_str(&body)
        .map_err(|e| FatSecretError::ParseError(format!("Failed to parse most eaten foods: {}. Body: {}", e, body)))?;

    Ok(response.foods)
}

/// Get user's recently eaten foods (foods.get_recently_eaten.v2 - 3-legged)
pub async fn get_recently_eaten(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    meal: Option<MealFilter>,
) -> Result<Vec<RecentlyEatenFood>, FatSecretError> {
    let mut params = HashMap::new();
    if let Some(m) = meal {
        params.insert("meal".to_string(), m.to_api_string().to_string());
    }

    let body = make_authenticated_request(config, access_token, "foods.get_recently_eaten.v2", params).await?;
    let response: RecentlyEatenResponse = serde_json::from_str(&body)
        .map_err(|e| FatSecretError::ParseError(format!("Failed to parse recently eaten foods: {}. Body: {}", e, body)))?;

    Ok(response.foods)
}

/// Add a recipe to favorites (recipe.add_favorite - 3-legged)
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

/// Remove a recipe from favorites (recipe.delete_favorite - 3-legged)
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

/// Get user's favorite recipes (recipes.get_favorites.v2 - 3-legged)
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

    let body = make_authenticated_request(config, access_token, "recipes.get_favorites.v2", params).await?;
    let response: FavoriteRecipesResponse = serde_json::from_str(&body)
        .map_err(|e| FatSecretError::ParseError(format!("Failed to parse favorite recipes: {}. Body: {}", e, body)))?;

    Ok(response.recipes)
}
