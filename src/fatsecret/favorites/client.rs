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
    // add_favorite_food tests
    // ========================================================================

    #[tokio::test]
    async fn test_add_favorite_food_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food.add_favorite"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = add_favorite_food(&config, &token, "12345").await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // delete_favorite_food tests
    // ========================================================================

    #[tokio::test]
    async fn test_delete_favorite_food_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food.delete_favorite"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = delete_favorite_food(&config, &token, "12345").await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // get_favorite_foods tests
    // ========================================================================

    #[tokio::test]
    async fn test_get_favorite_foods_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=foods.get_favorites.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "food": [
                        {
                            "food_id": "33691",
                            "food_name": "Chicken Breast",
                            "food_type": "Generic",
                            "food_description": "Per 100g - Calories: 165kcal",
                            "food_url": "https://www.fatsecret.com/chicken",
                            "serving_id": "34321",
                            "number_of_units": "1.00"
                        }
                    ]
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_favorite_foods(&config, &token, Some(50), Some(0)).await;
        assert!(result.is_ok());
        let foods = result.unwrap();
        assert_eq!(foods.len(), 1);
        assert_eq!(foods[0].food_name, "Chicken Breast");
    }

    #[tokio::test]
    async fn test_get_favorite_foods_no_pagination() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=foods.get_favorites.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"food": []}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_favorite_foods(&config, &token, None, None).await;
        assert!(result.is_ok());
        assert!(result.unwrap().is_empty());
    }

    // ========================================================================
    // get_most_eaten tests
    // ========================================================================

    #[tokio::test]
    async fn test_get_most_eaten_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=foods.get_most_eaten.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "food": [
                        {
                            "food_id": "33691",
                            "food_name": "Chicken Breast",
                            "food_type": "Generic",
                            "food_description": "Per 100g - Calories: 165kcal",
                            "food_url": "https://www.fatsecret.com/chicken",
                            "serving_id": "34321",
                            "number_of_units": "2.50"
                        }
                    ]
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_most_eaten(&config, &token, None).await;
        assert!(result.is_ok());
        let foods = result.unwrap();
        assert_eq!(foods.len(), 1);
    }

    #[tokio::test]
    async fn test_get_most_eaten_with_meal_filter() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=foods.get_most_eaten.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"food": []}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_most_eaten(&config, &token, Some(MealFilter::Breakfast)).await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // get_recently_eaten tests
    // ========================================================================

    #[tokio::test]
    async fn test_get_recently_eaten_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=foods.get_recently_eaten.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "food": [
                        {
                            "food_id": "5055",
                            "food_name": "Brown Rice",
                            "food_type": "Generic",
                            "food_description": "Per cup - Calories: 216kcal",
                            "food_url": "https://www.fatsecret.com/rice",
                            "serving_id": "5056",
                            "number_of_units": "1.00"
                        }
                    ]
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_recently_eaten(&config, &token, None).await;
        assert!(result.is_ok());
        let foods = result.unwrap();
        assert_eq!(foods.len(), 1);
        assert_eq!(foods[0].food_name, "Brown Rice");
    }

    #[tokio::test]
    async fn test_get_recently_eaten_with_meal_filter() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=foods.get_recently_eaten.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"food": []}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_recently_eaten(&config, &token, Some(MealFilter::Lunch)).await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // add_favorite_recipe tests
    // ========================================================================

    #[tokio::test]
    async fn test_add_favorite_recipe_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=recipe.add_favorite"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = add_favorite_recipe(&config, &token, "99999").await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // delete_favorite_recipe tests
    // ========================================================================

    #[tokio::test]
    async fn test_delete_favorite_recipe_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=recipe.delete_favorite"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = delete_favorite_recipe(&config, &token, "99999").await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // get_favorite_recipes tests
    // ========================================================================

    #[tokio::test]
    async fn test_get_favorite_recipes_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=recipes.get_favorites.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "recipe": [
                        {
                            "recipe_id": "99999",
                            "recipe_name": "Grilled Chicken",
                            "recipe_description": "Simple grilled chicken breast",
                            "recipe_url": "https://www.fatsecret.com/recipe/99999"
                        }
                    ]
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_favorite_recipes(&config, &token, Some(20), Some(0)).await;
        assert!(result.is_ok());
        let recipes = result.unwrap();
        assert_eq!(recipes.len(), 1);
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

        let result = add_favorite_food(&config, &token, "invalid").await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_parse_error_handling() {
        let mock_server = MockServer::start().await;

        // The response type has #[serde(default)] so missing fields won't cause errors.
        // Use an invalid "food" field value to trigger a parse error.
        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=foods.get_favorites.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"food": "not_an_array_or_object"}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_favorite_foods(&config, &token, None, None).await;
        assert!(matches!(result, Err(FatSecretError::ParseError(_))));
    }
}
