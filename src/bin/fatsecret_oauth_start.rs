//! Start `FatSecret` OAuth 3-legged flow
//!
//! Gets a request token and returns the authorization URL.
//! The user visits the URL to authorize, then `FatSecret` redirects to callback.
//!
//! This script returns the pending token which should be stored as a Windmill Resource
//! for use in the next step (`oauth_complete`).
//!
//! JSON stdin (Windmill format):
//!   `{"fatsecret": {...}, "callback_url": "oob"}`
//!
//! JSON stdin (standalone format - uses env vars for credentials):
//!   `{"callback_url": "http://localhost:8765/callback"}`
//!
//! JSON stdout: `{"success": true, "auth_url": "https://...", "oauth_token": "...", "oauth_token_secret": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used, clippy::expect_used)]

use meal_planner::fatsecret::core::oauth::get_request_token;
use meal_planner::fatsecret::core::FatSecretConfig;
use meal_planner::fatsecret::crypto::validate_encryption_at_startup;
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
    /// Callback URL for OAuth redirect (e.g., "<http://localhost:8765/callback>" or "oob")
    callback_url: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    /// URL user should visit to authorize
    auth_url: String,
    /// Request token (needed for `oauth_complete`)
    oauth_token: String,
    /// Request token secret (needed for `oauth_complete`)
    oauth_token_secret: String,
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
    // Validate encryption configuration at startup (Security Issue MP-2jjo)
    // Even though this specific binary doesn't use storage directly,
    // it's part of the OAuth flow that may lead to token storage
    validate_encryption_at_startup().map_err(|e| {
        format!("Encryption validation failed: {}. Please set OAUTH_ENCRYPTION_KEY environment variable.", e)
    })?;

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

    // Get request token from FatSecret (no database needed)
    let request_token = get_request_token(&config, &input.callback_url).await?;

    // Build authorization URL
    let auth_url = config.authorization_url(&request_token.oauth_token);

    Ok(Output {
        success: true,
        auth_url,
        oauth_token: request_token.oauth_token,
        oauth_token_secret: request_token.oauth_token_secret,
    })
}
