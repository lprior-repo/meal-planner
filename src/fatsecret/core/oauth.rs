//! OAuth 1.0a authentication types and utilities for FatSecret
//!
//! FatSecret uses OAuth 1.0a for both 2-legged (app-only) and 3-legged (user) authentication.
//! API Documentation: https://platform.fatsecret.com/api/Default.aspx?screen=rapih

use base64::Engine;
use reqwest::Method;
use ring::hmac;
use ring::rand::{SecureRandom, SystemRandom};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::time::{SystemTime, UNIX_EPOCH};

use crate::fatsecret::core::http::make_oauth_request;
use crate::fatsecret::core::{FatSecretConfig, FatSecretError};

/// OAuth 1.0a request token (from Step 1 of 3-legged flow)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RequestToken {
    /// The temporary token used for user authorization
    pub oauth_token: String,
    /// The secret associated with the temporary token
    pub oauth_token_secret: String,
    /// Whether the callback URL was confirmed by the server
    pub oauth_callback_confirmed: bool,
}

/// OAuth 1.0a access token (from Step 3 of 3-legged flow)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AccessToken {
    /// The long-lived token for accessing user resources
    pub oauth_token: String,
    /// The secret used to sign requests with this token
    pub oauth_token_secret: String,
}

impl AccessToken {
    /// Creates a new access token from the given credentials
    pub fn new(oauth_token: impl Into<String>, oauth_token_secret: impl Into<String>) -> Self {
        Self {
            oauth_token: oauth_token.into(),
            oauth_token_secret: oauth_token_secret.into(),
        }
    }
}

/// Generate OAuth nonce (random hex string)
///
/// Returns a cryptographically secure random nonce for OAuth signing.
///
/// # Errors
/// Returns `FatSecretError::OAuthError` if the system RNG fails (extremely rare).
pub fn generate_nonce() -> Result<String, FatSecretError> {
    let rng = SystemRandom::new();
    let mut bytes = [0u8; 16];
    rng.fill(&mut bytes)
        .map_err(|_| FatSecretError::oauth_error("Failed to generate random bytes for nonce"))?;
    Ok(hex::encode(bytes))
}

/// Get current Unix timestamp in seconds
///
/// Returns the current time as seconds since Unix epoch.
///
/// # Errors
/// Returns `FatSecretError::OAuthError` if system clock is before Unix epoch
/// (can happen in containers, VMs, or misconfigured systems).
pub fn unix_timestamp() -> Result<u64, FatSecretError> {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .map_err(|_| FatSecretError::oauth_error("System clock is before Unix epoch"))
}

/// RFC 3986 percent-encoding for OAuth 1.0a
///
/// Must encode all characters except: A-Z a-z 0-9 - . _ ~
#[must_use]
pub fn oauth_encode(s: &str) -> String {
    let mut result = String::new();
    for byte in s.bytes() {
        match byte {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'.' | b'_' | b'~' => {
                result.push(byte as char);
            }
            _ => {
                // Format each byte as %XX hex encoding
                result.push('%');
                // High nibble
                let hi = byte >> 4;
                result.push(if hi < 10 {
                    (b'0' + hi) as char
                } else {
                    (b'A' + hi - 10) as char
                });
                // Low nibble
                let lo = byte & 0x0F;
                result.push(if lo < 10 {
                    (b'0' + lo) as char
                } else {
                    (b'A' + lo - 10) as char
                });
            }
        }
    }
    result
}

/// Create OAuth 1.0a signature base string
///
/// Format: METHOD&URL&SORTED_PARAMS
/// All components must be percent-encoded
#[must_use]
pub fn create_signature_base_string(
    method: &str,
    url: &str,
    params: &HashMap<String, String>,
) -> String {
    let mut sorted_params: Vec<_> = params.iter().collect();
    sorted_params.sort_by(|a, b| a.0.cmp(b.0));

    let params_string: String = sorted_params
        .iter()
        .map(|(k, v)| format!("{}={}", oauth_encode(k), oauth_encode(v)))
        .collect::<Vec<_>>()
        .join("&");

    format!(
        "{}&{}&{}",
        method.to_uppercase(),
        oauth_encode(url),
        oauth_encode(&params_string)
    )
}

/// Create HMAC-SHA1 signature for OAuth 1.0a
///
/// Signing key = consumer_secret& OR consumer_secret&token_secret
/// Note: The signing key components are NOT percent-encoded per OAuth 1.0a spec
/// Result is base64-encoded
#[must_use]
pub fn create_signature(
    base_string: &str,
    consumer_secret: &str,
    token_secret: Option<&str>,
) -> String {
    let signing_key = format!("{consumer_secret}&{token_secret.unwrap_or(""}"));
    let key = hmac::Key::new(hmac::HMAC_SHA1_FOR_LEGACY_USE_ONLY, signing_key.as_bytes());
    let signature = hmac::sign(&key, base_string.as_bytes());
    base64::engine::general_purpose::STANDARD.encode(signature.as_ref())
}

/// Build complete OAuth 1.0a parameter set with signature
///
/// Includes: oauth_consumer_key, oauth_signature_method, oauth_timestamp,
/// oauth_nonce, oauth_version, oauth_token (if provided), oauth_signature,
/// plus any extra_params
///
/// # Gleam-style: Built immutably using iterator chains
#[allow(clippy::too_many_arguments)] // OAuth 1.0a spec requires these params
pub fn build_oauth_params(
    consumer_key: &str,
    consumer_secret: &str,
    method: &str,
    url: &str,
    extra_params: &HashMap<String, String>,
    token: Option<&str>,
    token_secret: Option<&str>,
) -> Result<HashMap<String, String>, FatSecretError> {
    let timestamp = unix_timestamp()?.to_string();
    let nonce = generate_nonce()?;

    // Base OAuth parameters (immutable construction)
    let base_params = [
        ("oauth_consumer_key", consumer_key.to_string()),
        ("oauth_signature_method", "HMAC-SHA1".to_string()),
        ("oauth_timestamp", timestamp),
        ("oauth_nonce", nonce),
        ("oauth_version", "1.0".to_string()),
    ];

    // Build params immutably: base + optional token + extra params
    let params_without_sig: HashMap<String, String> = base_params
        .into_iter()
        .map(|(k, v)| (k.to_string(), v))
        .chain(token.map(|t| ("oauth_token".to_string(), t.to_string())))
        .chain(extra_params.iter().map(|(k, v)| (k.clone(), v.clone())))
        .collect();

    // Compute signature from params
    let base_string = create_signature_base_string(method, url, &params_without_sig);
    let signature = create_signature(&base_string, consumer_secret, token_secret);

    // Return final params with signature (immutable extension)
    Ok(params_without_sig
        .into_iter()
        .chain(std::iter::once(("oauth_signature".to_string(), signature)))
        .collect())
}

/// Parse OAuth response string (key=value&key2=value2) into a hash map
#[must_use]
pub fn parse_oauth_response(response: &str) -> HashMap<String, String> {
    url::form_urlencoded::parse(response.as_bytes())
        .into_owned()
        .collect()
}

// ============================================================================
// OAuth 1.0a Flow - 3-legged Authentication
// ============================================================================

/// Get OAuth request token (Step 1 of 3-legged flow)
pub async fn get_request_token(
    config: &FatSecretConfig,
    callback_url: &str,
) -> Result<RequestToken, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("oauth_callback".to_string(), callback_url.to_string());

    let body = make_oauth_request(
        config,
        Method::POST,
        config.auth_host(),
        "/oauth/request_token",
        &params,
        None,
        None,
    )
    .await?;

    let response_params = parse_oauth_response(&body);

    let oauth_token = response_params
        .get("oauth_token")
        .ok_or_else(|| FatSecretError::oauth_error("Missing oauth_token"))?
        .clone();
    let oauth_token_secret = response_params
        .get("oauth_token_secret")
        .ok_or_else(|| FatSecretError::oauth_error("Missing oauth_token_secret"))?
        .clone();
    let oauth_callback_confirmed = response_params
        .get("oauth_callback_confirmed")
        .is_some_and(|v| v == "true");

    Ok(RequestToken {
        oauth_token,
        oauth_token_secret,
        oauth_callback_confirmed,
    })
}

/// Exchange authorized request token for access token (Step 3 of 3-legged flow)
pub async fn get_access_token(
    config: &FatSecretConfig,
    request_token: &RequestToken,
    oauth_verifier: &str,
) -> Result<AccessToken, FatSecretError> {
    let mut params = HashMap::new();
    params.insert("oauth_verifier".to_string(), oauth_verifier.to_string());

    let body = make_oauth_request(
        config,
        Method::GET,
        config.auth_host(),
        "/oauth/access_token",
        &params,
        Some(&request_token.oauth_token),
        Some(&request_token.oauth_token_secret),
    )
    .await?;

    let response_params = parse_oauth_response(&body);

    let oauth_token = response_params
        .get("oauth_token")
        .ok_or_else(|| FatSecretError::oauth_error("Missing oauth_token"))?
        .clone();
    let oauth_token_secret = response_params
        .get("oauth_token_secret")
        .ok_or_else(|| FatSecretError::oauth_error("Missing oauth_token_secret"))?
        .clone();

    Ok(AccessToken {
        oauth_token,
        oauth_token_secret,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_oauth_encode() {
        assert_eq!(oauth_encode("abcABC123-._~"), "abcABC123-._~");
        assert_eq!(oauth_encode(" "), "%20");
        assert_eq!(oauth_encode("&"), "%26");
        assert_eq!(oauth_encode("="), "%3D");
        // Multi-byte UTF-8
        assert_eq!(oauth_encode("🔥"), "%F0%9F%94%A5");
    }

    #[test]
    fn test_create_signature_base_string() {
        let mut params = HashMap::new();
        params.insert("oauth_consumer_key".to_string(), "key".to_string());
        params.insert("oauth_nonce".to_string(), "abc".to_string());
        params.insert(
            "oauth_signature_method".to_string(),
            "HMAC-SHA1".to_string(),
        );
        params.insert("oauth_timestamp".to_string(), "123".to_string());
        params.insert("oauth_version".to_string(), "1.0".to_string());

        let base = create_signature_base_string("POST", "https://api.example.com", &params);
        // Sorted params: oauth_consumer_key, oauth_nonce, oauth_signature_method, oauth_timestamp, oauth_version
        assert!(base.contains("POST&https%3A%2F%2Fapi.example.com&oauth_consumer_key%3Dkey"));
    }

    #[test]
    fn test_parse_oauth_response() {
        let response =
            "oauth_token=token123&oauth_token_secret=secret456&oauth_callback_confirmed=true";
        let params = parse_oauth_response(response);
        assert_eq!(params.get("oauth_token").unwrap(), "token123");
        assert_eq!(params.get("oauth_token_secret").unwrap(), "secret456");
        assert_eq!(params.get("oauth_callback_confirmed").unwrap(), "true");
    }
}
