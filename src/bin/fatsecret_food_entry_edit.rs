//! Edit `FatSecret` food diary entry
//!
//! Updates an existing food diary entry.
//! This is a 3-legged OAuth request (requires user access token).
//!
//! JSON input (CLI arg or stdin):
//!   `{"fatsecret": {...}, "access_token": "...", "access_secret": "...",
//!     "``food_entry_id``": "123456", "number_of_units": 2.0, "meal": "dinner"}`
//!
//! JSON stdout: `{"success": true}`

#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig};
use meal_planner::fatsecret::diary::{edit_food_entry, FoodEntryId, FoodEntryUpdate, MealType};
use serde::{Deserialize, Serialize};
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
    /// The food entry ID to edit
    food_entry_id: String,
    /// Optional new number of units
    number_of_units: Option<f64>,
    /// Optional new meal type (breakfast, lunch, dinner, other)
    meal: Option<String>,
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
        Some(resource) => FatSecretConfig::new(resource.consumer_key, resource.consumer_secret)
            .expect("Invalid FatSecret credentials"),
        None => FatSecretConfig::from_env().map_err(|e| format!("Invalid configuration: {}", e))?,
    };

    // Build access token
    let token = AccessToken::new(input.access_token, input.access_secret);

    // Build update struct with optional fields
    let mut update = FoodEntryUpdate::new();

    if let Some(units) = input.number_of_units {
        update = update.with_units(units);
    }

    if let Some(meal_str) = input.meal {
        let meal = MealType::from_api_string(&meal_str)
            .ok_or_else(|| format!("Invalid meal type: {meal_str}"))?;
        update = update.with_meal(meal);
    }

    // Make the API request
    let entry_id = FoodEntryId::new(input.food_entry_id);
    edit_food_entry(&config, &token, &entry_id, update).await?;

    Ok(Output { success: true })
}
