//! `FatSecret` Foods API Client Functions
//!
//! This module provides async functions for interacting with the `FatSecret` Foods API.
//! All functions are 2-legged OAuth requests (no user token required) and return
//! strongly-typed results or errors.
//!
//! # Architecture
//!
//! Each function follows this pattern:
//! 1. Build API parameters as `HashMap<String, String>`
//! 2. Call [`make_api_request`] with method name and params
//! 3. Deserialize JSON response through a wrapper type
//! 4. Return the inner domain type
//!
//! This provides a clean separation between API response shapes (which may have
//! nested wrapper objects) and domain types (which are flat and ergonomic).
//!
//! # API Methods
//!
//! | Function | `FatSecret` Method | Purpose |
//! |----------|-----------------|---------|
//! | [`get_food`] | `food.get.v5` | Get complete food details by ID |
//! | [`search_foods`] | `foods.search` | Search foods with pagination |
//! | [`search_foods_simple`] | `foods.search` | Search with defaults (page 0, max 20) |
//! | [`list_foods_with_options`] | `foods.search` | Search with optional page/max_results |
//! | [`autocomplete_foods`] | `foods.autocomplete.v2` | Get autocomplete suggestions |
//! | [`autocomplete_foods_with_options`] | `foods.autocomplete.v2` | Autocomplete with max_results |
//! | [`find_food_by_barcode`] | `food.find_id_for_barcode.v2` | Lookup food by barcode |
//!
//! # Examples
//!
//! ## Get food details by ID
//!
//! ```no_run
//! use meal_planner::fatsecret::foods::client::get_food;
//! use meal_planner::fatsecret::foods::types::FoodId;
//! use meal_planner::fatsecret::core::`FatSecretConfig`;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = `FatSecretConfig`::from_env()?;
//! let `food_id` = FoodId::new("12345");
//!
//! let food = get_food(&config, &`food_id`).await?;
//! println!("{} has {} servings",
//!     food.food_name,
//!     food.servings.serving.len()
//! );
//! # Ok(())
//! # }
//! ```
//!
//! ## Search foods with pagination
//!
//! ```no_run
//! use meal_planner::fatsecret::foods::client::search_foods;
//! use meal_planner::fatsecret::core::`FatSecretConfig`;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = `FatSecretConfig`::from_env()?;
//!
//! // Get page 1 (0-indexed) with max 50 results
//! let results = search_foods(&config, "salmon", 1, 50).await?;
//! println!("Page {}/{}: {} results",
//!     results.page_number + 1,
//!     (results.total_results / results.max_results) + 1,
//!     results.foods.len()
//! );
//! # Ok(())
//! # }
//! ```
//!
//! ## Autocomplete for search-as-you-type
//!
//! ```no_run
//! use meal_planner::fatsecret::foods::client::autocomplete_foods_with_options;
//! use meal_planner::fatsecret::core::`FatSecretConfig`;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = `FatSecretConfig`::from_env()?;
//!
//! // Get top 5 suggestions for "bro"
//! let suggestions = autocomplete_foods_with_options(&config, "bro", Some(5)).await?;
//! for suggestion in suggestions.suggestions {
//!     println!("{}", suggestion.food_name); // "Broccoli", "Brown Rice", etc.
//! }
//! # Ok(())
//! # }
//! ```
//!
//! # Error Handling
//!
//! All functions return [`Result<T, FatSecretError>`](crate::fatsecret::core::FatSecretError).
//! Common errors:
//!
//! - `ApiError` - `FatSecret` API returned an error (invalid params, not found, etc.)
//! - `HttpError` - Network/HTTP failure
//! - `ParseError` - Failed to deserialize response (API contract changed?)
//!
//! # See Also
//!
//! - [`crate::fatsecret::foods::types`] for all type definitions
//! - [`crate::fatsecret::core::make_api_request`] for the underlying request builder
//! - [`FatSecret` Platform API Reference](https://platform.fatsecret.com/api/)
//!
//! # Original Source
//!
//! Ported from `src/meal_planner/fatsecret/foods/client.gleam`

use std::collections::HashMap;

use serde::Deserialize;

use crate::fatsecret::core::{make_api_request, FatSecretConfig, FatSecretError};
use crate::fatsecret::foods::types::{Food, FoodAutocompleteResponse, FoodId, FoodSearchResponse};

// ============================================================================
// Response Wrappers
// ============================================================================

#[derive(Deserialize)]
struct FoodWrapper {
    food: Food,
}

#[derive(Deserialize)]
struct FoodsWrapper {
    foods: FoodSearchResponse,
}

#[derive(Deserialize)]
struct AutocompleteWrapper {
    suggestions: FoodAutocompleteResponse,
}

#[derive(Deserialize)]
struct BarcodeWrapper {
    food_id: BarcodeValue,
}

#[derive(Deserialize)]
struct BarcodeValue {
    value: String,
}

// ============================================================================
// Food Get API (food.get.v5)
// ============================================================================

/// Get complete food details by ID using `food.get`.v5 endpoint
///
/// This is a 2-legged OAuth request (no user token required).
pub async fn get_food(config: &FatSecretConfig, food_id: &FoodId) -> Result<Food, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("food_id".to_string(), food_id.as_str().to_string());
    params.insert("flag_default_serving".to_string(), "true".to_string());

    let response_json = make_api_request(config, "food.get.v5", params).await?;

    let wrapper: FoodWrapper = serde_json::from_str(&response_json)?;
    Ok(wrapper.food)
}

// ============================================================================
// Food Search API (foods.search)
// ============================================================================

/// Search for foods with optional pagination parameters
///
/// This is a 2-legged OAuth request (no user token required).
pub async fn list_foods_with_options(
    config: &FatSecretConfig,
    query: &str,
    page: Option<u32>,
    max_results: Option<u32>,
) -> Result<FoodSearchResponse, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("search_expression".to_string(), query.to_string());

    if let Some(p) = page {
        params.insert("page_number".to_string(), p.to_string());
    }

    if let Some(m) = max_results {
        params.insert("max_results".to_string(), m.to_string());
    }

    let response_json = make_api_request(config, "foods.search", params).await?;

    let wrapper: FoodsWrapper = serde_json::from_str(&response_json)?;
    Ok(wrapper.foods)
}

/// Search for foods using the `foods.search` endpoint
pub async fn search_foods(
    config: &FatSecretConfig,
    query: &str,
    page: u32,
    max_results: u32,
) -> Result<FoodSearchResponse, FatSecretError> {
    list_foods_with_options(config, query, Some(page), Some(max_results)).await
}

/// Simplified search with defaults (page 0, max 20 results)
pub async fn search_foods_simple(
    config: &FatSecretConfig,
    query: &str,
) -> Result<FoodSearchResponse, FatSecretError> {
    list_foods_with_options(config, query, None, None).await
}

// ============================================================================
// Food Barcode Lookup API (food.find_id_for_barcode.v2)
// ============================================================================

/// Find food ID by barcode using food.find_id_for_barcode.v2 endpoint
///
/// This is a 2-legged OAuth request (no user token required).
pub async fn find_food_by_barcode(
    config: &FatSecretConfig,
    barcode: &str,
    barcode_type: Option<&str>,
) -> Result<Food, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("barcode".to_string(), barcode.to_string());

    if let Some(bt) = barcode_type {
        params.insert("barcode_type".to_string(), bt.to_string());
    }

    let response_json = make_api_request(config, "food.find_id_for_barcode.v2", params).await?;

    let wrapper: BarcodeWrapper = serde_json::from_str(&response_json)?;
    let food_id = FoodId::new(wrapper.food_id.value);

    get_food(config, &food_id).await
}

// ============================================================================
// Food Autocomplete API (foods.autocomplete.v2)
// ============================================================================

/// Get food suggestions with optional max results using foods.autocomplete.v2 endpoint
///
/// This is a 2-legged OAuth request (no user token required).
pub async fn autocomplete_foods_with_options(
    config: &FatSecretConfig,
    expression: &str,
    max_results: Option<u32>,
) -> Result<FoodAutocompleteResponse, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("expression".to_string(), expression.to_string());

    if let Some(m) = max_results {
        params.insert("max_results".to_string(), m.to_string());
    }

    let response_json = make_api_request(config, "foods.autocomplete.v2", params).await?;

    let wrapper: AutocompleteWrapper = serde_json::from_str(&response_json)?;
    Ok(wrapper.suggestions)
}

/// Get food suggestions using foods.autocomplete.v2 endpoint
pub async fn autocomplete_foods(
    config: &FatSecretConfig,
    expression: &str,
) -> Result<FoodAutocompleteResponse, FatSecretError> {
    autocomplete_foods_with_options(config, expression, None).await
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
    // get_food tests
    // ========================================================================

    #[tokio::test]
    async fn test_get_food_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food.get.v5"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "food": {
                        "food_id": "33691",
                        "food_name": "Chicken Breast",
                        "food_type": "Generic",
                        "food_url": "https://www.fatsecret.com/chicken",
                        "servings": {
                            "serving": [
                                {
                                    "serving_id": "34321",
                                    "serving_description": "100 g",
                                    "serving_url": "https://www.fatsecret.com/serving",
                                    "metric_serving_amount": "100.000",
                                    "metric_serving_unit": "g",
                                    "number_of_units": "1.00",
                                    "measurement_description": "100g",
                                    "calories": "165",
                                    "carbohydrate": "0.00",
                                    "protein": "31.02",
                                    "fat": "3.57"
                                }
                            ]
                        }
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let food_id = FoodId::new("33691");

        let result = get_food(&config, &food_id).await;
        assert!(result.is_ok());
        let food = result.unwrap();
        assert_eq!(food.food_name, "Chicken Breast");
        assert_eq!(food.food_id.as_str(), "33691");
    }

    #[tokio::test]
    async fn test_get_food_parse_error() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food.get.v5"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"invalid": "data"}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let food_id = FoodId::new("33691");

        let result = get_food(&config, &food_id).await;
        assert!(result.is_err());
    }

    // ========================================================================
    // search_foods tests
    // ========================================================================

    #[tokio::test]
    async fn test_search_foods_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=foods.search"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "foods": {
                        "food": [
                            {
                                "food_id": "33691",
                                "food_name": "Chicken Breast",
                                "food_type": "Generic",
                                "food_description": "Per 100g - Calories: 165kcal",
                                "food_url": "https://www.fatsecret.com/chicken"
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

        let result = search_foods(&config, "chicken", 0, 20).await;
        assert!(result.is_ok());
        let response = result.unwrap();
        assert_eq!(response.foods.len(), 1);
        assert_eq!(response.total_results, 100);
    }

    #[tokio::test]
    async fn test_search_foods_simple_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=foods.search"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "foods": {
                        "food": [],
                        "max_results": "20",
                        "total_results": "0",
                        "page_number": "0"
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);

        let result = search_foods_simple(&config, "nonexistent").await;
        assert!(result.is_ok());
        assert!(result.unwrap().foods.is_empty());
    }

    #[tokio::test]
    async fn test_list_foods_with_options() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=foods.search"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "foods": {
                        "food": [],
                        "max_results": "50",
                        "total_results": "0",
                        "page_number": "2"
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);

        let result = list_foods_with_options(&config, "test", Some(2), Some(50)).await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // autocomplete_foods tests
    // ========================================================================

    #[tokio::test]
    async fn test_autocomplete_foods_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=foods.autocomplete.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "suggestions": {
                        "suggestion": [
                            {"food_id": "1", "food_name": "Chicken"},
                            {"food_id": "2", "food_name": "Chicken Breast"},
                            {"food_id": "3", "food_name": "Chicken Thigh"}
                        ]
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);

        let result = autocomplete_foods(&config, "chick").await;
        assert!(result.is_ok());
        let response = result.unwrap();
        assert_eq!(response.suggestions.len(), 3);
    }

    #[tokio::test]
    async fn test_autocomplete_foods_with_options() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=foods.autocomplete.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "suggestions": {
                        "suggestion": [{"food_id": "1", "food_name": "Test"}]
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);

        let result = autocomplete_foods_with_options(&config, "test", Some(5)).await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // find_food_by_barcode tests
    // ========================================================================

    #[tokio::test]
    async fn test_find_food_by_barcode_success() {
        let mock_server = MockServer::start().await;

        // First mock for barcode lookup
        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food.find_id_for_barcode.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{"food_id": {"value": "12345"}}"#,
            ))
            .mount(&mock_server)
            .await;

        // Second mock for food.get.v5
        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food.get.v5"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "food": {
                        "food_id": "12345",
                        "food_name": "Barcode Food",
                        "food_type": "Brand",
                        "food_url": "https://www.fatsecret.com/food",
                        "servings": {
                            "serving": []
                        }
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);

        let result = find_food_by_barcode(&config, "0123456789", None).await;
        assert!(result.is_ok());
        let food = result.unwrap();
        assert_eq!(food.food_name, "Barcode Food");
    }

    #[tokio::test]
    async fn test_find_food_by_barcode_with_type() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food.find_id_for_barcode.v2"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{"food_id": {"value": "12345"}}"#,
            ))
            .mount(&mock_server)
            .await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food.get.v5"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "food": {
                        "food_id": "12345",
                        "food_name": "UPC Food",
                        "food_type": "Brand",
                        "food_url": "https://www.fatsecret.com/food",
                        "servings": {"serving": []}
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);

        let result = find_food_by_barcode(&config, "0123456789", Some("UPC")).await;
        assert!(result.is_ok());
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
        let food_id = FoodId::new("invalid");

        let result = get_food(&config, &food_id).await;
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

        let result = search_foods(&config, "test", 0, 20).await;
        assert!(result.is_err());
    }
}
