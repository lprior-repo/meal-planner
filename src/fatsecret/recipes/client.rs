//! `FatSecret` Recipe API client functions.
//!
//! This module provides async functions for interacting with the `FatSecret` Recipe API.
//! All functions use 2-legged OAuth authentication and return structured recipe data.
//!
//! # Key Functions
//!
//! - [`get_recipe`] - Retrieve complete recipe details by ID (`recipe.get.v2`)
//! - [`search_recipes`] - Search recipes with filtering and pagination (`recipes.search.v3`)
//! - [`autocomplete_recipes`] - Get recipe name suggestions (`recipes.autocomplete.v2`)
//! - [`get_recipe_types`] - List available recipe categories (`recipe_types.get.v2`)
//!
//! # Usage Example
//!
//! ```no_run
//! use meal_planner::fatsecret::core::config::`FatSecretConfig`;
//! use meal_planner::fatsecret::recipes::client::{search_recipes, get_recipe};
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = `FatSecretConfig`::from_env()?;
//!
//! // Search for vegetarian pasta recipes
//! let results = search_recipes(
//!     &config,
//!     "pasta",
//!     Some(20),           // max_results
//!     Some(0),            // page_number
//!     Some("vegetarian")  // recipe_type
//! ).await?;
//!
//! println!("Found {} recipes", results.total_results);
//!
//! // Get detailed recipe information
//! for result in results.recipes.iter().take(3) {
//!     let recipe = get_recipe(&config, &result.`recipe_id`).await?;
//!     println!("\n{}", recipe.recipe_name);
//!     println!("Calories: {:?}", recipe.calories);
//!     println!("Prep time: {:?} min", recipe.preparation_time_min);
//!     println!("Ingredients: {}", recipe.ingredients.ingredients.len());
//! }
//! # Ok(())
//! # }
//! ```
//!
//! # Error Handling
//!
//! All functions return `Result<T, FatSecretError>` which handles:
//! - Network errors during API requests
//! - Authentication failures (invalid credentials)
//! - JSON parsing errors (malformed API responses)
//! - API-specific errors (invalid recipe ID, etc.)
//!
//! # API Rate Limits
//!
//! The `FatSecret` API has rate limits that vary by subscription tier.
//! Consider implementing retry logic with exponential backoff for production use.

use crate::fatsecret::core::config::FatSecretConfig;
use crate::fatsecret::core::errors::FatSecretError;
use crate::fatsecret::core::http::make_api_request;
use crate::fatsecret::recipes::types::{
    Recipe, RecipeAutocompleteResponseWrapper, RecipeId, RecipeResponseWrapper,
    RecipeSearchResponse, RecipeSearchResponseWrapper, RecipeSuggestion, RecipeType,
    RecipeTypesResponseWrapper,
};
use std::collections::HashMap;

/// Get recipe details by ID (recipe.get.v2 - 2-legged)
pub async fn get_recipe(
    config: &FatSecretConfig,
    recipe_id: &RecipeId,
) -> Result<Recipe, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("recipe_id".to_string(), recipe_id.as_str().to_string());

    let body = make_api_request(config, "recipe.get.v2", params).await?;
    let response: RecipeResponseWrapper = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!("Failed to parse recipe: {e}. Body: {body}"))
    })?;

    Ok(response.recipe)
}

/// Search recipes (recipes.search.v3 - 2-legged)
pub async fn search_recipes(
    config: &FatSecretConfig,
    search_expression: &str,
    max_results: Option<i32>,
    page_number: Option<i32>,
    recipe_type: Option<&str>,
) -> Result<RecipeSearchResponse, FatSecretError> {
    let mut params = HashMap::new();
    params.insert(
        "search_expression".to_string(),
        search_expression.to_string(),
    );

    if let Some(n) = max_results {
        params.insert("max_results".to_string(), n.to_string());
    }
    if let Some(n) = page_number {
        params.insert("page_number".to_string(), n.to_string());
    }
    if let Some(t) = recipe_type {
        params.insert("recipe_type".to_string(), t.to_string());
    }

    let body = make_api_request(config, "recipes.search.v3", params).await?;
    let response: RecipeSearchResponseWrapper = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse recipe search: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.recipes)
}

/// Autocomplete recipes (recipes.autocomplete.v2 - 2-legged)
pub async fn autocomplete_recipes(
    config: &FatSecretConfig,
    expression: &str,
) -> Result<Vec<RecipeSuggestion>, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("expression".to_string(), expression.to_string());

    let body = make_api_request(config, "recipes.autocomplete.v2", params).await?;
    let response: RecipeAutocompleteResponseWrapper = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse recipe autocomplete: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.suggestions.suggestions)
}

/// Get all recipe types (`recipe_types.get.v2` - 2-legged)
pub async fn get_recipe_types(config: &FatSecretConfig) -> Result<Vec<RecipeType>, FatSecretError> {
    let params = HashMap::new();

    let body = make_api_request(config, "recipe_types.get.v2", params).await?;
    let response: RecipeTypesResponseWrapper = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse recipe types: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.recipe_types.recipe_types)
}

#[cfg(test)]
mod tests {
    use super::*;
    use wiremock::matchers::{body_string_contains, method, path};
    use wiremock::{Mock, MockServer, ResponseTemplate};

    fn test_config(mock_server: &MockServer) -> FatSecretConfig {
        FatSecretConfig::with_base_url("test_key", "test_secret", mock_server.uri())
    }

    // ========================================================================
    // get_recipe tests
    // ========================================================================

    #[tokio::test]
    async fn test_get_recipe_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=recipe.get.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "recipe": {
                        "recipe_id": "99999",
                        "recipe_name": "Grilled Chicken",
                        "recipe_description": "Simple grilled chicken breast",
                        "recipe_url": "https://www.fatsecret.com/recipe",
                        "calories": "165",
                        "carbohydrate": "0",
                        "protein": "31",
                        "fat": "4",
                        "preparation_time_min": "30",
                        "cooking_time_min": "20",
                        "number_of_servings": "4",
                        "ingredients": {
                            "ingredient": []
                        },
                        "directions": {
                            "direction": []
                        },
                        "recipe_categories": {
                            "recipe_category": []
                        },
                        "recipe_types": {
                            "recipe_type": []
                        }
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let recipe_id = RecipeId::new("99999");

        let result = get_recipe(&config, &recipe_id).await;
        assert!(result.is_ok());
        let recipe = result.unwrap();
        assert_eq!(recipe.recipe_name, "Grilled Chicken");
    }

    #[tokio::test]
    async fn test_get_recipe_parse_error() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=recipe.get.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"invalid": "data"}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let recipe_id = RecipeId::new("99999");

        let result = get_recipe(&config, &recipe_id).await;
        assert!(matches!(result, Err(FatSecretError::ParseError(_))));
    }

    // ========================================================================
    // search_recipes tests
    // ========================================================================

    #[tokio::test]
    async fn test_search_recipes_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=recipes.search.v3"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "recipes": {
                        "recipe": [
                            {
                                "recipe_id": "99999",
                                "recipe_name": "Pasta Primavera",
                                "recipe_description": "Classic Italian pasta",
                                "recipe_url": "https://www.fatsecret.com/recipe/99999"
                            }
                        ],
                        "max_results": "20",
                        "total_results": "100",
                        "page_number": "0"
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);

        let result = search_recipes(&config, "pasta", Some(20), Some(0), None).await;
        assert!(result.is_ok());
        let response = result.unwrap();
        assert_eq!(response.recipes.len(), 1);
        assert_eq!(response.total_results, 100);
    }

    #[tokio::test]
    async fn test_search_recipes_with_type() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=recipes.search.v3"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "recipes": {
                        "recipe": [],
                        "max_results": "20",
                        "total_results": "0",
                        "page_number": "0"
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);

        let result = search_recipes(&config, "salad", None, None, Some("vegetarian")).await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // autocomplete_recipes tests
    // ========================================================================

    #[tokio::test]
    async fn test_autocomplete_recipes_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=recipes.autocomplete.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "suggestions": {
                        "suggestion": [
                            {"recipe_id": "1", "recipe_name": "Chicken Curry"},
                            {"recipe_id": "2", "recipe_name": "Chicken Stir Fry"}
                        ]
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);

        let result = autocomplete_recipes(&config, "chick").await;
        assert!(result.is_ok());
        let suggestions = result.unwrap();
        assert_eq!(suggestions.len(), 2);
    }

    #[tokio::test]
    async fn test_autocomplete_recipes_parse_error() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=recipes.autocomplete.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"bad": "format"}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);

        let result = autocomplete_recipes(&config, "test").await;
        assert!(matches!(result, Err(FatSecretError::ParseError(_))));
    }

    // ========================================================================
    // get_recipe_types tests
    // ========================================================================

    #[tokio::test]
    async fn test_get_recipe_types_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=recipe_types.get.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "recipe_types": {
                        "recipe_type": ["Appetizer", "Main Dish", "Dessert"]
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);

        let result = get_recipe_types(&config).await;
        assert!(result.is_ok());
        let types = result.unwrap();
        assert_eq!(types.len(), 3);
    }

    #[tokio::test]
    async fn test_get_recipe_types_parse_error() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=recipe_types.get.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"invalid": true}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);

        let result = get_recipe_types(&config).await;
        assert!(matches!(result, Err(FatSecretError::ParseError(_))));
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
        let recipe_id = RecipeId::new("invalid");

        let result = get_recipe(&config, &recipe_id).await;
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

        let result = search_recipes(&config, "test", None, None, None).await;
        assert!(result.is_err());
    }
}
