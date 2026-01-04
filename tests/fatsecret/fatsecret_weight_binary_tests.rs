//! Integration tests for FatSecret Weight binaries
//!
//! Tests: fatsecret_weight_update, fatsecret_weight_month_summary

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use serde_json::json;

use crate::fatsecret::common::expect_failure;

#[test]
fn test_fatsecret_weight_update_missing_weight() {
    // Missing required weight_kg should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test"
    });

    expect_failure("fatsecret_weight_update", &input);
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_weight_update_with_weight() {
    // Requires real OAuth tokens
}

#[test]
fn test_fatsecret_weight_update_missing_date() {
    // Missing required date should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test",
        "weight_kg": 75.5
    });

    expect_failure("fatsecret_weight_update", &input);
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_weight_update_invalid_weight() {
    // Requires real OAuth tokens
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_weight_update_response_format() {
    // Requires real OAuth tokens
}

#[test]
fn test_fatsecret_weight_month_summary_missing_params() {
    // Missing required year/month should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test"
    });

    expect_failure("fatsecret_weight_month_summary", &input);
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_weight_month_summary_with_params() {
    // Requires real OAuth tokens
}

#[test]
fn test_fatsecret_weight_month_summary_missing_year() {
    // Missing required year should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test",
        "month": 1
    });

    expect_failure("fatsecret_weight_month_summary", &input);
}

#[test]
fn test_fatsecret_weight_month_summary_missing_month() {
    // Missing required month should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test",
        "year": 2025
    });

    expect_failure("fatsecret_weight_month_summary", &input);
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_weight_month_summary_response_format() {
    // Requires real OAuth tokens
}
