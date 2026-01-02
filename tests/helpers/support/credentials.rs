//! Test credentials management
//!
//! Credentials are loaded in this order:
//! 1. Environment variables (`FATSECRET_CONSUMER_KEY`, etc.)
//! 2. `pass` password manager (`meal-planner/fatsecret/consumer_key`, etc.)

#![allow(dead_code)]

use serde_json::{json, Value};
use std::env;
use std::process::Command;

// ========================================
// TYPES
// ========================================

#[derive(Clone, Debug)]
#[allow(dead_code)]
pub struct FatSecretCredentials {
    pub consumer_key: String,
    pub consumer_secret: String,
}

#[derive(Clone, Debug)]
#[allow(dead_code)]
pub struct OAuthTokens {
    pub access_token: String,
    pub access_secret: String,
}

#[derive(Clone, Debug)]
#[allow(dead_code)]
pub struct TandoorCredentials {
    pub base_url: String,
    pub api_token: String,
}

// ========================================
// PUBLIC API
// ========================================

#[allow(dead_code)]
pub fn get_fatsecret_credentials() -> Option<FatSecretCredentials> {
    let consumer_key = get_env_or_pass(
        "FATSECRET_CONSUMER_KEY",
        "meal-planner/fatsecret/consumer_key",
    )?;

    let consumer_secret = get_env_or_pass(
        "FATSECRET_CONSUMER_SECRET",
        "meal-planner/fatsecret/consumer_secret",
    )?;

    Some(FatSecretCredentials {
        consumer_key,
        consumer_secret,
    })
}

#[allow(dead_code)]
pub fn get_oauth_tokens() -> Option<OAuthTokens> {
    let access_token = get_env_or_pass(
        "FATSECRET_ACCESS_TOKEN",
        "meal-planner/fatsecret/access_token",
    )?;

    let access_secret = get_env_or_pass(
        "FATSECRET_ACCESS_SECRET",
        "meal-planner/fatsecret/access_secret",
    )?;

    Some(OAuthTokens {
        access_token,
        access_secret,
    })
}

#[allow(dead_code)]
pub fn get_tandoor_credentials() -> Option<TandoorCredentials> {
    let base_url = env::var("TANDOOR_BASE_URL")
        .ok()
        .unwrap_or_else(|| "http://localhost:8090".to_string());

    let api_token = get_env_or_pass("TANDOOR_API_TOKEN", "meal-planner/tandoor/api_token")?;

    Some(TandoorCredentials {
        base_url,
        api_token,
    })
}

#[allow(dead_code)]
pub fn skip_if_no_credentials() {
    if get_fatsecret_credentials().is_none() && get_tandoor_credentials().is_none() {
        println!("Skipping: No credentials available (set env vars or configure pass)");
    }
}

// ========================================
// CORE (Pure Functions)
// ========================================

impl FatSecretCredentials {
    #[allow(dead_code)]
    pub fn to_json(&self) -> Value {
        json!({
            "consumer_key": self.consumer_key,
            "consumer_secret": self.consumer_secret,
        })
    }
}

impl TandoorCredentials {
    #[allow(dead_code)]
    pub fn to_json(&self) -> Value {
        json!({
            "base_url": self.base_url,
            "api_token": self.api_token,
        })
    }
}

// ========================================
// SHELL (I/O Operations)
// ========================================

/// Get value from environment variable or pass
fn get_env_or_pass(env_var: &str, pass_path: &str) -> Option<String> {
    env::var(env_var).ok().or_else(|| get_pass_value(pass_path))
}

/// Get password from pass password manager
fn get_pass_value(path: &str) -> Option<String> {
    let output = Command::new("pass").args(["show", path]).output().ok()?;

    String::from_utf8(output.stdout)
        .ok()?
        .trim()
        .to_string()
        .into()
}
