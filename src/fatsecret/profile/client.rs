//! `FatSecret` Profile API client functions
//!
//! This module provides client functions for interacting with `FatSecret`'s Profile API.
//! These functions handle OAuth authentication, HTTP requests, and response parsing.
//!
//! # Key Functions
//!
//! - [`create_profile`] - Create a new user profile and receive OAuth credentials
//! - [`get_profile`] - Retrieve user's profile data (goals, metrics, preferences)
//! - [`get_profile_auth`] - Retrieve OAuth credentials for an existing user
//!
//! # Authentication
//!
//! All functions require:
//! - `config: &FatSecretConfig` - Your `FatSecret` API credentials (consumer key/secret)
//! - `access_token: &AccessToken` - OAuth access token (app-level for create/get_auth, user-level for get)
//!
//! # Usage Pattern
//!
//! ## Creating a Profile
//!
//! Use app-level credentials to create a new user profile:
//!
//! ```rust,no_run
//! use meal_planner::fatsecret::core::config::`FatSecretConfig`;
//! use meal_planner::fatsecret::core::oauth::`AccessToken`;
//! use meal_planner::fatsecret::profile::client::create_profile;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = `FatSecretConfig`::from_env()?;
//! let app_token = `AccessToken`::from_client_credentials(&config).await?;
//!
//! let profile_auth = create_profile(
//!     &config,
//!     &app_token,
//!     "my-unique-user-id"
//! ).await?;
//!
//! // Store these credentials for this user
//! println!("Token: {}", profile_auth.auth_token);
//! println!("Secret: {}", profile_auth.auth_secret);
//! # Ok(())
//! # }
//! ```
//!
//! ## Getting Profile Data
//!
//! Use user-level credentials to fetch their profile:
//!
//! ```rust,no_run
//! use meal_planner::fatsecret::core::config::`FatSecretConfig`;
//! use meal_planner::fatsecret::core::oauth::`AccessToken`;
//! use meal_planner::fatsecret::profile::client::get_profile;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = `FatSecretConfig`::from_env()?;
//!
//! // Load user's stored credentials
//! let user_token = `AccessToken` {
//!     token: "user-oauth-token".to_string(),
//!     secret: "user-oauth-secret".to_string(),
//! };
//!
//! let profile = get_profile(&config, &user_token).await?;
//!
//! if let Some(weight_kg) = profile.last_weight_kg {
//!     println!("Current weight: {} kg", weight_kg);
//! }
//! if let Some(goal_kg) = profile.goal_weight_kg {
//!     println!("Goal weight: {} kg", goal_kg);
//! }
//! # Ok(())
//! # }
//! ```
//!
//! # Error Handling
//!
//! All functions return `Result<T, FatSecretError>`:
//! - `FatSecretError::AuthError` - OAuth authentication failed
//! - `FatSecretError::HttpError` - HTTP request failed
//! - `FatSecretError::ParseError` - Response parsing failed
//! - `FatSecretError::ApiError` - `FatSecret` API returned an error
//!
//! # API Methods
//!
//! - `profile.create` → [`create_profile`]
//! - `profile.get` → [`get_profile`]
//! - `profile.get_auth` → [`get_profile_auth`]

use crate::fatsecret::core::config::FatSecretConfig;
use crate::fatsecret::core::errors::FatSecretError;
use crate::fatsecret::core::http::make_authenticated_request;
use crate::fatsecret::core::oauth::AccessToken;
use crate::fatsecret::profile::types::{
    Profile, ProfileAuth, ProfileAuthResponseWrapper, ProfileResponse,
};
use std::collections::HashMap;

/// Get user's profile information
///
/// API Method: profile.get
pub async fn get_profile(
    config: &FatSecretConfig,
    access_token: &AccessToken,
) -> Result<Profile, FatSecretError> {
    let body =
        make_authenticated_request(config, access_token, "profile.get", HashMap::new()).await?;

    let response: ProfileResponse = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse profile response: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.profile)
}

/// Create a new profile for a user
///
/// API Method: profile.create
pub async fn create_profile(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    user_id: &str,
) -> Result<ProfileAuth, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("user_id".to_string(), user_id.to_string());

    let body = make_authenticated_request(config, access_token, "profile.create", params).await?;

    let response: ProfileAuthResponseWrapper = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse profile auth response: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.profile)
}

/// Get profile authentication credentials for a user
///
/// API Method: profile.get_auth
pub async fn get_profile_auth(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    user_id: &str,
) -> Result<ProfileAuth, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("user_id".to_string(), user_id.to_string());

    let body = make_authenticated_request(config, access_token, "profile.get_auth", params).await?;

    let response: ProfileAuthResponseWrapper = serde_json::from_str(&body).map_err(|e| {
        FatSecretError::ParseError(format!(
            "Failed to parse profile auth response: {}. Body: {}",
            e, body
        ))
    })?;

    Ok(response.profile)
}

#[cfg(test)]
mod tests {
    use super::*;
    use wiremock::matchers::{body_string_contains, method, path};
    use wiremock::{Mock, MockServer, ResponseTemplate};

    fn test_config(mock_server: &MockServer) -> FatSecretConfig {
        FatSecretConfig::with_base_url("test_key", "test_secret", mock_server.uri())
    }

    fn test_token() -> AccessToken {
        AccessToken {
            oauth_token: "test_token".to_string(),
            oauth_token_secret: "test_secret".to_string(),
        }
    }

    // ========================================================================
    // get_profile tests
    // ========================================================================

    #[tokio::test]
    async fn test_get_profile_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=profile.get"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "profile": {
                        "goal_weight_kg": "70",
                        "last_weight_kg": "75",
                        "last_weight_date_int": "20000",
                        "height_cm": "180",
                        "calorie_goal": "2000",
                        "weight_measure": "Kg",
                        "height_measure": "Cm"
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_profile(&config, &token).await;
        assert!(result.is_ok());
        let profile = result.unwrap();
        assert_eq!(profile.goal_weight_kg, Some(70.0));
        assert_eq!(profile.last_weight_kg, Some(75.0));
    }

    #[tokio::test]
    async fn test_get_profile_parse_error() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=profile.get"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"invalid": "data"}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_profile(&config, &token).await;
        assert!(matches!(result, Err(FatSecretError::ParseError(_))));
    }

    // ========================================================================
    // create_profile tests
    // ========================================================================

    #[tokio::test]
    async fn test_create_profile_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=profile.create"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "profile": {
                        "auth_token": "abc123token",
                        "auth_secret": "xyz789secret"
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = create_profile(&config, &token, "user123").await;
        assert!(result.is_ok());
        let auth = result.unwrap();
        assert_eq!(auth.auth_token, "abc123token");
        assert_eq!(auth.auth_secret, "xyz789secret");
    }

    #[tokio::test]
    async fn test_create_profile_parse_error() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=profile.create"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"bad": "response"}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = create_profile(&config, &token, "user123").await;
        assert!(matches!(result, Err(FatSecretError::ParseError(_))));
    }

    // ========================================================================
    // get_profile_auth tests
    // ========================================================================

    #[tokio::test]
    async fn test_get_profile_auth_success() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=profile.get_auth"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{
                    "profile": {
                        "auth_token": "existing_token",
                        "auth_secret": "existing_secret"
                    }
                }"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_profile_auth(&config, &token, "user456").await;
        assert!(result.is_ok());
        let auth = result.unwrap();
        assert_eq!(auth.auth_token, "existing_token");
    }

    #[tokio::test]
    async fn test_get_profile_auth_parse_error() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .and(body_string_contains("method=profile.get_auth"))
            .respond_with(ResponseTemplate::new(200).set_body_string(r#"{"invalid": true}"#))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_profile_auth(&config, &token, "user789").await;
        assert!(matches!(result, Err(FatSecretError::ParseError(_))));
    }

    // ========================================================================
    // Error handling tests
    // ========================================================================

    #[tokio::test]
    async fn test_api_error_response() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .respond_with(ResponseTemplate::new(200).set_body_string(
                r#"{"error": {"code": 9, "message": "Invalid access token"}}"#,
            ))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = get_profile(&config, &token).await;
        assert!(result.is_err());
    }

    #[tokio::test]
    async fn test_http_error_response() {
        let mock_server = MockServer::start().await;

        Mock::given(method("POST"))
            .and(path("/rest/server.api"))
            .respond_with(ResponseTemplate::new(500).set_body_string("Server Error"))
            .mount(&mock_server)
            .await;

        let config = test_config(&mock_server);
        let token = test_token();

        let result = create_profile(&config, &token, "user123").await;
        assert!(result.is_err());
    }
}
