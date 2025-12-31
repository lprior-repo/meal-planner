//! Complete FatSecret OAuth 3-legged flow with manual verifier
//!
//! Exchanges the request token for an access token using a manually-entered verifier.
//! This is for out-of-band (oob) OAuth flows where user copies the verifier code.
//!
//! Takes the pending token from oauth_start as input (via Windmill Resource parameter).
//! Returns the access token which should be stored as a Windmill Resource.
//!
//! JSON stdin (Windmill format):
//!   `{"fatsecret": {...}, "oauth_token": "...", "oauth_token_secret": "...", "oauth_verifier": "..."}`
//!
//! JSON stdin (standalone format - uses env vars for credentials):
//!   `{"oauth_token": "...", "oauth_token_secret": "...", "oauth_verifier": "..."}`
//!
//! JSON stdout: `{"success": true, "oauth_token": "...", "oauth_token_secret": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::fatsecret::core::oauth::{get_access_token, RequestToken};
use meal_planner::fatsecret::core::{FatSecretConfig, FatSecretError};
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
    /// Pending request token from oauth_start
    oauth_token: String,
    /// Pending request token secret from oauth_start
    oauth_token_secret: String,
    /// OAuth verifier code from user authorization
    oauth_verifier: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    /// Access token for authenticated requests
    oauth_token: String,
    /// Access token secret for signing requests
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
        Some(resource) => FatSecretConfig::new(resource.consumer_key, resource.consumer_secret),
        None => FatSecretConfig::from_env().ok_or(FatSecretError::ConfigMissing)?,
    };

    // Reconstruct request token from input (no database needed)
    let pending = RequestToken {
        oauth_token: input.oauth_token,
        oauth_token_secret: input.oauth_token_secret,
        oauth_callback_confirmed: true,
    };

    // Exchange request token for access token
    let access_token = get_access_token(&config, &pending, &input.oauth_verifier).await?;

    Ok(Output {
        success: true,
        oauth_token: access_token.oauth_token,
        oauth_token_secret: access_token.oauth_token_secret,
    })
}
