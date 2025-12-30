//! FatSecret Recipe API client

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
        FatSecretError::ParseError(format!("Failed to parse recipe: {}. Body: {}", e, body))
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

/// Get all recipe types (recipe_types.get.v2 - 2-legged)
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
