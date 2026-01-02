//! Integration tests for Tandoor Meal Type binaries
//!
//! Tests: tandoor_meal_type_list, tandoor_meal_type_get, tandoor_meal_type_create,
//!        tandoor_meal_type_update, tandoor_meal_type_delete

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

mod common;
use common::{get_tandoor_credentials, run_binary, expect_failure};
use serde_json::json;

// =============================================================================
// tandoor_meal_type_list Tests
// =============================================================================

#[test]
fn test_tandoor_meal_type_list_no_auth() {
    let input = json!({
        "tandoor": {"base_url": "http://localhost:8090", "api_token": "invalid"}
    });
    let _ = run_binary("tandoor_meal_type_list", &input);
}

#[test]
fn test_tandoor_meal_type_list_with_auth() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    let result = run_binary("tandoor_meal_type_list", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_meal_type_get Tests
// =============================================================================

#[test]
fn test_tandoor_meal_type_get_missing_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    expect_failure("tandoor_meal_type_get", &input);
}

#[test]
fn test_tandoor_meal_type_get_with_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "id": 1
    });

    let result = run_binary("tandoor_meal_type_get", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_meal_type_create Tests
// =============================================================================

#[test]
fn test_tandoor_meal_type_create_missing_name() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    expect_failure("tandoor_meal_type_create", &input);
}

#[test]
fn test_tandoor_meal_type_create_with_name() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "name": "Test Meal Type"
    });

    let result = run_binary("tandoor_meal_type_create", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_meal_type_update Tests
// =============================================================================

#[test]
fn test_tandoor_meal_type_update_missing_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    expect_failure("tandoor_meal_type_update", &input);
}

#[test]
fn test_tandoor_meal_type_update_with_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "id": 1,
        "name": "Updated Meal Type"
    });

    let result = run_binary("tandoor_meal_type_update", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_meal_type_delete Tests
// =============================================================================

#[test]
fn test_tandoor_meal_type_delete_missing_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    expect_failure("tandoor_meal_type_delete", &input);
}

#[test]
fn test_tandoor_meal_type_delete_with_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "id": 999999999
    });

    let result = run_binary("tandoor_meal_type_delete", &input);
    assert!(result.is_ok(), "Binary should execute");
}
