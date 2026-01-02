//! Integration tests for FatSecret Exercise binaries
//!
//! Tests: fatsecret_exercise_entries_get, fatsecret_exercise_entry_create,
//!        fatsecret_exercise_entry_edit, fatsecret_exercise_entry_delete,
//!        fatsecret_exercise_month_summary, fatsecret_exercise_get

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

mod common;
use common::{get_fatsecret_credentials, run_binary, expect_failure};
use serde_json::json;

// =============================================================================
// fatsecret_exercise_entries_get Tests
// =============================================================================

#[test]
fn test_fatsecret_exercise_entries_get_missing_date() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_exercise_entries_get", &input);
}

#[test]
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
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_exercise_entry_create", &input);
}

#[test]
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
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_exercise_entry_edit", &input);
}

#[test]
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
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_exercise_entry_delete", &input);
}

#[test]
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
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_exercise_month_summary", &input);
}

#[test]
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
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_exercise_get", &input);
}

#[test]
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
