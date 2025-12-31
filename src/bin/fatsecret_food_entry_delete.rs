//! Delete FatSecret food diary entry
//!
//! Deletes a food diary entry.
//! This is a 3-legged OAuth request (requires user access token).
//!
//! JSON input (CLI arg or stdin):
//!   `{"fatsecret": {...}, "access_token": "...", "access_secret": "...", "food_entry_id": "123456"}`
//!
//! JSON stdout: `{"success": true}`

#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig, FatSecretError};
use meal_planner::fatsecret::diary::{delete_food_entry, FoodEntryId};
use serde::{Deserialize, Serialize};
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
    /// Food entry ID to delete
    food_entry_id: String,
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
            println!("{serde_json::to_string(&output}").unwrap());
        }
        Err(e) => {
            let error = ErrorOutput {
                success: false,
                error: e.to_string(),
            };
            println!("{serde_json::to_string(&error}").unwrap());
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

    // Build access token from input
    let token = AccessToken::new(input.access_token, input.access_secret);

    // Create FoodEntryId from input
    let entry_id = FoodEntryId::new(input.food_entry_id);

    // Call API
    delete_food_entry(&config, &token, &entry_id).await?;

    Ok(Output { success: true })
}
