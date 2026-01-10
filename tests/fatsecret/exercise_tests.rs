//! Integration tests for FatSecret Exercise binaries
//!
//! Tests: fatsecret_exercise_entries_get, fatsecret_exercise_entry_create,
//!        fatsecret_exercise_entry_edit, fatsecret_exercise_entry_delete,
//!        fatsecret_exercise_month_summary, fatsecret_exercise_get

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use super::common::get_fatsecret_credentials;
use super::support::binary_runner::{expect_failure, run_binary};
use serde_json::json;

// =============================================================================
// fatsecret_exercise_entries_get Tests
// =============================================================================

#[test]
fn test_fatsecret_exercise_entries_get_missing_date() {
    // Missing required 'date' field should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test"
    });

    expect_failure("fatsecret_exercise_entries_get", &input);
}

#[test]
#[ignore = "requires real FatSecret API credentials"]
fn test_fatsecret_exercise_entries_get_with_date() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "date": 20088
    });

    let result = run_binary("fatsecret_exercise_entries_get", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_exercise_entry_create Tests
// =============================================================================

#[test]
fn test_fatsecret_exercise_entry_create_missing_fields() {
    // Missing required fields should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test"
    });

    expect_failure("fatsecret_exercise_entry_create", &input);
}

#[test]
#[ignore = "requires real FatSecret API credentials"]
fn test_fatsecret_exercise_entry_create_with_fields() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "exercise_id": "106",
        "number_of_units": 30,
        "date": 20088
    });

    let result = run_binary("fatsecret_exercise_entry_create", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_exercise_entry_edit Tests
// =============================================================================

#[test]
fn test_fatsecret_exercise_entry_edit_missing_entry_id() {
    // Missing required exercise_entry_id should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test"
    });

    expect_failure("fatsecret_exercise_entry_edit", &input);
}

#[test]
#[ignore = "requires real FatSecret API credentials"]
fn test_fatsecret_exercise_entry_edit_with_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "exercise_entry_id": "1",
        "duration_min": 45
    });

    let result = run_binary("fatsecret_exercise_entry_edit", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_exercise_entry_delete Tests
// =============================================================================

#[test]
fn test_fatsecret_exercise_entry_delete_missing_id() {
    // Missing required exercise_entry_id should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test"
    });

    expect_failure("fatsecret_exercise_entry_delete", &input);
}

#[test]
#[ignore = "requires real FatSecret API credentials"]
fn test_fatsecret_exercise_entry_delete_with_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "exercise_entry_id": "999999999"
    });

    let result = run_binary("fatsecret_exercise_entry_delete", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_exercise_month_summary Tests
// =============================================================================

#[test]
fn test_fatsecret_exercise_month_summary_missing_params() {
    // Missing required year/month fields should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test"
    });

    expect_failure("fatsecret_exercise_month_summary", &input);
}

#[test]
#[ignore = "requires real FatSecret API credentials"]
fn test_fatsecret_exercise_month_summary_with_params() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "year": 2025,
        "month": 1
    });

    let result = run_binary("fatsecret_exercise_month_summary", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_exercise_get Tests
// =============================================================================

#[test]
fn test_fatsecret_exercise_get_missing_id() {
    // Missing required exercise_id should fail
    let input = json!({
        "consumer_key": "test",
        "consumer_secret": "test"
    });

    expect_failure("fatsecret_exercise_get", &input);
}

#[test]
#[ignore = "requires real FatSecret API credentials"]
fn test_fatsecret_exercise_get_with_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "exercise_id": "106"
    });

    let result = run_binary("fatsecret_exercise_get", &input);
    assert!(result.is_ok(), "Binary should execute");
}
