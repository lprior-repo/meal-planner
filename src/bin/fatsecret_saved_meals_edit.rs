//! Edit an existing FatSecret saved meal
//!
//! Updates a saved meal template (name, description, meal types).
//! This is a 3-legged OAuth request (requires user access token).
//!
//! JSON stdin:
//!   `{"fatsecret": {...}, "access_token": "...", "access_secret": "...", "saved_meal_id": "...", ...}`
//!
//! JSON stdout: `{"success": true}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig, FatSecretError};
use meal_planner::fatsecret::saved_meals::{edit_saved_meal, MealType, SavedMealId};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

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

#[derive(Deserialize)]
struct FatSecretResource {
    consumer_key: String,
    consumer_secret: String,
}

#[derive(Deserialize)]
struct Input {
    /// FatSecret credentials (optional - falls back to env vars)
    fatsecret: Option<FatSecretResource>,
    /// OAuth access token (required for 3-legged requests)
    access_token: String,
    /// OAuth access secret (required for 3-legged requests)
    access_secret: String,
    /// ID of the saved meal to edit
    saved_meal_id: String,
    /// New name for the saved meal (optional)
    saved_meal_name: Option<String>,
    /// New description (optional)
    saved_meal_description: Option<String>,
    /// New meal types (optional, comma-separated)
    meals: Option<String>,
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
    let mut input_str = String::new();
    io::stdin().read_to_string(&mut input_str)?;
    let input: Input = serde_json::from_str(&input_str)?;

    let config = match input.fatsecret {
        Some(resource) => FatSecretConfig::new(resource.consumer_key, resource.consumer_secret),
        None => FatSecretConfig::from_env().ok_or(FatSecretError::ConfigMissing)?,
    };

    let token = AccessToken::new(input.access_token, input.access_secret);
    let saved_meal_id = SavedMealId::new(input.saved_meal_id);

    let meals: Option<Vec<MealType>> = input.meals.map(|m| parse_meals(&m)).transpose()?;

    edit_saved_meal(
        &config,
        &token,
        &saved_meal_id,
        input.saved_meal_name.as_deref(),
        input.saved_meal_description.as_deref(),
        meals.as_deref(),
    )
    .await?;

    Ok(Output { success: true })
}
