//! FatSecret SDK Food Diary API client
//!
//! 3-legged authenticated API calls for food diary management.
//! All operations require user OAuth access token.

use std::collections::HashMap;

use crate::fatsecret::core::{AccessToken, FatSecretConfig, FatSecretError};
use crate::fatsecret::core::http::make_authenticated_request;
use tracing::{info, instrument};
use serde::Deserialize;

use super::types::{
    FoodEntry, FoodEntryId, FoodEntryInput, FoodEntryUpdate, MonthSummary,
};

// ============================================================================
// Response Wrappers
// ============================================================================

#[derive(Debug, Deserialize)]
struct FoodEntryResponse {
    food_entry: FoodEntry,
}

#[derive(Debug, Deserialize)]
struct FoodEntriesWrapper {
    #[serde(default, deserialize_with = "crate::fatsecret::core::serde_utils::deserialize_single_or_vec")]
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
// Public API Functions
// ============================================================================

/// Create a new food entry in the user's diary
#[instrument(skip(config, token))]
pub async fn create_food_entry(
    config: &FatSecretConfig,
    token: &AccessToken,
    input: FoodEntryInput,
) -> Result<FoodEntryId, FatSecretError> {
    let mut params = HashMap::new();
    match &input {
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
            params.insert("serving_description".to_string(), serving_description.clone());
            params.insert("number_of_units".to_string(), number_of_units.to_string());
            params.insert("meal".to_string(), meal.to_api_string().to_string());
            params.insert("date_int".to_string(), date_int.to_string());
            params.insert("calories".to_string(), calories.to_string());
            params.insert("carbohydrate".to_string(), carbohydrate.to_string());
            params.insert("protein".to_string(), protein.to_string());
            params.insert("fat".to_string(), fat.to_string());
        }
    }

    info!(target: "fatsecret", "Creating food entry: {}", input.food_entry_name());

    let body = make_authenticated_request(config, token, "food_entry.create", params).await?;
    let response: CreateEntryResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!("Failed to parse create response: {}", e))
    })?;
    
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
    let response: FoodEntryResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!("Failed to parse food entry: {}", e))
    })?;
    
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
    let response: FoodEntriesResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!("Failed to parse food entries: {}", e))
    })?;

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
    let response: MonthResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!("Failed to parse month summary: {}", e))
    })?;
    
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
    params.insert("from_meal".to_string(), from_meal.to_api_string().to_string());
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
