//! Integration tests for FatSecret Diary (Food Entry) binaries
//!
//! Tests: fatsecret_food_entries_get, fatsecret_food_entries_get_month,
//!        fatsecret_food_entry_create, fatsecret_food_entry_edit, fatsecret_food_entry_delete

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use super::common::{get_fatsecret_credentials, run_binary, expect_failure};
use serde_json::json;

// =============================================================================
// fatsecret_food_entries_get Tests
// =============================================================================

#[test]
fn test_fatsecret_food_entries_get_missing_date() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "access_token": "test",
        "access_secret": "test"
    });

    expect_failure("fatsecret_food_entries_get", &input);
}

#[test]
fn test_fatsecret_food_entries_get_with_date() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "date": 20088
    });

    let result = run_binary("fatsecret_food_entries_get", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_food_entries_get_month Tests
// =============================================================================

#[test]
fn test_fatsecret_food_entries_get_month_missing_params() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_food_entries_get_month", &input);
}

#[test]
fn test_fatsecret_food_entries_get_month_with_params() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "year": 2025,
        "month": 1
    });

    let result = run_binary("fatsecret_food_entries_get_month", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_food_entry_create Tests
// =============================================================================

#[test]
fn test_fatsecret_food_entry_create_missing_fields() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "access_token": "test",
        "access_secret": "test"
    });

    expect_failure("fatsecret_food_entry_create", &input);
}

#[test]
fn test_fatsecret_food_entry_create_with_fields() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "food_id": "1633",
        "food_entry_name": "Test Entry",
        "serving_id": "1",
        "number_of_units": 1.0,
        "meal": "lunch",
        "date": 20088
    });

    let result = run_binary("fatsecret_food_entry_create", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_food_entry_edit Tests
// =============================================================================

#[test]
fn test_fatsecret_food_entry_edit_missing_entry_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "access_token": "test",
        "access_secret": "test"
    });

    expect_failure("fatsecret_food_entry_edit", &input);
}

#[test]
fn test_fatsecret_food_entry_edit_with_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "food_entry_id": "1",
        "number_of_units": 2.0
    });

    let result = run_binary("fatsecret_food_entry_edit", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_food_entry_delete Tests
// =============================================================================

#[test]
fn test_fatsecret_food_entry_delete_missing_entry_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_food_entry_delete", &input);
}

#[test]
fn test_fatsecret_food_entry_delete_with_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "food_entry_id": "999999999"
    });

    let result = run_binary("fatsecret_food_entry_delete", &input);
    assert!(result.is_ok(), "Binary should execute");
}
