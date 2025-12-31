//! `FatSecret` Food Diary API Client Implementation
//!
//! This module implements the HTTP client layer for the `FatSecret` Food Diary API.
//! It handles request construction, response parsing, and error handling for all
//! diary-related operations.
//!
//! # Purpose
//!
//! This client module provides the low-level implementation details for:
//! - Making authenticated API requests via OAuth 1.0a
//! - Serializing input types to API parameters
//! - Deserializing JSON responses to typed structs
//! - Handling API-specific response formats and edge cases
//!
//! # Authentication
//!
//! All functions require:
//! - [`FatSecretConfig`] - API credentials (consumer key/secret)
//! - [`AccessToken`] - User-specific OAuth token (obtained via 3-legged flow)
//!
//! The actual OAuth signing is handled by [`make_authenticated_request`] from
//! the core HTTP module.
//!
//! # API Methods
//!
//! ## Core CRUD Operations
//! - [`create_food_entry`] - Add new food to diary (database or custom)
//! - [`get_food_entry`] - Retrieve single entry by ID
//! - [`get_food_entries`] - Get all entries for a date
//! - [`edit_food_entry`] - Update portion size or meal type
//! - [`delete_food_entry`] - Remove entry from diary
//!
//! ## Summaries
//! - [`get_month_summary`] - Aggregated nutrition totals by day for a month
//!
//! ## Copy/Template Operations
//! - [`copy_entries`] - Copy entire day of entries to another date
//! - [`copy_meal`] - Copy specific meal entries between dates
//! - [`commit_day`] - Finalize a day's entries (marks as complete)
//! - [`save_template`] - Save day's entries as reusable template
//!
//! # Response Handling
//!
//! The `FatSecret` API has quirks that this module handles:
//! - Single items may be returned as objects OR arrays (handled by `deserialize_single_or_vec`)
//! - Numeric values may be strings or numbers (handled by `deserialize_flexible_*`)
//! - Nested wrapper objects (e.g., `{"food_entry": {...}}`)
//!
//! # Key Types
//!
//! - [`FoodEntry`] - Complete food diary entry
//! - [`FoodEntryInput`] - Input for creating entries
//! - [`FoodEntryUpdate`] - Partial updates for existing entries
//! - [`FoodEntryId`] - Type-safe entry identifier
//! - [`MonthSummary`] - Monthly aggregated data
//! - [`MealType`] - Enum for breakfast/lunch/dinner/snack
//!
//! # Usage Example
//!
//! ```rust,no_run
//! use meal_planner::fatsecret::{`FatSecretConfig`, `AccessToken`};
//! use meal_planner::fatsecret::diary::{
//!     create_food_entry, get_food_entries, edit_food_entry,
//!     FoodEntryInput, FoodEntryUpdate, `MealType`,
//! };
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = `FatSecretConfig`::from_env()?;
//! let token = `AccessToken`::new("`oauth_token`", "oauth_secret");
//! let `date_int` = 19723; // 2024-01-01
//!
//! // Create a new entry
//! let input = FoodEntryInput::`FromFood` {
//!     `food_id`: "12345".to_string(),
//!     food_entry_name: "Oatmeal".to_string(),
//!     `serving_id`: "67890".to_string(),
//!     number_of_units: 1.5,
//!     meal: `MealType`::Breakfast,
//!     `date_int`,
//! };
//! let entry_id = create_food_entry(&config, &token, input).await?;
//!
//! // Update the portion size
//! let update = FoodEntryUpdate::new().with_units(2.0);
//! edit_food_entry(&config, &token, &entry_id, update).await?;
//!
//! // Get all entries for the day
//! let entries = get_food_entries(&config, &token, `date_int`).await?;
//! println!("Total entries: {}", entries.len());
//! # Ok(())
//! # }
//! ```
//!
//! # Error Handling
//!
//! Functions return `Result<T, FatSecretError>` which covers:
//! - HTTP errors (network, timeout, status codes)
//! - OAuth errors (invalid/revoked tokens)
//! - Parse errors (unexpected API response format)
//! - API errors (invalid parameters, rate limits)
//!
//! # Implementation Notes
//!
//! - All API methods use the `food_entry.*` or `food_entries.*` endpoint namespace
//! - Date parameters use `date_int` (days since Unix epoch)
//! - Tracing is enabled on key operations for debugging
//! - Response deserialization is strict - unknown fields cause errors

use std::collections::HashMap;

use crate::fatsecret::core::http::make_authenticated_request;
use crate::fatsecret::core::{AccessToken, FatSecretConfig, FatSecretError};
use serde::Deserialize;
use tracing::{info, instrument};

use super::types::{FoodEntry, FoodEntryId, FoodEntryInput, FoodEntryUpdate, MonthSummary};

// ============================================================================
// Response Wrappers
// ============================================================================

#[derive(Debug, Deserialize)]
struct FoodEntryResponse {
    food_entry: FoodEntry,
}

#[derive(Debug, Deserialize)]
struct FoodEntriesWrapper {
    #[serde(
        default,
        deserialize_with = "crate::fatsecret::core::serde_utils::deserialize_single_or_vec"
    )]
    food_entry: Vec<FoodEntry>,
}

#[derive(Debug, Deserialize)]
struct FoodEntriesResponse {
    food_entries: FoodEntriesWrapper,
}

#[derive(Debug, Deserialize)]
struct FoodEntryIdValue {
    value: String,
}

#[derive(Debug, Deserialize)]
struct CreateEntryResponse {
    food_entry_id: FoodEntryIdValue,
}

#[derive(Debug, Deserialize)]
struct MonthResponse {
    month: MonthSummary,
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Build API parameters from a `FoodEntryInput`
fn build_entry_params(input: &FoodEntryInput) -> HashMap<String, String> {
    let mut params = HashMap::new();
    match input {
        FoodEntryInput::FromFood {
            food_id,
            food_entry_name,
            serving_id,
            number_of_units,
            meal,
            date_int,
        } => {
            params.insert("food_id".to_string(), food_id.clone());
            params.insert("food_entry_name".to_string(), food_entry_name.clone());
            params.insert("serving_id".to_string(), serving_id.clone());
            params.insert("number_of_units".to_string(), number_of_units.to_string());
            params.insert("meal".to_string(), meal.to_api_string().to_string());
            params.insert("date_int".to_string(), date_int.to_string());
        }
        FoodEntryInput::Custom {
            food_entry_name,
            serving_description,
            number_of_units,
            meal,
            date_int,
            calories,
            carbohydrate,
            protein,
            fat,
        } => {
            params.insert("food_entry_name".to_string(), food_entry_name.clone());
            params.insert(
                "serving_description".to_string(),
                serving_description.clone(),
            );
            params.insert("number_of_units".to_string(), number_of_units.to_string());
            params.insert("meal".to_string(), meal.to_api_string().to_string());
            params.insert("date_int".to_string(), date_int.to_string());
            params.insert("calories".to_string(), calories.to_string());
            params.insert("carbohydrate".to_string(), carbohydrate.to_string());
            params.insert("protein".to_string(), protein.to_string());
            params.insert("fat".to_string(), fat.to_string());
        }
    }
    params
}

// ============================================================================
// Public API Functions
// ============================================================================

/// Create a new food entry in the user's diary
#[instrument(skip(config, token))]
pub async fn create_food_entry(
    config: &FatSecretConfig,
    token: &AccessToken,
    input: FoodEntryInput,
) -> Result<FoodEntryId, FatSecretError> {
    let params = build_entry_params(&input);
    info!(target: "fatsecret", "Creating food entry: {}", input.food_entry_name());

    let body = make_authenticated_request(config, token, "food_entry.create", params).await?;
    let response: CreateEntryResponse = serde_json::from_str(&body)
        .map_err(|e| FatSecretError::ParseError(format!("Failed to parse create response: {e}")))?;

    let id = FoodEntryId::new(response.food_entry_id.value);
    info!(target: "fatsecret", "Created food entry: {}", id.as_str());

    Ok(id)
}

/// Get a specific food entry by ID
pub async fn get_food_entry(
    config: &FatSecretConfig,
    token: &AccessToken,
    entry_id: &FoodEntryId,
) -> Result<FoodEntry, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("food_entry_id".to_string(), entry_id.as_str().to_string());

    let body = make_authenticated_request(config, token, "food_entry.get", params).await?;
    let response: FoodEntryResponse = serde_json::from_str(&body)
        .map_err(|e| FatSecretError::ParseError(format!("Failed to parse food entry: {e}")))?;

    Ok(response.food_entry)
}

/// Get all food entries for a specific date
pub async fn get_food_entries(
    config: &FatSecretConfig,
    token: &AccessToken,
    date_int: i32,
) -> Result<Vec<FoodEntry>, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("date_int".to_string(), date_int.to_string());

    let body = make_authenticated_request(config, token, "food_entries.get", params).await?;
    let response: FoodEntriesResponse = serde_json::from_str(&body)
        .map_err(|e| FatSecretError::ParseError(format!("Failed to parse food entries: {e}")))?;

    Ok(response.food_entries.food_entry)
}

/// Edit an existing food entry
pub async fn edit_food_entry(
    config: &FatSecretConfig,
    token: &AccessToken,
    entry_id: &FoodEntryId,
    update: FoodEntryUpdate,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("food_entry_id".to_string(), entry_id.as_str().to_string());

    if let Some(units) = update.number_of_units {
        params.insert("number_of_units".to_string(), units.to_string());
    }

    if let Some(meal) = update.meal {
        params.insert("meal".to_string(), meal.to_api_string().to_string());
    }

    make_authenticated_request(config, token, "food_entry.edit", params).await?;
    Ok(())
}

/// Delete a food entry
pub async fn delete_food_entry(
    config: &FatSecretConfig,
    token: &AccessToken,
    entry_id: &FoodEntryId,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("food_entry_id".to_string(), entry_id.as_str().to_string());

    make_authenticated_request(config, token, "food_entry.delete", params).await?;
    Ok(())
}

/// Get monthly summary of food entries
pub async fn get_month_summary(
    config: &FatSecretConfig,
    token: &AccessToken,
    date_int: i32,
) -> Result<MonthSummary, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("date_int".to_string(), date_int.to_string());

    let body = make_authenticated_request(config, token, "food_entries.get_month", params).await?;
    let response: MonthResponse = serde_json::from_str(&body)
        .map_err(|e| FatSecretError::ParseError(format!("Failed to parse month summary: {e}")))?;

    Ok(response.month)
}

// ============================================================================
// Copy/Template Operations
// ============================================================================

/// Copy all food entries from one date to another
pub async fn copy_entries(
    config: &FatSecretConfig,
    token: &AccessToken,
    from_date_int: i32,
    to_date_int: i32,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("from_date_int".to_string(), from_date_int.to_string());
    params.insert("to_date_int".to_string(), to_date_int.to_string());

    make_authenticated_request(config, token, "food_entry.copy", params).await?;
    Ok(())
}

/// Copy entries for a specific meal from one date/meal to another
#[allow(clippy::too_many_arguments)] // API requires all these params
pub async fn copy_meal(
    config: &FatSecretConfig,
    token: &AccessToken,
    from_date_int: i32,
    from_meal: crate::fatsecret::diary::types::MealType,
    to_date_int: i32,
    to_meal: crate::fatsecret::diary::types::MealType,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("from_date_int".to_string(), from_date_int.to_string());
    params.insert(
        "from_meal".to_string(),
        from_meal.to_api_string().to_string(),
    );
    params.insert("to_date_int".to_string(), to_date_int.to_string());
    params.insert("to_meal".to_string(), to_meal.to_api_string().to_string());

    make_authenticated_request(config, token, "food_entry.copy_meal", params).await?;
    Ok(())
}

/// Commit/finalize a day's diary entries
pub async fn commit_day(
    config: &FatSecretConfig,
    token: &AccessToken,
    date_int: i32,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("date_int".to_string(), date_int.to_string());

    make_authenticated_request(config, token, "food_entry.commit_day", params).await?;
    Ok(())
}

/// Save a day's entries as a reusable template
pub async fn save_template(
    config: &FatSecretConfig,
    token: &AccessToken,
    date_int: i32,
    template_name: &str,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("date_int".to_string(), date_int.to_string());
    params.insert("template_name".to_string(), template_name.to_string());

    make_authenticated_request(config, token, "food_entry.save_template", params).await?;
    Ok(())
}
