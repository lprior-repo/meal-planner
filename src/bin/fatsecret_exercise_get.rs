//! Get FatSecret exercise by ID
//!
//! Retrieves detailed exercise information from FatSecret database.
//! This is a 2-legged OAuth request (no user token required).
//!
//! JSON stdin:
//!   `{"fatsecret": {"consumer_key": "...", "consumer_secret": "..."}, "exercise_id": "123"}`
//!
//! JSON stdout: `{"success": true, "exercise": {...}}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::fatsecret::core::{FatSecretConfig, FatSecretError};
use meal_planner::fatsecret::exercise::{get_exercise, ExerciseId};
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
    /// The exercise ID to retrieve
    exercise_id: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    exercise: serde_json::Value,
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

    let result = get_exercise(&config, &ExerciseId::new(input.exercise_id)).await?;

    Ok(Output {
        success: true,
        exercise: serde_json::to_value(result)?,
    })
}
