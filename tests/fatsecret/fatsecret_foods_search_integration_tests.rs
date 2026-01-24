//! Integration tests for FatSecret Foods Search binary
//!
//! Tests: fatsecret_foods_search
//!
//! These tests verify the foods search functionality with real API calls
//! when credentials are available.

#![allow(clippy::unwrap_used, clippy::indexing_slicing, clippy::panic)]

use super::common::get_fatsecret_credentials;
use super::support::binary_runner::{binary_exists, run_with_exit_code};
use serde_json::json;

/// Test that foods search fails when query is missing
#[test]
#[ignore = "integration test - requires real FatSecret API credentials"]
fn test_foods_search_missing_query() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_foods_search") {
        return;
    }

    // Missing required query should fail
    let input = json!({
        "fatsecret": credentials.to_json(),
        "page": 0,
        "max_results": 5
    });

    let (output, exit_code) = run_with_exit_code("fatsecret_foods_search", &input).unwrap();

    // Should fail with non-zero exit code and error message
    assert_ne!(exit_code, 0);
    assert_eq!(output["success"], false);
}

/// Test that foods search works with valid query
#[test]
#[ignore = "integration test - requires real FatSecret API credentials"]
fn test_foods_search_with_valid_query() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_foods_search") {
        return;
    }

    // Valid search with a common term
    let input = json!({
        "fatsecret": credentials.to_json(),
        "query": "chicken breast",
        "page": 0,
        "max_results": 5
    });

    let (output, exit_code) = run_with_exit_code("fatsecret_foods_search", &input).unwrap();

    assert_eq!(
        exit_code, 0,
        "Should succeed with valid credentials and query"
    );
    assert_eq!(output["success"], true);
    assert!(output["foods"].is_object(), "Should return foods object");
}

/// Test that foods search handles empty results gracefully
#[test]
#[ignore = "integration test - requires real FatSecret API credentials"]
fn test_foods_search_empty_results() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_foods_search") {
        return;
    }

    // Search for something that definitely doesn't exist
    let input = json!({
        "fatsecret": credentials.to_json(),
        "query": "thisisafakenameforatestthatshouldnotexist12345",
        "page": 0,
        "max_results": 5
    });

    let (output, exit_code) = run_with_exit_code("fatsecret_foods_search", &input).unwrap();

    assert_eq!(exit_code, 0, "Should succeed even with no results");
    assert_eq!(output["success"], true);
    // Empty results are valid - the API should return an empty foods object
    assert!(
        output["foods"].is_object(),
        "Should return foods object even when empty"
    );
}
