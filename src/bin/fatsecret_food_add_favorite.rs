//! Add food to FatSecret favorites
//!
//! Adds a food to the user's favorites list.
//! This is a 3-legged OAuth request (requires user access token).
//!
//! JSON input (CLI arg or stdin):
//!   `{"fatsecret": {...}, "access_token": "...", "access_secret": "...",
//!     "food_id": "12345", "serving_id": "54321", "number_of_units": 1.0}`
//!
//! JSON stdout: `{"success": true}`

#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::fatsecret::core::http::make_authenticated_request;
use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig, FatSecretError};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::io::{self, Read};

/// FatSecret resource (matches Windmill resource-fatsecret format)
#[derive(Deserialize)]
struct FatSecretResource {
    consumer_key: String,
    consumer_secret: String,
}

#[derive(Deserialize)]
struct Input {
    /// FatSecret credentials (optional - falls back to env vars)
    fatsecret: Option<FatSecretResource>,
    /// OAuth access token
    access_token: String,
    /// OAuth access token secret
    access_secret: String,
    /// The food ID to add to favorites
    food_id: String,
    /// Optional default serving ID
    serving_id: Option<String>,
    /// Optional default number of units
    number_of_units: Option<f64>,
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
            println!("{}", serde_json::to_string(&output).unwrap());
        }
        Err(e) => {
            let error = ErrorOutput {
                success: false,
                error: e.to_string(),
            };
            println!("{}", serde_json::to_string(&error).unwrap());
            std::process::exit(1);
        }
    }
}

async fn run() -> Result<Output, Box<dyn std::error::Error>> {
    // Read input: prefer CLI arg, fall back to stdin
    let input: Input = if let Some(arg) = std::env::args().nth(1) {
        serde_json::from_str(&arg)?
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        serde_json::from_str(&input_str)?
    };

    // Get config: prefer input, fall back to environment
    let config = match input.fatsecret {
        Some(resource) => FatSecretConfig::new(resource.consumer_key, resource.consumer_secret),
        None => FatSecretConfig::from_env().ok_or(FatSecretError::ConfigMissing)?,
    };

    // Build access token
    let token = AccessToken::new(input.access_token, input.access_secret);

    // Build request parameters
    let mut params = HashMap::new();
    params.insert("food_id".to_string(), input.food_id);

    if let Some(serving_id) = input.serving_id {
        params.insert("serving_id".to_string(), serving_id);
    }

    if let Some(number_of_units) = input.number_of_units {
        params.insert("number_of_units".to_string(), number_of_units.to_string());
    }

    // Make the API request
    let response = make_authenticated_request(&config, &token, "food.add_favorite", params).await?;

    // Parse response to verify success
    let json: serde_json::Value = serde_json::from_str(&response)?;
    let api_success = json
        .get("success")
        .and_then(serde_json::Value::as_i64)
        .unwrap_or(0)
        == 1;

    if !api_success {
        return Err(format!("API returned unexpected response: {}", response).into());
    }

    Ok(Output { success: true })
}
