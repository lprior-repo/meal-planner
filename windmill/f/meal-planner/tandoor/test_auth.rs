//! Tandoor API Authentication Test
//!
//! Tests connectivity and authentication against a Tandoor instance.
//! Returns basic instance info on success.
//!
//! ```cargo
//! [dependencies]
//! anyhow = "1.0.86"
//! reqwest = { version = "0.12", features = ["json"] }
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! tokio = { version = "1", features = ["full"] }
//! thiserror = "1.0"
//! ```

use anyhow::{Context, Result};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use thiserror::Error;

/// Tandoor API configuration passed as resource
#[derive(Deserialize)]
struct TandoorConfig {
    base_url: String,
    api_token: String,
}

/// Errors specific to Tandoor API operations
#[derive(Error, Debug)]
pub enum TandoorError {
    #[error("Authentication failed: {0}")]
    AuthError(String),

    #[error("Request failed with status {status}: {body}")]
    RequestFailed { status: u16, body: String },

    #[error("Network error: {0}")]
    NetworkError(String),

    #[error("Failed to parse response: {0}")]
    ParseError(String),
}

impl From<reqwest::Error> for TandoorError {
    fn from(error: reqwest::Error) -> Self {
        if error.is_timeout() {
            Self::NetworkError(format!("Request timed out: {}", error))
        } else if error.is_connect() {
            Self::NetworkError(format!("Connection failed: {}", error))
        } else if error.is_decode() {
            Self::ParseError(format!("Failed to decode response: {}", error))
        } else {
            Self::NetworkError(error.to_string())
        }
    }
}

/// Paginated response wrapper from Tandoor API
#[derive(Deserialize)]
struct PaginatedResponse<T> {
    count: i64,
    next: Option<String>,
    previous: Option<String>,
    results: Vec<T>,
}

/// Minimal recipe info for auth test
#[derive(Deserialize, Serialize)]
struct RecipeSummary {
    id: i64,
    name: String,
}

/// Result of authentication test
#[derive(Serialize)]
struct AuthTestResult {
    success: bool,
    message: String,
    recipe_count: i64,
    sample_recipes: Vec<RecipeSummary>,
}

/// Make authenticated GET request to Tandoor API
async fn get<T: for<'de> Deserialize<'de>>(
    client: &Client,
    base_url: &str,
    path: &str,
    api_token: &str,
) -> Result<T, TandoorError> {
    let url = format!("{}{}", base_url.trim_end_matches('/'), path);

    let response = client
        .get(&url)
        .header("Authorization", format!("Bearer {}", api_token))
        .header("Host", "localhost") // Required for Docker networking
        .header("Content-Type", "application/json")
        .send()
        .await?;

    let status = response.status();
    let body = response.text().await?;

    if status.as_u16() == 401 || status.as_u16() == 403 {
        return Err(TandoorError::AuthError(body));
    }

    if !status.is_success() {
        return Err(TandoorError::RequestFailed {
            status: status.as_u16(),
            body,
        });
    }

    serde_json::from_str(&body).map_err(|e| TandoorError::ParseError(e.to_string()))
}

/// Test authentication by fetching recipes list
async fn test_authentication(config: &TandoorConfig) -> Result<AuthTestResult> {
    let client = Client::builder()
        .timeout(std::time::Duration::from_secs(30))
        .build()
        .context("Failed to create HTTP client")?;

    let response: PaginatedResponse<RecipeSummary> =
        get(&client, &config.base_url, "/api/recipe/", &config.api_token)
            .await
            .context("Failed to fetch recipes")?;

    Ok(AuthTestResult {
        success: true,
        message: format!(
            "Successfully authenticated to Tandoor. Found {} recipes.",
            response.count
        ),
        recipe_count: response.count,
        sample_recipes: response.results.into_iter().take(5).collect(),
    })
}

#[tokio::main]
async fn main(tandoor: TandoorConfig) -> Result<AuthTestResult> {
    test_authentication(&tandoor).await
}
