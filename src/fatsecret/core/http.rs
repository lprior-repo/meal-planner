//! FatSecret SDK HTTP client with OAuth signing
//!
//! All requests to the FatSecret API must be signed with OAuth 1.0a.
//! This module handles signing and executing HTTP requests using reqwest.

use reqwest::{Client, Method};
use std::collections::HashMap;

use crate::fatsecret::core::errors::parse_error_response;
use crate::fatsecret::core::oauth::{build_oauth_params, oauth_encode};
use crate::fatsecret::core::{AccessToken, FatSecretConfig, FatSecretError};

/// Make signed OAuth request (2-legged or 3-legged)
///
/// This is the low-level request function. Most users should use
/// make_api_request() or make_authenticated_request() instead.
#[allow(clippy::too_many_arguments)] // OAuth signing requires these params
pub async fn make_oauth_request(
    config: &FatSecretConfig,
    method: Method,
    host: &str,
    path: &str,
    params: &HashMap<String, String>,
    token: Option<&str>,
    token_secret: Option<&str>,
) -> Result<String, FatSecretError> {
    // Use base_url_override if set (for testing), otherwise construct from host
    let url = if config.base_url_override.is_some() {
        format!("{}{}", config.get_base_url(), path)
    } else {
        format!("https://{}{}", host, path)
    };

    // Build OAuth parameters with signature
    let oauth_params = build_oauth_params(
        &config.consumer_key,
        &config.consumer_secret,
        method.as_str(),
        &url,
        params,
        token,
        token_secret,
    );

    let client = Client::new();
    let response = if method == Method::GET {
        // For GET: parameters go in query string
        let query: Vec<_> = oauth_params
            .iter()
            .map(|(k, v)| format!("{}={}", k, oauth_encode(v)))
            .collect();
        let query_string = query.join("&");
        let full_url = if query_string.is_empty() {
            url
        } else {
            format!("{}?{}", url, query_string)
        };

        client.get(&full_url).send().await?
    } else {
        // For POST: parameters go in body
        let body: Vec<_> = oauth_params
            .iter()
            .map(|(k, v)| format!("{}={}", k, oauth_encode(v)))
            .collect();
        let body_string = body.join("&");

        client
            .post(&url)
            .header("Content-Type", "application/x-www-form-urlencoded")
            .body(body_string)
            .send()
            .await?
    };

    let status = response.status();
    let body = response.text().await?;

    if !status.is_success() {
        return Err(FatSecretError::RequestFailed {
            status: status.as_u16(),
            body,
        });
    }

    Ok(body)
}

/// Make 2-legged API request (public data, no user token)
///
/// This is used for API methods that don't require user authentication,
/// such as foods.search or food.get.
pub async fn make_api_request(
    config: &FatSecretConfig,
    method_name: &str,
    params: HashMap<String, String>,
) -> Result<String, FatSecretError> {
    let mut api_params = params;
    api_params.insert("method".to_string(), method_name.to_string());
    api_params.insert("format".to_string(), "json".to_string());

    let body = make_oauth_request(
        config,
        Method::POST,
        config.api_host(),
        "/rest/server.api",
        &api_params,
        None,
        None,
    )
    .await?;

    check_api_error(body)
}

/// Make 3-legged API request (user data, requires access token)
///
/// This is used for API methods that require user authentication,
/// such as food_entries.get or food_entry.create.
pub async fn make_authenticated_request(
    config: &FatSecretConfig,
    access_token: &AccessToken,
    method_name: &str,
    params: HashMap<String, String>,
) -> Result<String, FatSecretError> {
    let mut api_params = params;
    api_params.insert("method".to_string(), method_name.to_string());
    api_params.insert("format".to_string(), "json".to_string());

    let body = make_oauth_request(
        config,
        Method::POST,
        config.api_host(),
        "/rest/server.api",
        &api_params,
        Some(&access_token.oauth_token),
        Some(&access_token.oauth_token_secret),
    )
    .await?;

    check_api_error(body)
}

/// Check response for API errors
fn check_api_error(body: String) -> Result<String, FatSecretError> {
    parse_error_response(&body).map_or(Ok(body), Err)
}
