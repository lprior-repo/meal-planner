//! FatSecret Saved Meals API client

use std::collections::HashMap;
use crate::fatsecret::core::config::FatSecretConfig;
use crate::fatsecret::core::errors::FatSecretError;
use crate::fatsecret::core::http::make_authenticated_request;
use crate::fatsecret::core::oauth::AccessToken;
use crate::fatsecret::saved_meals::types::{
    SavedMeal, SavedMealId, SavedMealItem, SavedMealItemsResponseWrapper,
    SavedMealsResponseWrapper, MealType,
};

/// Get user's saved meals (saved_meals.get.v2 - 3-legged)
pub async fn get_saved_meals(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    meal: Option<MealType>,
) -> Result<Vec<SavedMeal>, FatSecretError> {
    let mut params = HashMap::new();
    if let Some(m) = meal {
        params.insert("meal".to_string(), m.to_api_string().to_string());
    }

    let body = make_authenticated_request(config, access_token, "saved_meals.get.v2", params).await?;
    let response: SavedMealsResponseWrapper = serde_json::from_str(&body)
        .map_err(|e| FatSecretError::ParseError(format!("Failed to parse saved meals: {}. Body: {}", e, body)))?;

    Ok(response.saved_meals.saved_meals)
}

/// Get items for a specific saved meal (saved_meal_items.get.v2 - 3-legged)
pub async fn get_saved_meal_items(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    saved_meal_id: &SavedMealId,
) -> Result<Vec<SavedMealItem>, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("saved_meal_id".to_string(), saved_meal_id.as_str().to_string());

    let body = make_authenticated_request(config, access_token, "saved_meal_items.get.v2", params).await?;
    let response: SavedMealItemsResponseWrapper = serde_json::from_str(&body)
        .map_err(|e| FatSecretError::ParseError(format!("Failed to parse saved meal items: {}. Body: {}", e, body)))?;

    Ok(response.saved_meal_items.items)
}
