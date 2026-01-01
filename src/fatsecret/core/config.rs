//! `FatSecret` API Configuration
//!
//! Provides configuration for connecting to the `FatSecret` Platform API.
//! Ported from `src/meal_planner/fatsecret/core/config.gleam`

use std::env;

/// Default `FatSecret` API host
pub const DEFAULT_API_HOST: &str = "platform.fatsecret.com";

/// Default `FatSecret` authentication host
pub const DEFAULT_AUTH_HOST: &str = "authentication.fatsecret.com";

/// API endpoint path
pub const API_PATH: &str = "/rest/server.api";

/// `FatSecret` API configuration
#[derive(Debug, Clone)]
pub struct FatSecretConfig {
    /// The OAuth consumer key from `FatSecret` developer account
    pub consumer_key: String,
    /// The OAuth consumer secret from `FatSecret` developer account
    pub consumer_secret: String,
    /// Optional custom API host (defaults to platform.fatsecret.com)
    pub api_host: Option<String>,
    /// Optional custom authentication host (defaults to authentication.fatsecret.com)
    pub auth_host: Option<String>,
}

impl FatSecretConfig {
    /// Create a new `FatSecretConfig` with explicit credentials
    pub fn new(consumer_key: impl Into<String>, consumer_secret: impl Into<String>) -> Self {
        Self {
            consumer_key: consumer_key.into(),
            consumer_secret: consumer_secret.into(),
            api_host: None,
            auth_host: None,
        }
    }

    /// Create a new `FatSecretConfig` from environment variables
    ///
    /// Reads `FATSECRET_CONSUMER_KEY` and `FATSECRET_CONSUMER_SECRET` from environment.
    /// Optionally reads `FATSECRET_API_HOST` and `FATSECRET_AUTH_HOST` for custom hosts.
    pub fn from_env() -> Option<Self> {
        let consumer_key = env::var("FATSECRET_CONSUMER_KEY").ok()?;
        let consumer_secret = env::var("FATSECRET_CONSUMER_SECRET").ok()?;

        Some(Self {
            consumer_key,
            consumer_secret,
            api_host: env::var("FATSECRET_API_HOST").ok(),
            auth_host: env::var("FATSECRET_AUTH_HOST").ok(),
        })
    }

    /// Get the API host, using default if not configured
    pub fn api_host(&self) -> &str {
        self.api_host.as_deref().unwrap_or(DEFAULT_API_HOST)
    }

    /// Get the API host, using default if not configured (alias for Gleam compatibility)
    pub fn get_api_host(&self) -> &str {
        self.api_host()
    }

    /// Get the authentication host, using default if not configured
    pub fn auth_host(&self) -> &str {
        self.auth_host.as_deref().unwrap_or(DEFAULT_AUTH_HOST)
    }

    /// Get the authentication host, using default if not configured (alias for Gleam compatibility)
    pub fn get_auth_host(&self) -> &str {
        self.auth_host()
    }

    /// Get the full API URL
    pub fn api_url(&self) -> String {
        format!("https://{}{}", self.api_host(), API_PATH)
    }

    /// Get the OAuth authorization URL
    pub fn authorization_url(&self, oauth_token: &str) -> String {
        format!(
            "https://{}/oauth/authorize?oauth_token={}",
            self.auth_host(),
            oauth_token
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_new_config() {
        let config = FatSecretConfig::new("key", "secret");
        assert_eq!(config.consumer_key, "key");
        assert_eq!(config.consumer_secret, "secret");
        assert!(config.api_host.is_none());
        assert!(config.auth_host.is_none());
    }

    #[test]
    fn test_default_hosts() {
        let config = FatSecretConfig::new("key", "secret");
        assert_eq!(config.api_host(), DEFAULT_API_HOST);
        assert_eq!(config.auth_host(), DEFAULT_AUTH_HOST);
    }

    #[test]
    fn test_api_url() {
        let config = FatSecretConfig::new("key", "secret");
        assert_eq!(
            config.api_url(),
            "https://platform.fatsecret.com/rest/server.api"
        );
    }

    #[test]
    fn test_authorization_url() {
        let config = FatSecretConfig::new("key", "secret");
        assert_eq!(
            config.authorization_url("token123"),
            "https://authentication.fatsecret.com/oauth/authorize?oauth_token=token123"
        );
    }
}
