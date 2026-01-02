//! Integration tests for FatSecret OAuth and Profile binaries
//!
//! Tests: fatsecret_oauth_start, fatsecret_oauth_complete, fatsecret_oauth_callback,
//!        fatsecret_get_token, fatsecret_get_profile, fatsecret_foods_most_eaten,
//!        fatsecret_foods_recently_eaten

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

mod common;
use common::{get_fatsecret_credentials, run_binary, expect_failure};
use serde_json::json;

// =============================================================================
// fatsecret_get_profile Tests
// =============================================================================

#[test]
fn test_fatsecret_get_profile_no_params() {
    let result = run_binary("fatsecret_get_profile", &json!({}));
    assert!(result.is_ok(), "Binary should execute without params");
}

// =============================================================================
// fatsecret_foods_most_eaten Tests
// =============================================================================

#[test]
fn test_fatsecret_foods_most_eaten_no_params() {
    let result = run_binary("fatsecret_foods_most_eaten", &json!({}));
    assert!(result.is_ok(), "Binary should execute without params");
}

#[test]
fn test_fatsecret_foods_most_eaten_with_pagination() {
    let input = json!({
        "page_number": 1,
        "max_results": 5
    });

    let result = run_binary("fatsecret_foods_most_eaten", &input);
    assert!(result.is_ok(), "Binary should execute with pagination");
}

// =============================================================================
// fatsecret_foods_recently_eaten Tests
// =============================================================================

#[test]
fn test_fatsecret_foods_recently_eaten_no_params() {
    let result = run_binary("fatsecret_foods_recently_eaten", &json!({}));
    assert!(result.is_ok(), "Binary should execute without params");
}

#[test]
fn test_fatsecret_foods_recently_eaten_with_pagination() {
    let input = json!({
        "page_number": 1,
        "max_results": 5
    });

    let result = run_binary("fatsecret_foods_recently_eaten", &input);
    assert!(result.is_ok(), "Binary should execute with pagination");
}

// =============================================================================
// fatsecret_get_token Tests
// =============================================================================

#[test]
fn test_fatsecret_get_token_missing_request_token() {
    let input = json!({});
    expect_failure("fatsecret_get_token", &input);
}

#[test]
fn test_fatsecret_get_token_with_request_token() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "request_token": "test_token",
        "request_token_secret": "test_secret",
        "verifier": "test_verifier"
    });

    let result = run_binary("fatsecret_get_token", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_oauth_start Tests
// =============================================================================

#[test]
fn test_fatsecret_oauth_start_missing_credentials() {
    let input = json!({});
    expect_failure("fatsecret_oauth_start", &input);
}

#[test]
fn test_fatsecret_oauth_start_with_credentials() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "callback_url": "oob"
    });

    let result = run_binary("fatsecret_oauth_start", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_oauth_complete Tests
// =============================================================================

#[test]
fn test_fatsecret_oauth_complete_missing_auth() {
    let input = json!({});
    expect_failure("fatsecret_oauth_complete", &input);
}

#[test]
fn test_fatsecret_oauth_complete_with_auth() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "auth_key": "test_key"
    });

    let result = run_binary("fatsecret_oauth_complete", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_oauth_callback Tests
// =============================================================================

#[test]
fn test_fatsecret_oauth_callback_missing_params() {
    let input = json!({});
    expect_failure("fatsecret_oauth_callback", &input);
}

#[test]
fn test_fatsecret_oauth_callback_with_params() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "oauth_token": "test_token",
        "oauth_verifier": "test_verifier"
    });

    let result = run_binary("fatsecret_oauth_callback", &input);
    assert!(result.is_ok(), "Binary should execute");
}
