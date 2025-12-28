//! FatSecret SDK Profile API client

use std::collections::HashMap;
use crate::fatsecret::core::config::FatSecretConfig;
use crate::fatsecret::core::errors::FatSecretError;
use crate::fatsecret::core::http::make_authenticated_request;
use crate::fatsecret::core::oauth::AccessToken;
use crate::fatsecret::profile::types::{Profile, ProfileAuth, ProfileResponse, ProfileAuthResponseWrapper};

/// Get user's profile information
///
/// API Method: profile.get
pub async fn get_profile(
    config: &FatSecretConfig,
    access_token: &AccessToken,
) -> Result<Profile, FatSecretError> {
    let body = make_authenticated_request(
        config,
        access_token,
        "profile.get",
        HashMap::new(),
    ).await?;

    let response: ProfileResponse = serde_json::from_str(&body)
        .map_err(|e| FatSecretError::ParseError(format!("Failed to parse profile response: {}. Body: {}", e, body)))?;

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

    let body = make_authenticated_request(
        config,
        access_token,
        "profile.create",
        params,
    ).await?;

    let response: ProfileAuthResponseWrapper = serde_json::from_str(&body)
        .map_err(|e| FatSecretError::ParseError(format!("Failed to parse profile auth response: {}. Body: {}", e, body)))?;

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

    let body = make_authenticated_request(
        config,
        access_token,
        "profile.get_auth",
        params,
    ).await?;

    let response: ProfileAuthResponseWrapper = serde_json::from_str(&body)
        .map_err(|e| FatSecretError::ParseError(format!("Failed to parse profile auth response: {}. Body: {}", e, body)))?;

    Ok(response.profile)
}
