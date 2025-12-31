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
