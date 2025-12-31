//! Get FatSecret user profile
//!
//! Retrieves the authenticated user's profile information.
//! Requires a stored access token (run oauth_start + oauth_complete first).
//!
//! JSON input (CLI arg or stdin, Windmill format):
//!   `{"fatsecret": {"consumer_key": "...", "consumer_secret": "..."}}`
//!
//! JSON input (CLI arg or stdin, standalone format - uses env vars for credentials):
//!   `{}`
//!
//! JSON stdout: `{"success": true, "profile": {...}}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::fatsecret::core::{FatSecretConfig, FatSecretError};
use meal_planner::fatsecret::profile::get_profile;
use meal_planner::fatsecret::TokenStorage;
use serde::{Deserialize, Serialize};
use sqlx::postgres::PgPoolOptions;
use std::env;
use std::io::{self, Read};

/// FatSecret resource (matches Windmill resource-fatsecret format)
#[derive(Deserialize)]
struct FatSecretResource {
    consumer_key: String,
    consumer_secret: String,
}

#[derive(Deserialize, Default)]
struct Input {
    /// FatSecret credentials (optional - falls back to env vars)
    fatsecret: Option<FatSecretResource>,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    profile: serde_json::Value,
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
        if arg.trim().is_empty() {
            Input::default()
        } else {
            serde_json::from_str(&arg)?
        }
    } else {
        let mut input_str = String::new();
        io::stdin().read_to_string(&mut input_str)?;
        if input_str.trim().is_empty() {
            Input::default()
        } else {
            serde_json::from_str(&input_str)?
        }
    };

    // Get config: prefer input, fall back to environment
    let config = match input.fatsecret {
        Some(resource) => FatSecretConfig::new(resource.consumer_key, resource.consumer_secret),
        None => FatSecretConfig::from_env().ok_or(FatSecretError::ConfigMissing)?,
    };

    // Get database connection
    let database_url = env::var("DATABASE_URL").map_err(|_| "DATABASE_URL not set")?;
    let pool = PgPoolOptions::new()
        .max_connections(1)
        .connect(&database_url)
        .await?;

    let storage = TokenStorage::new(pool);

    // Get stored access token
    let access_token = storage
        .get_access_token()
        .await?
        .ok_or("No access token found. Complete OAuth flow first.")?;

    // Get profile
    let profile = get_profile(&config, &access_token).await?;

    Ok(Output {
        success: true,
        profile: serde_json::to_value(profile)?,
    })
}
