//! Edit an existing `FatSecret` exercise entry
//!
//! Updates an existing exercise entry (duration, exercise type, etc.).
//! This binary handles the edit case by including `exercise_entry_id`.
//!
//! This is a 3-legged OAuth request (requires user access token).
//!
//! JSON stdin:
//!   `{"fatsecret": {...}, "access_token": "...", "access_secret": "...", "exercise_entry_id": "...", ...}`
//!
//! JSON stdout: `{"success": true}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig};
use meal_planner::fatsecret::exercise::{
    edit_exercise_entry, ExerciseEntryId, ExerciseEntryUpdate, ExerciseId,
};
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
    /// OAuth access token (required for 3-legged requests)
    access_token: String,
    /// OAuth access secret (required for 3-legged requests)
    access_secret: String,
    /// ID of exercise entry to edit
    exercise_entry_id: String,
    /// New exercise ID (optional)
    exercise_id: Option<String>,
    /// New duration in minutes (optional)
    duration_min: Option<i32>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
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

    let token = AccessToken::new(input.access_token, input.access_secret);
    let entry_id = ExerciseEntryId::new(input.exercise_entry_id);

    let update = ExerciseEntryUpdate {
        exercise_id: input.exercise_id.map(ExerciseId::new),
        duration_min: input.duration_min,
    };

    edit_exercise_entry(&config, &token, &entry_id, update).await?;

    Ok(Output { success: true })
}
