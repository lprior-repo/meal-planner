//! Get FatSecret user profile
//!
//! Retrieves the authenticated user's profile.
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

const API_URL: &str = "https://platform.fatsecret.com/rest/server.api";
const ACCESS_TOKEN_RESOURCE: &str = "u/admin/fatsecret_oauth_credentials";

#[derive(Deserialize)]
pub struct FatSecretConfig {
    pub consumer_key: String,
    pub consumer_secret: String,
}

#[derive(Deserialize)]
struct StoredCredentials {
    oauth_token: String,
    oauth_token_secret: String,
}

#[derive(Serialize)]
pub struct Output {
    pub success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub height_cm: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub last_weight_kg: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub goal_weight_kg: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
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
    token_secret: &str,
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
        oauth_encode(token_secret)
    );

    let signing_key = hmac::Key::new(hmac::HMAC_SHA1_FOR_LEGACY_USE_ONLY, key.as_bytes());
    let signature = hmac::sign(&signing_key, base_string.as_bytes());
    STANDARD.encode(signature.as_ref())
}

fn main(fatsecret: FatSecretConfig) -> anyhow::Result<Output> {
    let wm = Windmill::default()?;

    // Read credentials from internal resource
    let creds: StoredCredentials = wm.get_resource(ACCESS_TOKEN_RESOURCE)
        .map_err(|e| anyhow::anyhow!("No OAuth credentials found. Run oauth_start and oauth_complete first. Error: {}", e))?;

    // Build OAuth parameters
    let mut params = HashMap::new();
    params.insert("oauth_consumer_key".to_string(), fatsecret.consumer_key.clone());
    params.insert("oauth_token".to_string(), creds.oauth_token.clone());
    params.insert("oauth_signature_method".to_string(), "HMAC-SHA1".to_string());
    params.insert("oauth_timestamp".to_string(), generate_timestamp());
    params.insert("oauth_nonce".to_string(), generate_nonce());
    params.insert("oauth_version".to_string(), "1.0".to_string());
    params.insert("method".to_string(), "profile.get".to_string());
    params.insert("format".to_string(), "json".to_string());

    // Create signature
    let signature = create_signature(
        "GET",
        API_URL,
        &params,
        &fatsecret.consumer_secret,
        &creds.oauth_token_secret,
    );
    params.insert("oauth_signature".to_string(), signature);

    // Make request
    let query: String = params
        .iter()
        .map(|(k, v)| format!("{}={}", oauth_encode(k), oauth_encode(v)))
        .collect::<Vec<_>>()
        .join("&");

    let url = format!("{}?{}", API_URL, query);
    
    match ureq::get(&url).call() {
        Ok(resp) => {
            let body = resp.into_string()?;
            let json: serde_json::Value = serde_json::from_str(&body)?;

            if let Some(error) = json.get("error") {
                return Ok(Output {
                    success: false,
                    height_cm: None,
                    last_weight_kg: None,
                    goal_weight_kg: None,
                    error: Some(format!("FatSecret API error: {:?}", error)),
                });
            }

            let profile = &json["profile"];
            Ok(Output {
                success: true,
                height_cm: profile["height_cm"].as_str().map(|s| s.to_string()),
                last_weight_kg: profile["last_weight_kg"].as_str().map(|s| s.to_string()),
                goal_weight_kg: profile["goal_weight_kg"].as_str().map(|s| s.to_string()),
                error: None,
            })
        }
        Err(e) => Ok(Output {
            success: false,
            height_cm: None,
            last_weight_kg: None,
            goal_weight_kg: None,
            error: Some(format!("HTTP error: {}", e)),
        }),
    }
}
