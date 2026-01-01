//! Search `FatSecret` foods database
//!
//! Searches the `FatSecret` food database for foods matching a query.
//! This is a 2-legged OAuth request (no user token required).
//!
//! JSON input (CLI arg or stdin):
//!   `{"fatsecret": {"consumer_key": "...", "consumer_secret": "..."},`
//!   `"query": "chicken breast", "page": 0, "max_results": 20}`
//!
//! JSON stdout: `{"success": true, "foods": {...}}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::fatsecret::core::FatSecretConfig;
use meal_planner::fatsecret::foods::search_foods;
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
    /// Search query
    query: String,
    /// Page number (0-indexed)
    #[serde(default)]
    page: Option<u32>,
    /// Maximum results per page
    #[serde(default)]
    max_results: Option<u32>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    foods: serde_json::Value,
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
        Some(resource) => FatSecretConfig::new(resource.consumer_key, resource.consumer_secret)
            .expect("Invalid FatSecret credentials"),
        None => FatSecretConfig::from_env().map_err(|e| format!("Invalid configuration: {}", e))?,
    };

    // Set defaults
    let page = input.page.unwrap_or(0);
    let max_results = input.max_results.unwrap_or(20);

    // Search foods
    let result = search_foods(&config, &input.query, page, max_results).await?;

    Ok(Output {
        success: true,
        foods: serde_json::to_value(result)?,
    })
}
