//! FatSecret OAuth callback handler
//!
//! Starts a temporary HTTP server to receive the OAuth callback,
//! exchanges the request token for an access token, and stores it.
//!
//! JSON stdin: `{"port": 8765, "timeout_secs": 300}`
//! JSON stdout: `{"success": true, "message": "Connected to FatSecret"}`

// CLI binaries: exit and JSON unwrap are acceptable at the top level
#![allow(clippy::exit, clippy::unwrap_used)]
#![allow(clippy::too_many_lines, clippy::clone_on_ref_ptr)]
#![allow(clippy::significant_drop_in_scrutinee, clippy::let_underscore_must_use)]
#![allow(clippy::indexing_slicing)]

use meal_planner::fatsecret::core::oauth::get_access_token;
use meal_planner::fatsecret::core::{FatSecretConfig, FatSecretError};
use meal_planner::fatsecret::TokenStorage;
use serde::{Deserialize, Serialize};
use sqlx::postgres::PgPoolOptions;
use std::env;
use std::io::{self, Read};
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::sync::oneshot;
use tokio::time::{timeout, Duration};

#[derive(Deserialize)]
struct Input {
    /// Port to listen on for callback (default: 8765)
    #[serde(default = "default_port")]
    port: u16,
    /// Timeout in seconds to wait for callback (default: 300 = 5 min)
    #[serde(default = "default_timeout")]
    timeout_secs: u64,
}

fn default_port() -> u16 {
    8765
}

fn default_timeout() -> u64 {
    300
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

/// Query parameters from OAuth callback
#[derive(Debug, Deserialize)]
struct CallbackParams {
    oauth_token: String,
    oauth_verifier: String,
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

async fn run() -> Result<Output, Box<dyn std::error::Error + Send + Sync>> {
    // Read input
    let mut input_str = String::new();
    io::stdin().read_to_string(&mut input_str)?;
    let input: Input = serde_json::from_str(&input_str)?;

    // Get config from environment
    let config = FatSecretConfig::from_env().map_err(|_| FatSecretError::ConfigMissing)?;

    // Get database connection
    let database_url = env::var("DATABASE_URL").map_err(|_| "DATABASE_URL not set")?;
    let pool = PgPoolOptions::new()
        .max_connections(2)
        .connect(&database_url)
        .await?;

    let storage = Arc::new(TokenStorage::new(pool));

    // Channel to receive callback result
    let (tx, rx) = oneshot::channel::<CallbackParams>();
    let tx = Arc::new(tokio::sync::Mutex::new(Some(tx)));

    // Build the callback handler
    let tx_clone = Arc::clone(&tx);
    let callback_handler = move |params: CallbackParams| {
        let tx = Arc::clone(&tx_clone);
        async move {
            if let Some(sender) = tx.lock().await.take() {
                // Ignoring send result - receiver may have been dropped
                drop(sender.send(params));
            }
        }
    };

    // Start HTTP server
    let addr = SocketAddr::from(([127, 0, 0, 1], input.port));

    // Use a simple TCP listener approach
    let listener = tokio::net::TcpListener::bind(addr).await?;
    eprintln!(
        "Listening for OAuth callback on http://127.0.0.1:{}/callback",
        input.port
    );

    // Wait for callback with timeout
    let callback_future = async {
        loop {
            let (mut socket, _) = listener.accept().await?;

            // Read the HTTP request
            let mut buf = [0u8; 4096];
            let n = tokio::io::AsyncReadExt::read(&mut socket, &mut buf).await?;
            let request = buf
                .get(..n)
                .map(|b| String::from_utf8_lossy(b))
                .unwrap_or_default();

            // Parse the request line to get the path
            if let Some(line) = request.lines().next() {
                if line.starts_with("GET /callback?") {
                    // Extract query string
                    if let Some(query_start) = line.find('?') {
                        if let Some(query_end) = line[query_start..].find(' ') {
                            let query = &line[query_start + 1..query_start + query_end];

                            // Parse query parameters
                            let params: std::collections::HashMap<String, String> =
                                url::form_urlencoded::parse(query.as_bytes())
                                    .into_owned()
                                    .collect();

                            if let (Some(oauth_token), Some(oauth_verifier)) =
                                (params.get("oauth_token"), params.get("oauth_verifier"))
                            {
                                // Send success response
                                let response = "HTTP/1.1 200 OK\r\n\
                                    Content-Type: text/html\r\n\
                                    Connection: close\r\n\r\n\
                                    <html><body><h1>Authorization successful!</h1>\
                                    <p>You can close this window.</p></body></html>";
                                tokio::io::AsyncWriteExt::write_all(
                                    &mut socket,
                                    response.as_bytes(),
                                )
                                .await?;

                                callback_handler(CallbackParams {
                                    oauth_token: oauth_token.clone(),
                                    oauth_verifier: oauth_verifier.clone(),
                                })
                                .await;

                                break;
                            }
                        }
                    }
                }
            }

            // Send 404 for other requests
            let response = "HTTP/1.1 404 Not Found\r\nConnection: close\r\n\r\n";
            tokio::io::AsyncWriteExt::write_all(&mut socket, response.as_bytes()).await?;
        }
        Ok::<(), Box<dyn std::error::Error + Send + Sync>>(())
    };

    // Run with timeout
    let timeout_duration = Duration::from_secs(input.timeout_secs);
    timeout(timeout_duration, callback_future)
        .await
        .map_err(|_| {
            format!(
                "Timeout waiting for callback after {} seconds",
                input.timeout_secs
            )
        })??;

    // Get the callback params
    let params = rx.await.map_err(|_| "Failed to receive callback")?;

    // Retrieve pending token from database
    let request_token = storage
        .get_pending_token(&params.oauth_token)
        .await?
        .ok_or_else(|| {
            format!(
                "No pending token found for oauth_token: {}",
                params.oauth_token
            )
        })?;

    // Exchange for access token
    let access_token = get_access_token(&config, &request_token, &params.oauth_verifier).await?;

    // Store access token (encrypted)
    storage.store_access_token(&access_token).await?;

    // Clean up pending token
    storage.delete_pending_token(&params.oauth_token).await?;

    Ok(Output {
        success: true,
        message: "Successfully connected to FatSecret. Access token stored.".to_string(),
    })
}
