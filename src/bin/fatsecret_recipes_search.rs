//! Search `FatSecret` recipes
//!
//! Searches for recipes with optional pagination and filtering by recipe type.
//! This is a 2-legged OAuth request (no user token required).
//!
//! JSON stdin:
//!   `{"fatsecret": {...}, "search_expression": "chicken", ...}`
//!
//! JSON stdout: `{"success": true, "recipes": {...}}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::fatsecret::core::FatSecretConfig;
use meal_planner::fatsecret::recipes::search_recipes;
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
    /// Search query (e.g., "chicken soup")
    search_expression: String,
    /// Maximum results to return (optional)
    max_results: Option<i32>,
    /// Page number for pagination (optional)
    page_number: Option<i32>,
    /// Filter by recipe type (optional)
    recipe_type: Option<String>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    recipes: serde_json::Value,
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

    let result = search_recipes(
        &config,
        &input.search_expression,
        input.max_results,
        input.page_number,
        input.recipe_type.as_deref(),
    )
    .await?;

    Ok(Output {
        success: true,
        recipes: serde_json::to_value(result)?,
    })
}
