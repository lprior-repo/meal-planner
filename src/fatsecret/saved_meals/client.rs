//! `FatSecret` Saved Meals API client

use crate::fatsecret::core::config::FatSecretConfig;
use crate::fatsecret::core::errors::FatSecretError;
use crate::fatsecret::core::http::make_authenticated_request;
use crate::fatsecret::core::oauth::AccessToken;
use crate::fatsecret::core::serde_utils::SuccessResponse;
use crate::fatsecret::saved_meals::types::{
    MealType, SavedMeal, SavedMealId, SavedMealItem, SavedMealItemsResponseWrapper,
    SavedMealsResponseWrapper,
};
use std::collections::HashMap;

/// Create a saved meal (`saved_meal.create.v2` - 3-legged)
pub async fn create_saved_meal(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    name: &str,
    description: Option<&str>,
    meals: &[MealType],
) -> Result<SavedMealId, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("saved_meal_name".to_string(), name.to_string());

    if let Some(d) = description {
        params.insert("saved_meal_description".to_string(), d.to_string());
    }

    let meal_str = meals
        .iter()
        .map(MealType::to_api_string)
        .collect::<Vec<_>>()
        .join(",");
    params.insert("meals".to_string(), meal_str);

    let body =
        make_authenticated_request(config, access_token, "saved_meal.create.v2", params).await?;

    #[derive(serde::Deserialize)]
    struct CreateResponse {
        saved_meal_id: String,
    }

    let response: CreateResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse create response: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(SavedMealId::new(response.saved_meal_id))
}

/// Get user's saved meals (`saved_meals.get.v2` - 3-legged)
pub async fn get_saved_meals(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    meal: Option<MealType>,
) -> Result<Vec<SavedMeal>, FatSecretError> {
    let mut params = HashMap::new();
    if let Some(m) = meal {
        params.insert("meal".to_string(), m.to_api_string().to_string());
    }

    let body =
        make_authenticated_request(config, access_token, "saved_meals.get.v2", params).await?;
    let response: SavedMealsResponseWrapper = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse saved meals: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.saved_meals.saved_meals)
}

/// Get items for a specific saved meal (`saved_meal_items.get.v2` - 3-legged)
pub async fn get_saved_meal_items(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    saved_meal_id: &SavedMealId,
) -> Result<Vec<SavedMealItem>, FatSecretError> {
    let mut params = HashMap::new();
    params.insert(
        "saved_meal_id".to_string(),
        saved_meal_id.as_str().to_string(),
    );

    let body =
        make_authenticated_request(config, access_token, "saved_meal_items.get.v2", params).await?;
    let response: SavedMealItemsResponseWrapper = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse saved meal items: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.saved_meal_items.items)
}

/// Delete a saved meal (`saved_meal.delete.v2` - 3-legged)
pub async fn delete_saved_meal(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    saved_meal_id: &SavedMealId,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert(
        "saved_meal_id".to_string(),
        saved_meal_id.as_str().to_string(),
    );

    let body =
        make_authenticated_request(config, access_token, "saved_meal.delete.v2", params).await?;
    let response: SuccessResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse delete response: {}. Body: {}",
            e, body
        ))
    })?;

    if !response.is_success() {
        return Err(FatSecretError::RequestFailed {
            status: 400,
            body: "Delete operation did not return success".to_string(),
        });
    }

    Ok(())
}

/// Edit a saved meal (`saved_meal.update.v2` - 3-legged)
#[allow(clippy::too_many_arguments)]
pub async fn edit_saved_meal(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    saved_meal_id: &SavedMealId,
    name: Option<&str>,
    description: Option<&str>,
    meals: Option<&[MealType]>,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert(
        "saved_meal_id".to_string(),
        saved_meal_id.as_str().to_string(),
    );

    if let Some(n) = name {
        params.insert("saved_meal_name".to_string(), n.to_string());
    }

    if let Some(d) = description {
        params.insert("saved_meal_description".to_string(), d.to_string());
    }

    if let Some(meal_types) = meals {
        let meal_str = meal_types
            .iter()
            .map(MealType::to_api_string)
            .collect::<Vec<_>>()
            .join(",");
        params.insert("meals".to_string(), meal_str);
    }

    let body =
        make_authenticated_request(config, access_token, "saved_meal.update.v2", params).await?;
    let response: SuccessResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse update response: {}. Body: {}",
            e, body
        ))
    })?;

    if !response.is_success() {
        return Err(FatSecretError::RequestFailed {
            status: 400,
            body: "Update operation did not return success".to_string(),
        });
    }

    Ok(())
}
