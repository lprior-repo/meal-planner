//! OAuth 1.0a authentication implementation for `FatSecret` Platform API
//!
//! This module provides complete OAuth 1.0a authentication for the `FatSecret` Platform API,
//! supporting both **2-legged** (application-only) and **3-legged** (user authorization)
//! authentication flows.
//!
//! # OAuth 1.0a Overview
//!
//! OAuth 1.0a is a signature-based authentication protocol that provides secure API access
//! without exposing user credentials. `FatSecret` uses this for all API operations.
//!
//! ## 2-Legged OAuth (Application-Only)
//!
//! Used for public, non-user-specific API calls:
//! - Food search (`foods.search`)
//! - Recipe search (`recipes.search.v3`)
//! - Exercise lookup (`exercises.get.v2`)
//!
//! Requires only **Consumer Key** and **Consumer Secret**.
//!
//! ## 3-Legged OAuth (User Authorization)
//!
//! Required for user-specific operations:
//! - Food diary (`food_entries.get`, `food_entry.create`)
//! - Weight tracking (`weights.get`, `weight.update`)
//! - Exercise tracking (`exercise_entries.get`)
//! - Saved meals and favorites
//!
//! Requires **Consumer Key**, **Consumer Secret**, and **Access Token** (obtained through user authorization).
//!
//! # Security Considerations
//!
//! ## Signature-Based Authentication
//!
//! - All requests must be signed with HMAC-SHA1
//! - Signatures include timestamp to prevent replay attacks
//! - Nonces prevent duplicate request attacks
//! - Requests expire after ~5 minutes (server clock tolerance)
//!
//! ## Secret Management
//!
//! **CRITICAL**: Never expose secrets in:
//! - Client-side code (JavaScript, mobile apps)
//! - Version control (git commits, public repos)
//! - Logs or error messages
//! - URLs or query parameters
//!
//! Secrets should be:
//! - Stored in environment variables or secure vaults
//! - Encrypted at rest (see `fatsecret::crypto` module)
//! - Rotated periodically
//! - Accessed only server-side
//!
//! ## Clock Skew
//!
//! OAuth 1.0a relies on timestamps. Ensure:
//! - System clock is synchronized (use NTP)
//! - Server time is within ±5 minutes of `FatSecret` servers
//! - Handle `401 Unauthorized` errors with timestamp issues
//!
//! # 3-Legged OAuth Flow
//!
//! ## Step 1: Get Request Token
//!
//! ```no_run
//! use meal_planner::fatsecret::core::{`FatSecretConfig`, oauth::get_request_token};
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = `FatSecretConfig`::from_env()?;
//! let callback_url = "https://yourapp.com/oauth/callback";
//!
//! let request_token = get_request_token(&config, callback_url).await?;
//! println!("Request Token: {}", request_token.`oauth_token`);
//! # Ok(())
//! # }
//! ```
//!
//! ## Step 2: User Authorization
//!
//! Redirect user to authorization URL:
//!
//! ```text
//! https://www.fatsecret.com/oauth/authorize?`oauth_token`={REQUEST_TOKEN}
//! ```
//!
//! User logs in and authorizes your app. `FatSecret` redirects back with:
//!
//! ```text
//! https://yourapp.com/oauth/callback?`oauth_token`={TOKEN}&oauth_verifier={VERIFIER}
//! ```
//!
//! ## Step 3: Exchange for Access Token
//!
//! ```no_run
//! use meal_planner::fatsecret::core::{`FatSecretConfig`, oauth::{get_access_token, `RequestToken`}};
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = `FatSecretConfig`::from_env()?;
//! # let request_token = `RequestToken` {
//! #     `oauth_token`: "token".to_string(),
//! #     oauth_token_secret: "secret".to_string(),
//! #     oauth_callback_confirmed: true,
//! # };
//! let oauth_verifier = "verifier_from_callback"; // From callback URL
//!
//! let access_token = get_access_token(&config, &request_token, oauth_verifier).await?;
//!
//! // Store access_token securely (encrypted in database)
//! println!("Access Token: {}", access_token.`oauth_token`);
//! # Ok(())
//! # }
//! ```
//!
//! ## Step 4: Make Authenticated Requests
//!
//! ```no_run
//! use meal_planner::fatsecret::core::{`FatSecretConfig`, oauth::`AccessToken`};
//! use meal_planner::fatsecret::diary::get_food_entries;
//! use chrono::NaiveDate;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = `FatSecretConfig`::from_env()?;
//! let access_token = `AccessToken`::new("token", "secret"); // From storage
//!
//! let date = NaiveDate::from_ymd_opt(2025, 1, 1).unwrap();
//! let entries = get_food_entries(&config, &access_token, date).await?;
//! # Ok(())
//! # }
//! ```
//!
//! # Signature Generation
//!
//! OAuth 1.0a signatures are generated using HMAC-SHA1:
//!
//! 1. **Build signature base string**: `METHOD&URL&SORTED_PARAMS`
//! 2. **Create signing key**: `{consumer_secret}&{token_secret}`
//! 3. **Sign with HMAC-SHA1**: `HMAC-SHA1(signing_key, base_string)`
//! 4. **Base64 encode**: Result is the `oauth_signature`
//!
//! This is handled automatically by `build_oauth_params()`.
//!
//! # Common Pitfalls
//!
//! ## Percent Encoding
//!
//! OAuth 1.0a uses **RFC 3986** encoding (not `application/x-www-form-urlencoded`):
//!
//! - MUST encode: `! * ' ( ) ; : @ & = + $ , / ? # [ ] %`
//! - MUST NOT encode: `A-Z a-z 0-9 - . _ ~`
//! - Encode as uppercase hex: `%20` not `%2a`
//!
//! Use `oauth_encode()` for all OAuth parameters.
//!
//! ## Signing Key Format
//!
//! Signing key components are **NOT percent-encoded**:
//!
//! ```text
//! signing_key = `consumer_secret` & token_secret
//! ```
//!
//! NOT:
//!
//! ```text
//! signing_key = percent_encode(`consumer_secret`) & percent_encode(token_secret)
//! ```
//!
//! ## Parameter Sorting
//!
//! Parameters must be sorted **lexicographically by key** before signing:
//!
//! ```text
//! `oauth_consumer_key`=...&`oauth_nonce`=...&`oauth_signature_method`=...
//! ```
//!
//! ## Timestamp Validation
//!
//! If requests fail with 401:
//! - Check system clock synchronization
//! - Verify timestamp is within ±5 minutes of server
//! - Use `date -u` to check UTC time
//!
//! # API Reference
//!
//! - [`FatSecret` Platform API](https://platform.fatsecret.com/api/)
//! - [OAuth 1.0a Spec (RFC 5849)](https://tools.ietf.org/html/rfc5849)
//! - [OAuth Authentication Guide](https://platform.fatsecret.com/api/Default.aspx?screen=rapih)
//!
//! # Performance Notes
//!
//! - Signature generation: ~50-200 μs per request
//! - Network latency: ~100-500 ms (typical API roundtrip)
//! - Token storage: Use encrypted database (see `fatsecret::storage`)
//!
//! # Related Modules
//!
//! - `fatsecret::crypto` - Encryption for token storage
//! - `fatsecret::storage` - Database persistence for tokens
//! - `fatsecret::core::http` - HTTP client with OAuth signing

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
/// This function handles the extremely rare case of RNG failure gracefully.
pub fn generate_nonce() -> String {
    let rng = SystemRandom::new();
    let mut bytes = [0u8; 16];
    // RNG failure is extremely rare (hardware/OS issue) - use fallback
    if rng.fill(&mut bytes).is_err() {
        // Fallback: use timestamp + fixed entropy (not ideal but functional)
        let ts = unix_timestamp();
        return format!("{:016x}{:016x}", ts, ts.wrapping_mul(0x517cc1b727220a95));
    }
    hex::encode(bytes)
}

/// Get current Unix timestamp in seconds
///
/// Returns the current time as seconds since Unix epoch.
/// Handles the theoretical case of system clock before epoch gracefully.
pub fn unix_timestamp() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0) // Clock before epoch = 0 (shouldn't happen but safe)
}

/// RFC 3986 percent-encoding for OAuth 1.0a
///
/// Must encode all characters except: A-Z a-z 0-9 - . _ ~
#[allow(clippy::arithmetic_side_effects, clippy::as_conversions)]
// Safe: byte values 0-255, nibbles 0-15, ASCII char arithmetic is bounded
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
/// Format: `METHOD&URL&SORTED_PARAMS`
/// All components must be percent-encoded
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
/// Signing key = `consumer_secret`& OR `consumer_secret`&`token_secret`
/// Note: The signing key components are NOT percent-encoded per OAuth 1.0a spec
/// Result is base64-encoded
pub fn create_signature(
    base_string: &str,
    consumer_secret: &str,
    token_secret: Option<&str>,
) -> String {
    let signing_key = format!("{consumer_secret}&{}", token_secret.unwrap_or(""));
    let key = hmac::Key::new(hmac::HMAC_SHA1_FOR_LEGACY_USE_ONLY, signing_key.as_bytes());
    let signature = hmac::sign(&key, base_string.as_bytes());
    base64::engine::general_purpose::STANDARD.encode(signature.as_ref())
}

/// Build complete OAuth 1.0a parameter set with signature
///
/// Includes: `oauth_consumer_key`, `oauth_signature_method`, `oauth_timestamp`,
/// `oauth_nonce`, `oauth_version`, `oauth_token` (if provided), `oauth_signature`,
/// plus any `extra_params`
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
) -> HashMap<String, String> {
    let timestamp = unix_timestamp().to_string();
    let nonce = generate_nonce();

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
    params_without_sig
        .into_iter()
        .chain(std::iter::once(("oauth_signature".to_string(), signature)))
        .collect()
}

/// Parse OAuth response string (key=value&key2=value2) into a hash map
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
#[allow(clippy::unwrap_used)] // Tests are allowed to use unwrap/expect
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
