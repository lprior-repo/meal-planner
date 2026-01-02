//! Integration tests for Tandoor Ingredient binaries
//!
//! Tests: tandoor_ingredient_list, tandoor_ingredient_get, tandoor_ingredient_create,
//!        tandoor_ingredient_update, tandoor_ingredient_delete, tandoor_ingredient_from_string

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

mod common;
use common::{get_tandoor_credentials, run_binary, expect_failure};
use serde_json::json;

// =============================================================================
// tandoor_ingredient_list Tests
// =============================================================================

#[test]
fn test_tandoor_ingredient_list_with_auth() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    let result = run_binary("tandoor_ingredient_list", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_ingredient_get Tests
// =============================================================================

#[test]
fn test_tandoor_ingredient_get_missing_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    expect_failure("tandoor_ingredient_get", &input);
}

#[test]
fn test_tandoor_ingredient_get_with_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "id": 1
    });

    let result = run_binary("tandoor_ingredient_get", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_ingredient_create Tests
// =============================================================================

#[test]
fn test_tandoor_ingredient_create_missing_name() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    expect_failure("tandoor_ingredient_create", &input);
}

#[test]
fn test_tandoor_ingredient_create_with_name() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "name": "Test Ingredient"
    });

    let result = run_binary("tandoor_ingredient_create", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_ingredient_update Tests
// =============================================================================

#[test]
fn test_tandoor_ingredient_update_missing_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    expect_failure("tandoor_ingredient_update", &input);
}

#[test]
fn test_tandoor_ingredient_update_with_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "id": 1,
        "name": "Updated Ingredient"
    });

    let result = run_binary("tandoor_ingredient_update", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_ingredient_delete Tests
// =============================================================================

#[test]
fn test_tandoor_ingredient_delete_missing_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    expect_failure("tandoor_ingredient_delete", &input);
}

#[test]
fn test_tandoor_ingredient_delete_with_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "id": 999999999
    });

    let result = run_binary("tandoor_ingredient_delete", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_ingredient_from_string Tests
// =============================================================================

#[test]
fn test_tandoor_ingredient_from_string_missing_string() {
    let input = json!({});
    expect_failure("tandoor_ingredient_from_string", &input);
}

#[test]
fn test_tandoor_ingredient_from_string_with_string() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "string": "200g chicken breast"
    });

    let result = run_binary("tandoor_ingredient_from_string", &input);
    assert!(result.is_ok(), "Binary should execute");
}
