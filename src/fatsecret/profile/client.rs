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
//! - `access_token: &AccessToken` - OAuth access token (app-level for `create/get_auth`, user-level for get)
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
/// API Method: `profile.get_auth`
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
