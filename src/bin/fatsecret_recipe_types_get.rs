//! Get `FatSecret` recipe types
//!
//! Retrieves all available recipe types/categories.
//! This is a 2-legged OAuth request (no user token required).
//!
//! JSON stdin:
//!   `{"fatsecret": {"consumer_key": "...", "consumer_secret": "..."}}`
//!
//! JSON stdout: `{"success": true, "recipe_types": [...]}`

// CLI binaries: exit and JSON unwrap are acceptable at top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::fatsecret::core::FatSecretConfig;
use meal_planner::fatsecret::core::FatSecretError;
use meal_planner::fatsecret::recipes::get_recipe_types;
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
}

#[derive(Serialize)]
struct Output {
    success: bool,
    recipe_types: Vec<serde_json::Value>,
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
        Some(resource) => FatSecretConfig::new(resource.consumer_key, resource.consumer_secret),
        None => FatSecretConfig::from_env().ok_or(FatSecretError::ConfigMissing)?,
    };

    let recipe_types = get_recipe_types(&config).await?;

    Ok(Output {
        success: true,
        recipe_types: recipe_types
            .into_iter()
            .map(serde_json::to_value)
            .collect::<Result<Vec<_>, _>>()?,
    })
}
