//! Get `FatSecret` recently eaten foods
//!
//! Retrieves user's recently eaten foods.
//! This is a 3-legged OAuth request (requires user access token).
//!
//! JSON stdin:
//!   `{"fatsecret": {...}, "access_token": "...", "access_secret": "..."}`
//!
//! JSON stdout: `{"success": true, "foods": [...]}`

// CLI binaries: exit and JSON unwrap are acceptable at top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig};
use meal_planner::fatsecret::favorites::{get_recently_eaten, MealFilter};
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
    /// Filter by meal type (optional)
    meal: Option<String>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    foods: Vec<serde_json::Value>,
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
    let mut input_str = String::new();
    io::stdin().read_to_string(&mut input_str)?;
    let input: Input = serde_json::from_str(&input_str)?;

    let config = match input.fatsecret {
        Some(resource) => FatSecretConfig::new(resource.consumer_key, resource.consumer_secret).expect("Invalid FatSecret credentials"),
        None => FatSecretConfig::from_env().map_err(|e| format!("Invalid configuration: {}", e))?,
    };

    let token = AccessToken::new(input.access_token, input.access_secret);

    let meal_filter = input.meal.and_then(|m| match m.as_str() {
        "breakfast" => Some(MealFilter::Breakfast),
        "lunch" => Some(MealFilter::Lunch),
        "dinner" => Some(MealFilter::Dinner),
        "other" | "snack" => Some(MealFilter::Snack),
        _ => None,
    });

    let foods = get_recently_eaten(&config, &token, meal_filter).await?;

    Ok(Output {
        success: true,
        foods: foods
            .into_iter()
            .map(serde_json::to_value)
            .collect::<Result<Vec<_>, _>>()?,
    })
}
