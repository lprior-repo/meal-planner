//! Integration tests for FatSecret Exercise binaries
//!
//! Tests: fatsecret_exercise_get, fatsecret_exercise_month_summary
//!
//! These tests verify the exercise functionality with real API calls
//! when credentials are available.

#![allow(clippy::unwrap_used, clippy::indexing_slicing, clippy::panic)]

use super::common::{get_fatsecret_credentials, get_oauth_tokens};
use super::support::binary_runner::{binary_exists, run_with_exit_code};
use serde_json::json;

#[test]
#[ignore = "integration test - requires real FatSecret API credentials and OAuth tokens"]
fn test_exercise_get_missing_id() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    let Some(tokens) = get_oauth_tokens() else {
        println!("Skipping: FATSECRET_ACCESS_TOKEN/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_exercise_get") {
        return;
    }

    // Missing exercise_id should fail
    let input = json!({
        "fatsecret": credentials.to_json(),
        "access_token": tokens.access_token,
        "access_secret": tokens.access_secret
    });

    let (output, exit_code) = run_with_exit_code("fatsecret_exercise_get", &input).unwrap();

    // Should fail with non-zero exit code and error message
    assert_ne!(exit_code, 0);
    assert_eq!(output["success"], false);
}

#[test]
#[ignore = "integration test - requires real FatSecret API credentials and OAuth tokens"]
fn test_exercise_month_summary_missing_date() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    let Some(tokens) = get_oauth_tokens() else {
        println!("Skipping: FATSECRET_ACCESS_TOKEN/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_exercise_month_summary") {
        return;
    }

    // Missing date_int should fail
    let input = json!({
        "fatsecret": credentials.to_json(),
        "access_token": tokens.access_token,
        "access_secret": tokens.access_secret
    });

    let (output, exit_code) =
        run_with_exit_code("fatsecret_exercise_month_summary", &input).unwrap();

    // Should fail with non-zero exit code and error message
    assert_ne!(exit_code, 0);
    assert_eq!(output["success"], false);
}
