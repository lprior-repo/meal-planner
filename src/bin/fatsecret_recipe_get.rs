//! Get `FatSecret` recipe by ID
//!
//! Retrieves detailed recipe information including ingredients and directions.
//! This is a 2-legged OAuth request (no user token required).
//!
//! JSON stdin:
//!   `{"fatsecret": {"consumer_key": "...", "consumer_secret": "..."}, "recipe_id": "123"}`
//!
//! JSON stdout: `{"success": true, "recipe": {...}}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::fatsecret::core::FatSecretConfig;
use meal_planner::fatsecret::recipes::{get_recipe, RecipeId};
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
    /// The recipe ID to retrieve
    recipe_id: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    recipe: serde_json::Value,
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
        Some(resource) => FatSecretConfig::new(resource.consumer_key, resource.consumer_secret)
            .expect("Invalid FatSecret credentials"),
        None => FatSecretConfig::from_env().map_err(|e| format!("Invalid configuration: {}", e))?,
    };

    let result = get_recipe(&config, &RecipeId::new(input.recipe_id)).await?;

    Ok(Output {
        success: true,
        recipe: serde_json::to_value(result)?,
    })
}
