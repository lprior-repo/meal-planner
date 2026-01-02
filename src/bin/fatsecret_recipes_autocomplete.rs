//! Autocomplete FatSecret recipes
//!
//! Get recipe suggestions based on partial input.
//! This is a 2-legged OAuth request (no user token required).
//!
//! JSON stdin:
//!   `{"fatsecret": {...}, "expression": "chic"}`
//!
//! JSON stdout: `{"success": true, "suggestions": [...]}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::fatsecret::core::{FatSecretConfig, FatSecretError};
use meal_planner::fatsecret::recipes::autocomplete_recipes;
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
    /// Partial recipe name to autocomplete
    expression: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    suggestions: Vec<serde_json::Value>,
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
            .map_err(|_| FatSecretError::ConfigMissing)?,
        None => FatSecretConfig::from_env().map_err(|_| FatSecretError::ConfigMissing)?,
    };

    let suggestions = autocomplete_recipes(&config, &input.expression).await?;

    Ok(Output {
        success: true,
        suggestions: suggestions
            .into_iter()
            .map(serde_json::to_value)
            .collect::<Result<Vec<_>, _>>()?,
    })
}
