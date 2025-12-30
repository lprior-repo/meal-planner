//! Complete FatSecret OAuth 3-legged flow with manual verifier
//!
//! Exchanges the request token for an access token using a manually-entered verifier.
//! This is for out-of-band (oob) OAuth flows where user copies the verifier code.
//!
//! JSON stdin (Windmill format):
//!   {"fatsecret": {"consumer_key": "...", "consumer_secret": "..."}, "oauth_verifier": "..."}
//!
//! JSON stdin (standalone format - uses env vars for credentials):
//!   {"oauth_verifier": "..."}
//!
//! JSON stdout: {"success": true, "message": "Access token stored"}

use meal_planner::fatsecret::core::oauth::get_access_token;
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
    /// OAuth verifier code from user authorization
    oauth_verifier: String,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    message: String,
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

    // Get database connection
    let database_url = env::var("DATABASE_URL").map_err(|_| "DATABASE_URL not set")?;
    let pool = PgPoolOptions::new()
        .max_connections(1)
        .connect(&database_url)
        .await?;

    let storage = TokenStorage::new(pool);

    // Get the latest pending request token from storage
    let pending = storage
        .get_latest_pending_token()
        .await?
        .ok_or("No pending OAuth request found. Run oauth_start first.")?;

    // Exchange request token for access token
    let access_token = get_access_token(&config, &pending, &input.oauth_verifier).await?;

    // Store access token
    storage.store_access_token(&access_token).await?;

    // Clean up pending token
    storage.delete_pending_token(&pending.oauth_token).await?;

    Ok(Output {
        success: true,
        message: "Access token stored successfully".to_string(),
    })
}
