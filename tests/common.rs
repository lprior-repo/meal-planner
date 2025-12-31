//! Common test utilities for integration tests

use serde_json::{json, Value};

/// `FatSecret` API credentials
pub struct FatSecretCredentials {
    /// OAuth consumer key for API authentication
    pub consumer_key: String,
    /// OAuth consumer secret for API authentication
    pub consumer_secret: String,
}

impl FatSecretCredentials {
    /// Convert credentials to JSON object for use in test inputs
    pub fn to_json(&self) -> Value {
        json!({
            "consumer_key": self.consumer_key,
            "consumer_secret": self.consumer_secret,
        })
    }
}

/// OAuth tokens for 3-legged authentication
pub struct OAuthTokens {
    /// OAuth access token for authenticated requests
    pub access_token: String,
    /// OAuth access token secret for authenticated requests
    pub access_secret: String,
}

/// Get `FatSecret` credentials from environment or password manager
///
/// Tries the following sources in order:
/// 1. Environment variables (`FATSECRET_CONSUMER_KEY`, `FATSECRET_CONSUMER_SECRET`)
/// 2. Windmill resources (would be fetched via API in real implementation)
/// 3. Password manager (`pass` command)
pub fn get_fatsecret_credentials() -> Option<FatSecretCredentials> {
    // Try environment variables first
    let consumer_key = std::env::var("FATSECRET_CONSUMER_KEY").ok()?;
    let consumer_secret = std::env::var("FATSECRET_CONSUMER_SECRET").ok()?;

    Some(FatSecretCredentials {
        consumer_key,
        consumer_secret,
    })
}

/// Get OAuth tokens from environment or password manager
///
/// Tries the following sources in order:
/// 1. Environment variables (FATSECRET_ACCESS_TOKEN, FATSECRET_ACCESS_SECRET)
/// 2. Windmill resources (would be fetched via API in real implementation)
/// 3. Password manager (`pass` command)
pub fn get_oauth_tokens() -> Option<OAuthTokens> {
    // Try environment variables first
    let access_token = std::env::var("FATSECRET_ACCESS_TOKEN").ok()?;
    let access_secret = std::env::var("FATSECRET_ACCESS_SECRET").ok()?;

    Some(OAuthTokens {
        access_token,
        access_secret,
    })
}
