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
//! | [`list_foods_with_options`] | `foods.search` | Search with optional `page/max_results` |
//! | [`autocomplete_foods`] | `foods.autocomplete.v2` | Get autocomplete suggestions |
//! | [`autocomplete_foods_with_options`] | `foods.autocomplete.v2` | Autocomplete with `max_results` |
//! | [`find_food_by_barcode`] | `food.find_id_for_barcode.v2` | Lookup food by barcode |
//!
//! # Examples
//!
//! ## Get food details by ID
//!
//! ```no_run
//! use meal_planner::fatsecret::foods::client::get_food;
//! use meal_planner::fatsecret::foods::types::FoodId;
//! use meal_planner::fatsecret::core::FatSecretConfig;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = FatSecretConfig::from_env()?;
//! let food_id = FoodId::new("12345");
//!
//! let food = get_food(&config, &food_id).await?;
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
//! use meal_planner::fatsecret::core::FatSecretConfig;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = FatSecretConfig::from_env()?;
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
//! use meal_planner::fatsecret::core::FatSecretConfig;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = FatSecretConfig::from_env()?;
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

/// Find food ID by barcode using `food.find_id_for_barcode.v2` endpoint
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
