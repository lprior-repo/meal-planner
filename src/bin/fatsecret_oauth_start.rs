//! Start FatSecret OAuth 3-legged flow
//!
//! Gets a request token and returns the authorization URL.
//! The user visits the URL to authorize, then FatSecret redirects to callback.
//!
//! JSON stdin (Windmill format):
//!   `{"fatsecret": {...}, "callback_url": "oob"}`
//!
//! JSON stdin (standalone format - uses env vars for credentials):
//!   `{"callback_url": "http://localhost:8765/callback"}`
//!
//! JSON stdout: `{"success": true, "auth_url": "https://...", "oauth_token": "..."}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]

use meal_planner::fatsecret::core::oauth::get_request_token;
use meal_planner::fatsecret::core::{FatSecretConfig, FatSecretError};
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

#[derive(Deserialize)]
struct Input {
    /// FatSecret credentials (optional - falls back to env vars)
    fatsecret: Option<FatSecretResource>,
    /// Callback URL for OAuth redirect (e.g., "http://localhost:8765/callback" or "oob")
    callback_url: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    /// URL user should visit to authorize
    auth_url: String,
    /// Request token (needed to identify the pending auth)
    oauth_token: String,
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
    // Read input
    let mut input_str = String::new();
    io::stdin().read_to_string(&mut input_str)?;
    let input: Input = serde_json::from_str(&input_str)?;

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

    // Get request token from FatSecret
    let request_token = get_request_token(&config, &input.callback_url).await?;

    // Store pending token in database (encrypted)
    let storage = TokenStorage::new(pool);
    storage.store_pending_token(&request_token).await?;

    // Build authorization URL
    let auth_url = config.authorization_url(&request_token.oauth_token);

    Ok(Output {
        success: true,
        auth_url,
        oauth_token: request_token.oauth_token,
    })
}
