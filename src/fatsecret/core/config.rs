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
    /// Optional base URL override for testing (e.g., "http://127.0.0.1:8080")
    /// When set, this is used instead of constructing https://{host}
    pub base_url_override: Option<String>,
}

impl FatSecretConfig {
    /// Create a new `FatSecretConfig` with explicit credentials
    pub fn new(consumer_key: impl Into<String>, consumer_secret: impl Into<String>) -> Self {
        Self {
            consumer_key: consumer_key.into(),
            consumer_secret: consumer_secret.into(),
            api_host: None,
            auth_host: None,
            base_url_override: None,
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
            base_url_override: None,
        })
    }

    /// Create a test config with a base URL override (for mocking)
    pub fn with_base_url(
        consumer_key: impl Into<String>,
        consumer_secret: impl Into<String>,
        base_url: impl Into<String>,
    ) -> Self {
        Self {
            consumer_key: consumer_key.into(),
            consumer_secret: consumer_secret.into(),
            api_host: None,
            auth_host: None,
            base_url_override: Some(base_url.into()),
        }
    }

    /// Get the base URL for API requests
    /// Uses base_url_override if set (for testing), otherwise constructs from host
    pub fn get_base_url(&self) -> String {
        self.base_url_override
            .clone()
            .unwrap_or_else(|| format!("https://{}", self.api_host()))
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
            "https://{}/authorize?oauth_token={}",
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
            "https://authentication.fatsecret.com/authorize?oauth_token=token123"
        );
    }

    #[test]
    fn test_with_base_url() {
        let config = FatSecretConfig::with_base_url("key", "secret", "http://localhost:8080");
        assert_eq!(config.get_base_url(), "http://localhost:8080");
    }

    #[test]
    fn test_get_base_url_default() {
        let config = FatSecretConfig::new("key", "secret");
        assert_eq!(config.get_base_url(), "https://platform.fatsecret.com");
    }

    #[test]
    fn test_custom_api_host() {
        let mut config = FatSecretConfig::new("key", "secret");
        config.api_host = Some("custom.fatsecret.com".to_string());
        assert_eq!(config.api_host(), "custom.fatsecret.com");
        assert_eq!(config.get_api_host(), "custom.fatsecret.com");
        assert_eq!(
            config.api_url(),
            "https://custom.fatsecret.com/rest/server.api"
        );
    }

    #[test]
    fn test_custom_auth_host() {
        let mut config = FatSecretConfig::new("key", "secret");
        config.auth_host = Some("auth.custom.com".to_string());
        assert_eq!(config.auth_host(), "auth.custom.com");
        assert_eq!(config.get_auth_host(), "auth.custom.com");
        assert_eq!(
            config.authorization_url("token"),
            "https://auth.custom.com/authorize?oauth_token=token"
        );
    }

    #[test]
    fn test_config_clone() {
        let config = FatSecretConfig::new("key", "secret");
        let cloned = config.clone();
        assert_eq!(config.consumer_key, cloned.consumer_key);
        assert_eq!(config.consumer_secret, cloned.consumer_secret);
    }

    #[test]
    fn test_config_debug() {
        let config = FatSecretConfig::new("key", "secret");
        let debug_str = format!("{:?}", config);
        assert!(debug_str.contains("FatSecretConfig"));
        assert!(debug_str.contains("key"));
    }

    #[test]
    fn test_alias_methods() {
        let config = FatSecretConfig::new("key", "secret");
        // Verify alias methods return same values
        assert_eq!(config.api_host(), config.get_api_host());
        assert_eq!(config.auth_host(), config.get_auth_host());
    }

    #[test]
    fn test_base_url_override_takes_precedence() {
        let mut config = FatSecretConfig::new("key", "secret");
        config.api_host = Some("ignored.host.com".to_string());
        config.base_url_override = Some("http://mock:9999".to_string());
        // base_url_override takes precedence over api_host
        assert_eq!(config.get_base_url(), "http://mock:9999");
    }
}
