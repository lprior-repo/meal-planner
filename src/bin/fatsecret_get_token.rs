//! Retrieve FatSecret access token
//!
//! Retrieves and decrypts the stored access token for use by other scripts.
//! Returns the token validity status and optionally the token itself.
//!
//! JSON stdin: {} (empty object, no input required)
//! JSON stdout: {"success": true, "status": "valid", "oauth_token": "...", "oauth_token_secret": "..."}

use meal_planner::fatsecret::{TokenStorage, TokenValidity};
use serde::{Deserialize, Serialize};
use sqlx::postgres::PgPoolOptions;
use std::env;
use std::io::{self, Read};

#[derive(Deserialize)]
struct Input {
    /// If true, only check validity without returning the actual token
    #[serde(default)]
    check_only: bool,
}

#[derive(Serialize)]
struct Output {
    success: bool,
    /// Token status: "valid", "not_found", or "old"
    status: String,
    /// Days since token was connected (if old)
    #[serde(skip_serializing_if = "Option::is_none")]
    days_since_connected: Option<i32>,
    /// OAuth token (omitted if check_only or not found)
    #[serde(skip_serializing_if = "Option::is_none")]
    oauth_token: Option<String>,
    /// OAuth token secret (omitted if check_only or not found)
    #[serde(skip_serializing_if = "Option::is_none")]
    oauth_token_secret: Option<String>,
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

    // Handle empty input
    let input: Input = if input_str.trim().is_empty() {
        Input { check_only: false }
    } else {
        serde_json::from_str(&input_str)?
    };

    // Get database connection
    let database_url = env::var("DATABASE_URL").map_err(|_| "DATABASE_URL not set")?;
    let pool = PgPoolOptions::new()
        .max_connections(1)
        .connect(&database_url)
        .await?;

    let storage = TokenStorage::new(pool);

    // Check token validity
    let validity = storage.check_token_validity().await?;

    match validity {
        TokenValidity::Valid => {
            if input.check_only {
                Ok(Output {
                    success: true,
                    status: "valid".to_string(),
                    days_since_connected: None,
                    oauth_token: None,
                    oauth_token_secret: None,
                })
            } else {
                // Retrieve and decrypt token
                let token = storage
                    .get_access_token()
                    .await?
                    .ok_or("Token marked valid but not found")?;

                // Update last used timestamp
                storage.update_last_used().await?;

                Ok(Output {
                    success: true,
                    status: "valid".to_string(),
                    days_since_connected: None,
                    oauth_token: Some(token.oauth_token),
                    oauth_token_secret: Some(token.oauth_token_secret),
                })
            }
        }
        TokenValidity::NotFound => Ok(Output {
            success: true,
            status: "not_found".to_string(),
            days_since_connected: None,
            oauth_token: None,
            oauth_token_secret: None,
        }),
        TokenValidity::Old {
            days_since_connected,
        } => {
            // Still return the token for old tokens - let caller decide what to do
            if input.check_only {
                Ok(Output {
                    success: true,
                    status: "old".to_string(),
                    days_since_connected: Some(days_since_connected),
                    oauth_token: None,
                    oauth_token_secret: None,
                })
            } else {
                let token = storage
                    .get_access_token()
                    .await?
                    .ok_or("Token marked old but not found")?;

                storage.update_last_used().await?;

                Ok(Output {
                    success: true,
                    status: "old".to_string(),
                    days_since_connected: Some(days_since_connected),
                    oauth_token: Some(token.oauth_token),
                    oauth_token_secret: Some(token.oauth_token_secret),
                })
            }
        }
    }
}
