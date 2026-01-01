//! Get `FatSecret` user profile
//!
//! Retrieves the authenticated user's profile information.
//! Requires access token credentials passed as parameters (from `oauth_complete` or Windmill Resource).
//!
//! JSON stdin (Windmill format):
//!   `{"fatsecret": {"consumer_key": "...", "consumer_secret": "..."}, "oauth_token": "...", "oauth_token_secret": "..."}`
//!
//! JSON stdin (standalone format - uses env vars for credentials):
//!   `{"oauth_token": "...", "oauth_token_secret": "..."}`
//!
//! JSON stdout: `{"success": true, "profile": {...}}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::fatsecret::core::{AccessToken, FatSecretConfig};
use meal_planner::fatsecret::profile::get_profile;
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
    /// OAuth access token
    oauth_token: String,
    /// OAuth access token secret
    oauth_token_secret: String,
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
    // Read input
    let mut input_str = String::new();
    io::stdin().read_to_string(&mut input_str)?;
    let input: Input = serde_json::from_str(&input_str)?;

    // Get config: prefer input, fall back to environment
    let config = match input.fatsecret {
        Some(resource) => FatSecretConfig::new(resource.consumer_key, resource.consumer_secret)
            .expect("Invalid FatSecret credentials"),
        None => FatSecretConfig::from_env().map_err(|e| format!("Invalid configuration: {}", e))?,
    };

    // Create access token from parameters (no database needed)
    let access_token = AccessToken {
        oauth_token: input.oauth_token,
        oauth_token_secret: input.oauth_token_secret,
    };

    // Get profile
    let profile = get_profile(&config, &access_token).await?;

    Ok(Output {
        success: true,
        profile: serde_json::to_value(profile)?,
    })
}
