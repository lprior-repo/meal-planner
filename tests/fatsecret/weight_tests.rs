//! Integration tests for FatSecret Weight binaries
//!
//! Tests: fatsecret_weight_update, fatsecret_weight_month_summary

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

mod common;
use common::{get_fatsecret_credentials, run_binary, expect_failure};
use serde_json::json;

// =============================================================================
// fatsecret_weight_update Tests
// =============================================================================

#[test]
fn test_fatsecret_weight_update_missing_weight() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_weight_update", &input);
}

#[test]
fn test_fatsecret_weight_update_with_weight() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "weight_kg": 75.5,
        "date_int": 20088
    });

    let result = run_binary("fatsecret_weight_update", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_weight_month_summary Tests
// =============================================================================

#[test]
fn test_fatsecret_weight_month_summary_missing_params() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_weight_month_summary", &input);
}

#[test]
fn test_fatsecret_weight_month_summary_with_params() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "year": 2025,
        "month": 1
    });

    let result = run_binary("fatsecret_weight_month_summary", &input);
    assert!(result.is_ok(), "Binary should execute");
}
