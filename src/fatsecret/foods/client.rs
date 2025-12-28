//! FatSecret Foods API client
//!
//! Provides type-safe wrappers around the base FatSecret client.
//! Ported from src/meal_planner/fatsecret/foods/client.gleam

use std::collections::HashMap;

use serde::Deserialize;

use crate::fatsecret::core::{make_api_request, FatSecretConfig, FatSecretError};
use crate::fatsecret::foods::types::{
    Food, FoodAutocompleteResponse, FoodId, FoodSearchResponse,
};

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

/// Get complete food details by ID using food.get.v5 endpoint
///
/// This is a 2-legged OAuth request (no user token required).
pub async fn get_food(
    config: &FatSecretConfig,
    food_id: &FoodId,
) -> Result<Food, FatSecretError> {
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

/// Search for foods using the foods.search endpoint
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
