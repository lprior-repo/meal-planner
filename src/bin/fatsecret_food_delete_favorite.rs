//! Delete food from `FatSecret` favorites
//!
//! Removes a food from the user's favorites list.
//! This is a 3-legged OAuth request (requires user access token).
//!
//! JSON stdin:
//!   `{"fatsecret": {...}, "access_token": "...", "access_secret": "...", "food_id": "12345"}`
//!
//! JSON stdout: `{"success": true}`

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::fatsecret::core::http::make_authenticated_request;
use meal_planner::fatsecret::core::serde_utils::SuccessResponse;
use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::io::{self, Read};

/// `FatSecret` resource (matches Windmill resource-fatsecret format)
#[derive(Deserialize)]
struct FatSecretResource {
    consumer_key: String,
    consumer_secret: String,
}

#[derive(Deserialize)]
struct Input {
    /// `FatSecret` credentials (optional - falls back to env vars)
    fatsecret: Option<FatSecretResource>,
    /// OAuth access token
    access_token: String,
    /// OAuth access token secret
    access_secret: String,
    /// Food ID to remove from favorites
    food_id: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
}

#[derive(Serialize)]
struct ErrorOutput {
    success: bool,
    error: String,
}

#[tokio::main]
async fn main() {
    match run().await {
        Ok(output) => {
            println!(
                "{}",
                serde_json::to_string(&output).expect("Failed to serialize output JSON")
            );
        }
        Err(e) => {
            let error = ErrorOutput {
                success: false,
                error: e.to_string(),
            };
            println!(
                "{}",
                serde_json::to_string(&error).expect("Failed to serialize error JSON")
            );
            std::process::exit(1);
        }
    }
}

async fn run() -> Result<Output, Box<dyn std::error::Error>> {
    // Read input
    let mut input_str = String::new();
    io::stdin().read_to_string(&mut input_str)?;
    let input: Input = serde_json::from_str(&input_str)?;

    // Get config: prefer input, fall back to environment
    let config = match input.fatsecret {
        Some(resource) => FatSecretConfig::new(resource.consumer_key, resource.consumer_secret)
            .expect("Invalid FatSecret credentials"),
        None => FatSecretConfig::from_env().map_err(|e| format!("Invalid configuration: {}", e))?,
    };

    // Build access token from input
    let token = AccessToken::new(input.access_token, input.access_secret);

    // Build params with food_id
    let mut params = HashMap::new();
    params.insert("food_id".to_string(), input.food_id);

    // Call API
    let response =
        make_authenticated_request(&config, &token, "food.delete_favorite", params).await?;

    // Parse response to verify success
    // The API returns {"success": {"value": "1"}} - nested format
    let api_response: SuccessResponse = serde_json::from_str(&response)
        .map_err(|e| format!("Failed to parse API response: {e}. Body: {response}"))?;

    if !api_response.is_success() {
        return Err(format!("API returned unexpected response: {response}").into());
    }

    Ok(Output { success: true })
}
