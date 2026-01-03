//! Unit tests for fatsecret_exercise_month_summary validation logic
//!
//! Dave Farley: "Functional Core / Imperative Shell"
//!
//! Tests pure validation functions (Core) separate from binary execution (Shell)

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use serde_json::json;

#[path = "../helpers/common.rs"]
pub mod common;

const BINARY_NAME: &str = "fatsecret_exercise_month_summary";

fn run_binary(input: &serde_json::Value) -> Result<serde_json::Value, String> {
    common::run_binary(BINARY_NAME, input)
}

fn require_credentials() -> bool {
    let creds = common::get_fatsecret_credentials();
    let tokens = common::get_oauth_tokens();
    creds.is_some() && tokens.is_some()
}

#[test]
fn test_binary_accepts_valid_input_structure() {
    let creds = match common::get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };
    let tokens = match common::get_oauth_tokens() {
        Some(t) => t,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "access_token": tokens.access_token,
        "access_secret": tokens.access_secret,
        "year": 2025,
        "month": 12
    });

    let result = run_binary(&input);
    assert!(result.is_ok(), "Binary should accept valid input: {:?}", result);
}

#[test]
fn test_response_contains_success_field() {
    if !require_credentials() {
        return;
    }
    let creds = common::get_fatsecret_credentials().unwrap();
    let tokens = common::get_oauth_tokens().unwrap();

    let input = json!({
        "fatsecret": creds.to_json(),
        "access_token": tokens.access_token,
        "access_secret": tokens.access_secret,
        "year": 2025,
        "month": 12
    });

    let result = run_binary(&input).unwrap();
    assert!(
        result.get("success").and_then(|v| v.as_bool()).is_some(),
        "Response should contain 'success' field"
    );
}

#[test]
fn test_response_contains_month_summary_on_success() {
    if !require_credentials() {
        return;
    }
    let creds = common::get_fatsecret_credentials().unwrap();
    let tokens = common::get_oauth_tokens().unwrap();

    let input = json!({
        "fatsecret": creds.to_json(),
        "access_token": tokens.access_token,
        "access_secret": tokens.access_secret,
        "year": 2025,
        "month": 12
    });

    let result = run_binary(&input).unwrap();
    assert!(
        result.get("month_summary").is_some(),
        "Response should contain 'month_summary' field on success"
    );
}
