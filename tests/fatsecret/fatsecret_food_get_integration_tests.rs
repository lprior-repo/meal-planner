//! Integration tests for FatSecret Food Get binary
//!
//! Tests: fatsecret_food_get
//!
//! These tests verify the food get functionality with real API calls
//! when credentials are available.

#![allow(clippy::unwrap_used, clippy::indexing_slicing, clippy::panic)]

use super::common::get_fatsecret_credentials;
use super::support::binary_runner::{binary_exists, run_with_exit_code};
use serde_json::json;

#[test]
#[ignore = "integration test - requires real FatSecret API credentials"]
fn test_food_get_missing_id() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_food_get") {
        return;
    }

    // Missing required food_id should fail
    let input = json!({
        "fatsecret": credentials.to_json()
    });

    let (output, exit_code) = run_with_exit_code("fatsecret_food_get", &input).unwrap();

    // Should fail with non-zero exit code and error message
    assert_ne!(exit_code, 0);
    assert_eq!(output["success"], false);
}

#[test]
#[ignore = "integration test - requires real FatSecret API credentials"]
fn test_food_get_valid_id() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_food_get") {
        return;
    }

    // Valid food ID (using a known test food ID)
    let input = json!({
        "fatsecret": credentials.to_json(),
        "food_id": "35718"
    });

    let (output, exit_code) = run_with_exit_code("fatsecret_food_get", &input).unwrap();

    assert_eq!(
        exit_code, 0,
        "Should succeed with valid credentials and food ID"
    );
    assert_eq!(output["success"], true);
    assert!(output["food"].is_object(), "Should return food object");
}

#[test]
#[ignore = "integration test - requires real FatSecret API credentials"]
fn test_food_get_invalid_id() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_food_get") {
        return;
    }

    // Invalid food ID should fail gracefully
    let input = json!({
        "fatsecret": credentials.to_json(),
        "food_id": "999999999"
    });

    let (output, exit_code) = run_with_exit_code("fatsecret_food_get", &input).unwrap();

    // Should return failure but not crash
    assert_eq!(output["success"], false);
}
