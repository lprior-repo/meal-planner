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

#[cfg(test)]
mod tests {
    use super::*;
    use wiremock::matchers::{body_string_contains, method, path};
    use wiremock::{Mock, MockServer, ResponseTemplate};

    fn test_config(mock_server: &MockServer) -> FatSecretConfig {
        FatSecretConfig::with_base_url("test_key", "test_secret", mock_server.uri())
    }

    fn test_token() -> AccessToken {
        AccessToken {
            oauth_token: "test_token".to_string(),
            oauth_token_secret: "test_secret".to_string(),
        }
    }

    // ========================================================================
    // create_saved_meal tests
    // ========================================================================

    #[tokio::test]
    async fn test_create_saved_meal_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=saved_meal.create.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{"saved_meal_id": "55555"}"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = create_saved_meal(
            &config,
            &token,
            "Morning Routine",
            Some("My breakfast routine"),
            &[MealType::Breakfast],
        )
        .await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap().as_str(), "55555");
    }

    #[tokio::test]
    async fn test_create_saved_meal_without_description() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=saved_meal.create.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{"saved_meal_id": "55556"}"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = create_saved_meal(
            &config,
            &token,
            "Quick Lunch",
            None,
            &[MealType::Lunch],
        )
        .await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_create_saved_meal_parse_error() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=saved_meal.create.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"bad": "response"}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = create_saved_meal(&config, &token, "Test", None, &[MealType::Dinner]).await;
        assert!(matches!(result, Err(FatSecretError::ParseError(_))));
    }

    // ========================================================================
    // get_saved_meals tests
    // ========================================================================

    #[tokio::test]
    async fn test_get_saved_meals_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=saved_meals.get.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "saved_meals": {
                        "saved_meal": [
                            {
                                "saved_meal_id": "55555",
                                "saved_meal_name": "Breakfast Combo",
                                "saved_meal_description": "Eggs and toast",
                                "meals": "breakfast",
                                "calories": "350",
                                "carbohydrate": "30",
                                "protein": "20",
                                "fat": "15"
                            }
                        ]
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_saved_meals(&config, &token, None).await;
        assert!(result.is_ok());
        let meals = result.unwrap();
        assert_eq!(meals.len(), 1);
        assert_eq!(meals[0].saved_meal_name, "Breakfast Combo");
    }

    #[tokio::test]
    async fn test_get_saved_meals_with_filter() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=saved_meals.get.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{"saved_meals": {"saved_meal": []}}"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_saved_meals(&config, &token, Some(MealType::Lunch)).await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // get_saved_meal_items tests
    // ========================================================================

    #[tokio::test]
    async fn test_get_saved_meal_items_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=saved_meal_items.get.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "saved_meal_items": {
                        "saved_meal_id": "55555",
                        "item": [
                            {
                                "saved_meal_item_id": "111",
                                "food_id": "33691",
                                "food_entry_name": "Eggs",
                                "serving_id": "34321",
                                "number_of_units": "2.0",
                                "calories": "180",
                                "carbohydrate": "2",
                                "protein": "12",
                                "fat": "14"
                            }
                        ]
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();
        let meal_id = SavedMealId::new("55555");

        let result = get_saved_meal_items(&config, &token, &meal_id).await;
        assert!(result.is_ok());
        let items = result.unwrap();
        assert_eq!(items.len(), 1);
        assert_eq!(items[0].food_entry_name, "Eggs");
    }

    // ========================================================================
    // delete_saved_meal tests
    // ========================================================================

    #[tokio::test]
    async fn test_delete_saved_meal_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=saved_meal.delete.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"success": {"value": "1"}}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();
        let meal_id = SavedMealId::new("55555");

        let result = delete_saved_meal(&config, &token, &meal_id).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_delete_saved_meal_failure() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=saved_meal.delete.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"success": {"value": "0"}}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();
        let meal_id = SavedMealId::new("55555");

        let result = delete_saved_meal(&config, &token, &meal_id).await;
        assert!(result.is_err());
    }

    // ========================================================================
    // edit_saved_meal tests
    // ========================================================================

    #[tokio::test]
    async fn test_edit_saved_meal_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=saved_meal.update.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"success": {"value": "1"}}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();
        let meal_id = SavedMealId::new("55555");

        let result = edit_saved_meal(
            &config,
            &token,
            &meal_id,
            Some("Updated Name"),
            Some("Updated description"),
            Some(&[MealType::Dinner]),
        )
        .await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_edit_saved_meal_partial_update() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=saved_meal.update.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"success": {"value": "1"}}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();
        let meal_id = SavedMealId::new("55555");

        let result = edit_saved_meal(&config, &token, &meal_id, Some("New Name"), None, None).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_edit_saved_meal_failure() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=saved_meal.update.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"success": {"value": "0"}}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();
        let meal_id = SavedMealId::new("55555");

        let result = edit_saved_meal(&config, &token, &meal_id, Some("Test"), None, None).await;
        assert!(result.is_err());
    }

    // ========================================================================
    // Error handling tests
    // ========================================================================

    #[tokio::test]
    async fn test_api_error_response() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{"error": {"code": 106, "message": "Invalid ID value"}}"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();
        let meal_id = SavedMealId::new("invalid");

        let result = get_saved_meal_items(&config, &token, &meal_id).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_http_error_response() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .respond_with(ResponseTemplate::new(500).set_body_string("Server Error"))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_saved_meals(&config, &token, None).await;
        assert!(result.is_err());
    }
}
