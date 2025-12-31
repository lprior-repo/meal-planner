//! Autocomplete FatSecret food names
//!
//! Returns food suggestions for partial search terms.
//! This is a 2-legged OAuth request (no user token required).
//!
//! JSON input (CLI arg or stdin):
//!   `{"fatsecret": {"consumer_key": "...", "consumer_secret": "..."}, "expression": "chick", "max_results": 10}`
//!
//! JSON stdout: `{"success": true, "suggestions": [...]}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::fatsecret::core::{FatSecretConfig, FatSecretError};
use meal_planner::fatsecret::foods::autocomplete_foods_with_options;
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
    /// Partial food name to autocomplete
    expression: String,
    /// Maximum number of suggestions
    #[serde(default)]
    max_results: Option<u32>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    suggestions: serde_json::Value,
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
        Some(resource) => FatSecretConfig::new(resource.consumer_key, resource.consumer_secret),
        None => FatSecretConfig::from_env().ok_or(FatSecretError::ConfigMissing)?,
    };

    // Set defaults
    let max_results = input.max_results.unwrap_or(10);

    // Autocomplete foods
    let result =
        autocomplete_foods_with_options(&config, &input.expression, Some(max_results)).await?;

    Ok(Output {
        success: true,
        suggestions: serde_json::to_value(result)?,
    })
}
