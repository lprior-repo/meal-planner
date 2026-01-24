//! Integration tests for FatSecret OAuth Flow binaries
//!
//! Tests: fatsecret_oauth_start, fatsecret_oauth_complete
//!
//! These tests verify the OAuth flow functionality with real API calls
//! when credentials are available.

#![allow(clippy::unwrap_used, clippy::indexing_slicing, clippy::panic)]

use super::common::get_fatsecret_credentials;
use super::support::binary_runner::{binary_exists, run_with_exit_code};
use serde_json::json;

#[test]
#[ignore = "integration test - requires real FatSecret API credentials"]
fn test_oauth_start_missing_callback() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_oauth_start") {
        return;
    }

    // Missing callback_url should fail
    let input = json!({
        "fatsecret": credentials.to_json()
    });

    let (output, exit_code) = run_with_exit_code("fatsecret_oauth_start", &input).unwrap();

    // Should fail with non-zero exit code and error message
    assert_ne!(exit_code, 0);
    assert_eq!(output["success"], false);
}

#[test]
#[ignore = "integration test - requires real FatSecret API credentials"]
fn test_oauth_start_valid_callback() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_oauth_start") {
        return;
    }

    // Valid callback URL
    let input = json!({
        "fatsecret": credentials.to_json(),
        "callback_url": "oob"
    });

    let (output, exit_code) = run_with_exit_code("fatsecret_oauth_start", &input).unwrap();

    assert_eq!(
        exit_code, 0,
        "Should succeed with valid credentials and callback"
    );
    assert_eq!(output["success"], true);
    assert!(output["auth_url"].is_string(), "Should return auth URL");
    assert!(
        output["oauth_token"].is_string(),
        "Should return oauth token"
    );
    assert!(
        output["oauth_token_secret"].is_string(),
        "Should return oauth token secret"
    );
}

#[test]
#[ignore = "integration test - requires real FatSecret API credentials"]
fn test_oauth_start_valid_callback_url() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_oauth_start") {
        return;
    }

    // Valid callback URL with proper format
    let input = json!({
        "fatsecret": credentials.to_json(),
        "callback_url": "http://localhost:8765/callback"
    });

    let (output, exit_code) = run_with_exit_code("fatsecret_oauth_start", &input).unwrap();

    assert_eq!(
        exit_code, 0,
        "Should succeed with valid credentials and callback URL"
    );
    assert_eq!(output["success"], true);
    assert!(output["auth_url"].is_string(), "Should return auth URL");
}
