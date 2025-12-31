//! FatSecret Weight API client functions
//!
//! This module contains the client functions for interacting with the FatSecret
//! Platform API's weight management endpoints. All functions require authentication
//! via OAuth 1.0a access tokens.
//!
//! # Available Operations
//!
//! - **Update Weight** - Record a new weight measurement using [`update_weight()`]
//! - **Get Weight by Date** - Retrieve a specific weight entry using [`get_weight_by_date()`]
//! - **Get Monthly Summary** - Fetch all weight measurements for a month using [`get_weight_month_summary()`]
//!
//! # Authentication
//!
//! All functions require:
//! - A [`FatSecretConfig`] containing API credentials
//! - An [`AccessToken`] obtained via the OAuth flow
//!
//! # Error Handling
//!
//! Functions return [`FatSecretError`] which covers:
//! - Network errors
//! - Authentication failures
//! - JSON parsing errors
//! - API-specific errors (invalid dates, missing data, etc.)
//!
//! # Usage Example
//!
//! ```no_run
//! use meal_planner::fatsecret::weight::{update_weight, get_weight_by_date, WeightUpdate};
//! use meal_planner::fatsecret::core::config::FatSecretConfig;
//! use meal_planner::fatsecret::core::oauth::AccessToken;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = FatSecretConfig::from_env()?;
//! let token = AccessToken::new("access_token", "access_secret");
//!
//! // Record today's weight
//! let update = WeightUpdate {
//!     current_weight_kg: 75.5,
//!     date_int: 19723, // 2024-01-01
//!     goal_weight_kg: None,
//!     height_cm: None,
//!     comment: Some("After breakfast".to_string()),
//! };
//! update_weight(&config, &token, update).await?;
//!
//! // Retrieve the weight we just recorded
//! let entry = get_weight_by_date(&config, &token, 19723).await?;
//! println!("Weight: {} kg", entry.weight_kg);
//! if let Some(comment) = entry.weight_comment {
//!     println!("Comment: {}", comment);
//! }
//! # Ok(())
//! # }
//! ```

use crate::fatsecret::core::config::FatSecretConfig;
use crate::fatsecret::core::errors::FatSecretError;
use crate::fatsecret::core::http::make_authenticated_request;
use crate::fatsecret::core::oauth::AccessToken;
use crate::fatsecret::weight::types::{
    WeightEntry, WeightEntryResponse, WeightMonthSummary, WeightMonthSummaryResponse, WeightUpdate,
};
use std::collections::HashMap;

/// Update weight measurement (weight.update method)
pub async fn update_weight(
    config: &FatSecretConfig,
    token: &AccessToken,
    update: WeightUpdate,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert(
        "current_weight_kg".to_string(),
        update.current_weight_kg.to_string(),
    );
    params.insert("date".to_string(), update.date_int.to_string());

    if let Some(goal) = update.goal_weight_kg {
        params.insert("goal_weight_kg".to_string(), goal.to_string());
    }

    if let Some(height) = update.height_cm {
        params.insert("current_height_cm".to_string(), height.to_string());
    }

    if let Some(comment) = update.comment {
        params.insert("comment".to_string(), comment);
    }

    make_authenticated_request(config, token, "weight.update", params).await?;

    Ok(())
}

/// Get weight measurements for a month (`weights.get_month` method)
pub async fn get_weight_month_summary(
    config: &FatSecretConfig,
    token: &AccessToken,
    date_int: i32,
) -> Result<WeightMonthSummary, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("date".to_string(), date_int.to_string());

    let body = make_authenticated_request(config, token, "weights.get_month", params).await?;

    let response: WeightMonthSummaryResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse weight month summary: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.weight_month)
}

/// Get weight measurement for a specific date (weight.get method)
pub async fn get_weight_by_date(
    config: &FatSecretConfig,
    token: &AccessToken,
    date_int: i32,
) -> Result<WeightEntry, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("date".to_string(), date_int.to_string());

    let body = make_authenticated_request(config, token, "weight.get", params).await?;

    let response: WeightEntryResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse weight entry: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.weight)
}
