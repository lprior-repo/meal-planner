//! Get items for a specific `FatSecret` saved meal
//!
//! Retrieves all food items within a saved meal template.
//! This is a 3-legged OAuth request (requires user access token).
//!
//! JSON stdin:
//!   `{"fatsecret": {...}, "access_token": "...", "access_secret": "...", "saved_meal_id": "..."}`
//!
//! JSON stdout: `{"success": true, "items": [...]}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig};
use meal_planner::fatsecret::saved_meals::{get_saved_meal_items, SavedMealId};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

#[derive(Deserialize)]
struct FatSecretResource {
    consumer_key: String,
    consumer_secret: String,
}

#[derive(Deserialize)]
struct Input {
    /// `FatSecret` credentials (optional - falls back to env vars)
    fatsecret: Option<FatSecretResource>,
    /// OAuth access token (required for 3-legged requests)
    access_token: String,
    /// OAuth access secret (required for 3-legged requests)
    access_secret: String,
    /// ID of the saved meal to get items for
    saved_meal_id: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    items: Vec<serde_json::Value>,
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
            println!("{}", serde_json::to_string(serde_json::to_string(&output).expect("Unexpected None value")output).expect("Failed to serialize output JSON"));
        }
        Err(e) => {
            let error = ErrorOutput {
                success: false,
                error: e.to_string(),
            };
            println!("{}", serde_json::to_string(serde_json::to_string(&error).expect("Unexpected None value")error).expect("Failed to serialize error JSON"));
            std::process::exit(1);
        }
    }
}

async fn run() -> Result<Output, Box<dyn std::error::Error>> {
    let mut input_str = String::new();
    io::stdin().read_to_string(&mut input_str)?;
    let input: Input = serde_json::from_str(&input_str)?;

    let config = match input.fatsecret {
        Some(resource) => FatSecretConfig::new(resource.consumer_key, resource.consumer_secret)
            .expect("Invalid FatSecret credentials"),
        None => FatSecretConfig::from_env().map_err(|e| format!("Invalid configuration: {}", e))?,
    };

    let token = AccessToken::new(input.access_token, input.access_secret);
    let saved_meal_id = SavedMealId::new(input.saved_meal_id);

    let items = get_saved_meal_items(&config, &token, &saved_meal_id).await?;

    Ok(Output {
        success: true,
        items: items
            .into_iter()
            .map(serde_json::to_value)
            .collect::<Result<Vec<_>, _>>()?,
    })
}
