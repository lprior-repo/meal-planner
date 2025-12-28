//! FatSecret Core module
//!
//! Contains configuration, error types, OAuth utilities, and HTTP client.

mod config;
pub mod errors;

pub use config::FatSecretConfig;
pub use errors::{parse_error_response, ApiErrorCode, FatSecretError};

/// OAuth 1.0a access token (from 3-legged OAuth flow)
#[derive(Debug, Clone)]
pub struct AccessToken {
    pub oauth_token: String,
    pub oauth_token_secret: String,
}

impl AccessToken {
    pub fn new(oauth_token: impl Into<String>, oauth_token_secret: impl Into<String>) -> Self {
        Self {
            oauth_token: oauth_token.into(),
            oauth_token_secret: oauth_token_secret.into(),
        }
    }
}
