//! Find FatSecret food by barcode
//!
//! Looks up a food by its UPC/EAN barcode and returns full details.
//! This is a 2-legged OAuth request (no user token required).
//!
//! JSON input (CLI arg or stdin):
//!   `{"fatsecret": {...}, "barcode": "0014800000000", "barcode_type": "UPC-A"}`
//!
//! JSON stdout: `{"success": true, "food": {...}}`

#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::fatsecret::core::{FatSecretConfig, FatSecretError};
use meal_planner::fatsecret::foods::find_food_by_barcode;
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
    /// The barcode to look up (UPC-A, EAN-13, etc.)
    barcode: String,
    /// Optional barcode type (e.g., "UPC-A", "EAN-13")
    barcode_type: Option<String>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    food: serde_json::Value,
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

    // Find food by barcode
    let result =
        find_food_by_barcode(&config, &input.barcode, input.barcode_type.as_deref()).await?;

    Ok(Output {
        success: true,
        food: serde_json::to_value(result)?,
    })
}
