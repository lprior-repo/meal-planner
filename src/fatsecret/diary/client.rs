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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::fatsecret::diary::types::MealType;
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
    // build_entry_params tests
    // ========================================================================

    #[test]
    fn test_build_entry_params_from_food() {
        let input = FoodEntryInput::FromFood {
            food_id: "12345".to_string(),
            food_entry_name: "Oatmeal".to_string(),
            serving_id: "67890".to_string(),
            number_of_units: 1.5,
            meal: MealType::Breakfast,
            date_int: 19723,
        };
        let params = build_entry_params(&input);

        assert_eq!(params.get("food_id"), Some(&"12345".to_string()));
        assert_eq!(params.get("food_entry_name"), Some(&"Oatmeal".to_string()));
        assert_eq!(params.get("serving_id"), Some(&"67890".to_string()));
        assert_eq!(params.get("number_of_units"), Some(&"1.5".to_string()));
        assert_eq!(params.get("meal"), Some(&"breakfast".to_string()));
        assert_eq!(params.get("date_int"), Some(&"19723".to_string()));
    }

    #[test]
    fn test_build_entry_params_custom() {
        let input = FoodEntryInput::Custom {
            food_entry_name: "Custom Meal".to_string(),
            serving_description: "1 bowl".to_string(),
            number_of_units: 2.0,
            meal: MealType::Lunch,
            date_int: 19724,
            calories: 350.0,
            carbohydrate: 45.0,
            protein: 15.0,
            fat: 12.0,
        };
        let params = build_entry_params(&input);

        assert_eq!(params.get("food_entry_name"), Some(&"Custom Meal".to_string()));
        assert_eq!(params.get("serving_description"), Some(&"1 bowl".to_string()));
        assert_eq!(params.get("number_of_units"), Some(&"2".to_string()));
        assert_eq!(params.get("meal"), Some(&"lunch".to_string()));
        assert_eq!(params.get("date_int"), Some(&"19724".to_string()));
        assert_eq!(params.get("calories"), Some(&"350".to_string()));
        assert_eq!(params.get("carbohydrate"), Some(&"45".to_string()));
        assert_eq!(params.get("protein"), Some(&"15".to_string()));
        assert_eq!(params.get("fat"), Some(&"12".to_string()));
    }

    // ========================================================================
    // create_food_entry tests
    // ========================================================================

    #[tokio::test]
    async fn test_create_food_entry_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food_entry.create"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{"food_entry_id": {"value": "99999"}}"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();
        let input = FoodEntryInput::FromFood {
            food_id: "12345".to_string(),
            food_entry_name: "Test Food".to_string(),
            serving_id: "67890".to_string(),
            number_of_units: 1.0,
            meal: MealType::Breakfast,
            date_int: 19723,
        };

        let result = create_food_entry(&config, &token, input).await;
        assert!(result.is_ok());
        assert_eq!(result.unwrap().as_str(), "99999");
    }

    #[tokio::test]
    async fn test_create_food_entry_parse_error() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food_entry.create"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"invalid": "response"}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();
        let input = FoodEntryInput::FromFood {
            food_id: "12345".to_string(),
            food_entry_name: "Test".to_string(),
            serving_id: "67890".to_string(),
            number_of_units: 1.0,
            meal: MealType::Breakfast,
            date_int: 19723,
        };

        let result = create_food_entry(&config, &token, input).await;
        assert!(matches!(result, Err(FatSecretError::ParseError(_))));
    }

    // ========================================================================
    // get_food_entry tests
    // ========================================================================

    #[tokio::test]
    async fn test_get_food_entry_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food_entry.get"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "food_entry": {
                        "food_entry_id": "11111",
                        "food_id": "33691",
                        "food_entry_name": "Chicken Breast",
                        "food_entry_description": "100g Chicken Breast",
                        "serving_id": "34321",
                        "number_of_units": "1.00",
                        "meal": "lunch",
                        "date_int": "19723",
                        "calories": "165",
                        "carbohydrate": "0",
                        "protein": "31.02",
                        "fat": "3.57"
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();
        let entry_id = FoodEntryId::new("11111");

        let result = get_food_entry(&config, &token, &entry_id).await;
        assert!(result.is_ok());
        let entry = result.unwrap();
        assert_eq!(entry.food_entry_id.as_str(), "11111");
        assert_eq!(entry.food_entry_name, "Chicken Breast");
    }

    #[tokio::test]
    async fn test_get_food_entry_parse_error() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food_entry.get"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"bad": "data"}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();
        let entry_id = FoodEntryId::new("11111");

        let result = get_food_entry(&config, &token, &entry_id).await;
        assert!(matches!(result, Err(FatSecretError::ParseError(_))));
    }

    // ========================================================================
    // get_food_entries tests
    // ========================================================================

    #[tokio::test]
    async fn test_get_food_entries_multiple() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food_entries.get"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "food_entries": {
                        "food_entry": [
                            {
                                "food_entry_id": "111",
                                "food_id": "33691",
                                "food_entry_name": "Eggs",
                                "food_entry_description": "2 large eggs",
                                "serving_id": "34321",
                                "number_of_units": "2.00",
                                "meal": "breakfast",
                                "date_int": "19723",
                                "calories": "180",
                                "carbohydrate": "1",
                                "protein": "12",
                                "fat": "14"
                            },
                            {
                                "food_entry_id": "222",
                                "food_id": "12345",
                                "food_entry_name": "Toast",
                                "food_entry_description": "1 slice toast",
                                "serving_id": "54321",
                                "number_of_units": "1.00",
                                "meal": "breakfast",
                                "date_int": "19723",
                                "calories": "80",
                                "carbohydrate": "15",
                                "protein": "2",
                                "fat": "1"
                            }
                        ]
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_food_entries(&config, &token, 19723).await;
        assert!(result.is_ok());
        let entries = result.unwrap();
        assert_eq!(entries.len(), 2);
        assert_eq!(entries[0].food_entry_name, "Eggs");
        assert_eq!(entries[1].food_entry_name, "Toast");
    }

    #[tokio::test]
    async fn test_get_food_entries_single() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food_entries.get"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "food_entries": {
                        "food_entry": {
                            "food_entry_id": "111",
                            "food_id": "33691",
                            "food_entry_name": "Salad",
                            "food_entry_description": "1 serving mixed salad",
                            "serving_id": "34321",
                            "number_of_units": "1.00",
                            "meal": "lunch",
                            "date_int": "19723",
                            "calories": "50",
                            "carbohydrate": "10",
                            "protein": "3",
                            "fat": "0"
                        }
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_food_entries(&config, &token, 19723).await;
        assert!(result.is_ok());
        let entries = result.unwrap();
        assert_eq!(entries.len(), 1);
    }

    #[tokio::test]
    async fn test_get_food_entries_empty() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food_entries.get"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{"food_entries": {"food_entry": []}}"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_food_entries(&config, &token, 19723).await;
        assert!(result.is_ok());
        assert!(result.unwrap().is_empty());
    }

    // ========================================================================
    // edit_food_entry tests
    // ========================================================================

    #[tokio::test]
    async fn test_edit_food_entry_units() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food_entry.edit"))
            .and(body_string_contains("number_of_units"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();
        let entry_id = FoodEntryId::new("11111");
        let update = FoodEntryUpdate::new().with_units(2.5);

        let result = edit_food_entry(&config, &token, &entry_id, update).await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_edit_food_entry_meal() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food_entry.edit"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();
        let entry_id = FoodEntryId::new("11111");
        let update = FoodEntryUpdate::new().with_meal(MealType::Dinner);

        let result = edit_food_entry(&config, &token, &entry_id, update).await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // delete_food_entry tests
    // ========================================================================

    #[tokio::test]
    async fn test_delete_food_entry_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food_entry.delete"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();
        let entry_id = FoodEntryId::new("11111");

        let result = delete_food_entry(&config, &token, &entry_id).await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // get_month_summary tests
    // ========================================================================

    #[tokio::test]
    async fn test_get_month_summary_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food_entries.get_month"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "month": {
                        "month": "1",
                        "year": "2024",
                        "day": [
                            {
                                "date_int": "19723",
                                "calories": "1800",
                                "carbohydrate": "200",
                                "protein": "100",
                                "fat": "60"
                            }
                        ]
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_month_summary(&config, &token, 19723).await;
        assert!(result.is_ok());
        let summary = result.unwrap();
        assert_eq!(summary.month, 1);
        assert!(!summary.days.is_empty());
    }

    // ========================================================================
    // copy_entries tests
    // ========================================================================

    #[tokio::test]
    async fn test_copy_entries_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food_entry.copy"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = copy_entries(&config, &token, 19723, 19724).await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // copy_meal tests
    // ========================================================================

    #[tokio::test]
    async fn test_copy_meal_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food_entry.copy_meal"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = copy_meal(
            &config,
            &token,
            19723,
            MealType::Breakfast,
            19724,
            MealType::Lunch,
        )
        .await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // commit_day tests
    // ========================================================================

    #[tokio::test]
    async fn test_commit_day_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food_entry.commit_day"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = commit_day(&config, &token, 19723).await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // save_template tests
    // ========================================================================

    #[tokio::test]
    async fn test_save_template_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=food_entry.save_template"))
            .and(body_string_contains("template_name"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = save_template(&config, &token, 19723, "My Breakfast").await;
        assert!(result.is_ok());
    }

    // ========================================================================
    // Error handling tests
    // ========================================================================

    #[tokio::test]
    async fn test_api_error_handling() {
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
        let entry_id = FoodEntryId::new("invalid");

        let result = get_food_entry(&config, &token, &entry_id).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_http_error_handling() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .respond_with(ResponseTemplate::new(500).set_body_string("Internal Server Error"))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_food_entries(&config, &token, 19723).await;
        assert!(result.is_err());
    }
}
