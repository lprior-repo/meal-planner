//! Create `FatSecret` food diary entry
//!
//! Creates a new food diary entry.
//! This is a 3-legged OAuth request (requires user access token).
//!
//! JSON input (CLI arg or stdin):
//!   `{"fatsecret": {...}, "access_token": "...", "access_secret": "...",
//!     "`food_id`": "12345", "food_entry_name": "Chicken Breast",
//!     "`serving_id`": "54321", "number_of_units": 1.5,
//!     "meal": "lunch", "`date_int`": 20088}`
//!
//! JSON stdout: `{"success": true, "food_entry_id": "123456789"}`

#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig};
use meal_planner::fatsecret::diary::{create_food_entry, FoodEntryInput, MealType};
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
    /// The food ID from `FatSecret` database
    food_id: String,
    /// Display name for the entry
    food_entry_name: String,
    /// The serving size ID
    serving_id: String,
    /// Number of servings consumed
    number_of_units: f64,
    /// Meal type: breakfast, lunch, dinner, or other
    meal: String,
    /// Date as days since Unix epoch (1970-01-01)
    date_int: i32,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    food_entry_id: String,
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
        Some(resource) => FatSecretConfig::new(resource.consumer_key, resource.consumer_secret).expect("Invalid FatSecret credentials"),
        None => FatSecretConfig::from_env().map_err(|e| format!("Invalid configuration: {}", e))?,
    };

    // Build access token
    let token = AccessToken::new(input.access_token, input.access_secret);

    // Parse meal type
    let meal = MealType::from_api_string(&input.meal).ok_or_else(|| {
        format!(
            "Invalid meal type: {}. Expected: breakfast, lunch, dinner, or other",
            input.meal
        )
    })?;

    // Build food entry input
    let entry_input = FoodEntryInput::FromFood {
        food_id: input.food_id,
        food_entry_name: input.food_entry_name,
        serving_id: input.serving_id,
        number_of_units: input.number_of_units,
        meal,
        date_int: input.date_int,
    };

    // Create the entry
    let entry_id = create_food_entry(&config, &token, entry_input).await?;

    Ok(Output {
        success: true,
        food_entry_id: entry_id.to_string(),
    })
}
