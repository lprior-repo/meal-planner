//! Get `FatSecret` food by ID
//!
//! Retrieves detailed food information including all servings and nutrition data.
//! This is a 2-legged OAuth request (no user token required).
//!
//! JSON input (CLI arg or stdin):
//!   `{"fatsecret": {"consumer_key": "...", "consumer_secret": "..."}, "food_id": "35718"}`
//!
//! JSON stdout: `{"success": true, "food": {...}}`

use meal_planner::fatsecret::core::{FatSecretConfig, FatSecretError};
use meal_planner::fatsecret::foods::{get_food, FoodId};
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
    /// The food ID to retrieve
    food_id: String,
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

/// Parse input from CLI argument or stdin
fn parse_input() -> Result<Input, Box<dyn std::error::Error>> {
    let input_str = if let Some(arg) = std::env::args().nth(1) {
        arg
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        input_str
    };
    
    Ok(serde_json::from_str(&input_str)?)
}

/// Get FatSecret configuration from input or environment
fn get_config(input: &Input) -> Result<FatSecretConfig, Box<dyn std::error::Error>> {
    match &input.fatsecret {
        Some(resource) => {
            FatSecretConfig::new(resource.consumer_key.clone(), resource.consumer_secret.clone())
                .map_err(|e| format!("Invalid FatSecret credentials: {}", e).into())
        }
        None => FatSecretConfig::from_env()
            .map_err(|e| format!("Invalid configuration: {}", e).into()),
    }
}

/// Get food by ID from FatSecret API
async fn fetch_food(config: &FatSecretConfig, food_id: &str) -> Result<meal_planner::fatsecret::foods::Food, FatSecretError> {
    let food_id = FoodId::new(food_id.to_string());
    get_food(config, &food_id).await
}

/// Main functional entry point that handles the pipeline of operations
async fn run() -> Result<Output, Box<dyn std::error::Error>> {
    // Parse input
    let input = parse_input()?;
    
    // Get config
    let config = get_config(&input)?;
    
    // Fetch food data
    let food = fetch_food(&config, &input.food_id).await?;
    
    // Return successful output
    Ok(Output {
        success: true,
        food: serde_json::to_value(food)?,
    })
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
