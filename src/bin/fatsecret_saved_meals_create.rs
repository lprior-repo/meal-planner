//! Create a new `FatSecret` saved meal
//!
//! Creates a saved meal template with associated meal types.
//! This is a 3-legged OAuth request (requires user access token).
//!
//! JSON stdin:
//!   `{"fatsecret": {...}, "access_token": "...", "access_secret": "...", ...}`
//!
//! JSON stdout: `{"success": true, "saved_meal_id": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig};
use meal_planner::fatsecret::saved_meals::{create_saved_meal, MealType};
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
    /// Name for the saved meal
    saved_meal_name: String,
    /// Optional description for the saved meal
    saved_meal_description: Option<String>,
    /// Meal types this saved meal applies to (comma-separated: breakfast,lunch,dinner,other)
    meals: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    saved_meal_id: String,
}

#[derive(Serialize)]
struct ErrorOutput {
    success: bool,
    error: String,
}

fn parse_meals(meals_str: &str) -> Result<Vec<MealType>, String> {
    meals_str
        .split(',')
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(|s| match s {
            "breakfast" => Ok(MealType::Breakfast),
            "lunch" => Ok(MealType::Lunch),
            "dinner" => Ok(MealType::Dinner),
            "other" | "snack" => Ok(MealType::Snack),
            _ => Err(format!("Invalid meal type: {s}")),
        })
        .collect::<Result<Vec<_>, _>>()
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
    let meals = parse_meals(&input.meals)?;

    let saved_meal_id = create_saved_meal(
        &config,
        &token,
        &input.saved_meal_name,
        input.saved_meal_description.as_deref(),
        &meals,
    )
    .await?;

    Ok(Output {
        success: true,
        saved_meal_id: saved_meal_id.as_str().to_string(),
    })
}
