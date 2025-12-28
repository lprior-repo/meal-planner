//! FatSecret SDK Weight API client

use std::collections::HashMap;
use crate::fatsecret::core::config::FatSecretConfig;
use crate::fatsecret::core::errors::FatSecretError;
use crate::fatsecret::core::http::make_authenticated_request;
use crate::fatsecret::core::oauth::AccessToken;
use crate::fatsecret::weight::types::{
    WeightEntry, WeightMonthSummary, WeightUpdate, WeightEntryResponse, WeightMonthSummaryResponse
};

/// Update weight measurement (weight.update method)
pub async fn update_weight(
    config: &FatSecretConfig,
    token: &AccessToken,
    update: WeightUpdate,
) -> Result<(), FatSecretError> {
    let mut params = HashMap::new();
    params.insert("current_weight_kg".to_string(), update.current_weight_kg.to_string());
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

    make_authenticated_request(
        config,
        token,
        "weight.update",
        params,
    ).await?;

    Ok(())
}

/// Get weight measurements for a month (weights.get_month method)
pub async fn get_weight_month_summary(
    config: &FatSecretConfig,
    token: &AccessToken,
    date_int: i32,
) -> Result<WeightMonthSummary, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("date".to_string(), date_int.to_string());

    let body = make_authenticated_request(
        config,
        token,
        "weights.get_month",
        params,
    ).await?;

    let response: WeightMonthSummaryResponse = serde_json::from_str(&body)
        .map_err(|e| FatSecretError::ParseError(format!("Failed to parse weight month summary: {}. Body: {}", e, body)))?;

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

    let body = make_authenticated_request(
        config,
        token,
        "weight.get",
        params,
    ).await?;

    let response: WeightEntryResponse = serde_json::from_str(&body)
        .map_err(|e| FatSecretError::ParseError(format!("Failed to parse weight entry: {}. Body: {}", e, body)))?;

    Ok(response.weight)
}
