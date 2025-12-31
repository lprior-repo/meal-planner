//! Create a new FatSecret exercise entry
//!
//! Logs an exercise session with duration. The FatSecret API uses
//! the same endpoint (exercise_entry.edit) for both create and update operations.
//! This binary handles the create case by not including exercise_entry_id.
//!
//! This is a 3-legged OAuth request (requires user access token).
//!
//! JSON stdin:
//!   `{"fatsecret": {...}, "access_token": "...", "access_secret": "...", ...}`
//!
//! JSON stdout: `{"success": true, "exercise_entry_id": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig, FatSecretError};
use meal_planner::fatsecret::exercise::{create_exercise_entry, ExerciseEntryInput, ExerciseId};
use serde::{Deserialize, Serialize};
use std::io::{self, Read};

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
    /// ID of the exercise to log
    exercise_id: String,
    /// Duration of exercise in minutes
    duration_min: i32,
    /// Date as days since Unix epoch (1970-01-01)
    date_int: i32,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    exercise_entry_id: String,
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
    let entry_input = ExerciseEntryInput {
        exercise_id: ExerciseId::new(input.exercise_id),
        duration_min: input.duration_min,
        date_int: input.date_int,
    };

    let entry_id = create_exercise_entry(&config, &token, entry_input).await?;

    Ok(Output {
        success: true,
        exercise_entry_id: entry_id.as_str().to_string(),
    })
}
