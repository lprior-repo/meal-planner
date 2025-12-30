//! Start FatSecret OAuth flow
//!
//! Gets a request token and returns the authorization URL.
//!
//! ```cargo
//! [dependencies]
//! anyhow = "1.0"
//! serde = { version = "1.0", features = ["derive"] }
//! serde_json = "1.0"
//! ureq = "2.10"
//! url = "2.5"
//! ring = "0.17"
//! base64 = "0.22"
//! chrono = "0.4"
//! hex = "0.4"
//! getrandom = "0.2"
//! wmill = "1"
//! ```

use base64::{engine::general_purpose::STANDARD, Engine};
use getrandom::getrandom;
use ring::hmac;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use wmill::Windmill;

const REQUEST_TOKEN_URL: &str = "https://authentication.fatsecret.com/oauth/request_token";
const AUTHORIZE_URL: &str = "https://authentication.fatsecret.com/oauth/authorize";
const PENDING_TOKEN_RESOURCE: &str = "u/admin/fatsecret_pending_oauth";

#[derive(Deserialize)]
pub struct FatSecretConfig {
    pub consumer_key: String,
    pub consumer_secret: String,
}

#[derive(Serialize)]
pub struct Output {
    pub success: bool,
    pub auth_url: String,
    pub message: String,
}

fn oauth_encode(s: &str) -> String {
    url::form_urlencoded::byte_serialize(s.as_bytes()).collect()
}

fn generate_nonce() -> String {
    let mut bytes = [0u8; 16];
    getrandom(&mut bytes).expect("Failed to generate random bytes");
    hex::encode(bytes)
}

fn generate_timestamp() -> String {
    chrono::Utc::now().timestamp().to_string()
}

fn create_signature(
    method: &str,
    url: &str,
    params: &HashMap<String, String>,
    consumer_secret: &str,
    token_secret: Option<&str>,
) -> String {
    let mut sorted_params: Vec<_> = params.iter().collect();
    sorted_params.sort_by(|a, b| a.0.cmp(b.0));

    let param_string: String = sorted_params
        .iter()
        .map(|(k, v)| format!("{}={}", oauth_encode(k), oauth_encode(v)))
        .collect::<Vec<_>>()
        .join("&");

    let base_string = format!(
        "{}&{}&{}",
        method.to_uppercase(),
        oauth_encode(url),
        oauth_encode(&param_string)
    );

    let key = format!(
        "{}&{}",
        oauth_encode(consumer_secret),
        oauth_encode(token_secret.unwrap_or(""))
    );

    let signing_key = hmac::Key::new(hmac::HMAC_SHA1_FOR_LEGACY_USE_ONLY, key.as_bytes());
    let signature = hmac::sign(&signing_key, base_string.as_bytes());
    STANDARD.encode(signature.as_ref())
}

fn main(fatsecret: FatSecretConfig, callback_url: String) -> anyhow::Result<Output> {
    let wm = Windmill::default()?;

    // Build OAuth parameters
    let mut params = HashMap::new();
    params.insert("oauth_consumer_key".to_string(), fatsecret.consumer_key.clone());
    params.insert("oauth_signature_method".to_string(), "HMAC-SHA1".to_string());
    params.insert("oauth_timestamp".to_string(), generate_timestamp());
    params.insert("oauth_nonce".to_string(), generate_nonce());
    params.insert("oauth_version".to_string(), "1.0".to_string());
    params.insert("oauth_callback".to_string(), callback_url);

    // Create signature
    let signature = create_signature(
        "POST",
        REQUEST_TOKEN_URL,
        &params,
        &fatsecret.consumer_secret,
        None,
    );
    params.insert("oauth_signature".to_string(), signature);

    // Make request to FatSecret
    let query: String = params
        .iter()
        .map(|(k, v)| format!("{}={}", oauth_encode(k), oauth_encode(v)))
        .collect::<Vec<_>>()
        .join("&");

    let response = ureq::post(REQUEST_TOKEN_URL)
        .set("Content-Type", "application/x-www-form-urlencoded")
        .send_string(&query)?
        .into_string()?;

    // Parse response
    let response_params: HashMap<String, String> = url::form_urlencoded::parse(response.as_bytes())
        .into_owned()
        .collect();

    let oauth_token = response_params
        .get("oauth_token")
        .ok_or_else(|| anyhow::anyhow!("Missing oauth_token in response: {}", response))?;
    let oauth_token_secret = response_params
        .get("oauth_token_secret")
        .ok_or_else(|| anyhow::anyhow!("Missing oauth_token_secret"))?;

    // Store tokens internally as Windmill resource
    let resource_value = serde_json::json!({
        "oauth_token": oauth_token,
        "oauth_token_secret": oauth_token_secret,
        "created_at": chrono::Utc::now().to_rfc3339()
    });

    wm.set_resource(
        Some(resource_value),
        PENDING_TOKEN_RESOURCE,
        "state"
    )?;

    let auth_url = format!("{}?oauth_token={}", AUTHORIZE_URL, oauth_encode(oauth_token));

    Ok(Output {
        success: true,
        auth_url,
        message: "Visit auth_url to authorize, then run oauth_complete with the verifier code.".to_string(),
    })
}
