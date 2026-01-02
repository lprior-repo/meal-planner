//! Integration tests for FatSecret Food binaries
//!
//! Tests: fatsecret_food_get, fatsecret_foods_search, fatsecret_foods_autocomplete,
//!        fatsecret_food_find_barcode, fatsecret_foods_get_favorites, fatsecret_food_add_favorite,
//!        fatsecret_food_delete_favorite

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use super::common::{get_fatsecret_credentials, run_binary, expect_failure};
use serde_json::json;

// =============================================================================
// fatsecret_food_get Tests
// =============================================================================

#[test]
fn test_fatsecret_food_get_missing_id() {
    let input = json!({});
    expect_failure("fatsecret_food_get", &input);
}

#[test]
fn test_fatsecret_food_get_with_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "food_id": "1633"
    });

    let result = run_binary("fatsecret_food_get", &input);
    assert!(result.is_ok(), "Binary should execute without panicking");
}

// =============================================================================
// fatsecret_foods_search Tests
// =============================================================================

#[test]
fn test_fatsecret_foods_search_empty_query() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "query": "xyz123nonexistentfood987"
    });

    let result = run_binary("fatsecret_foods_search", &input);
    assert!(result.is_ok(), "Binary should handle empty results");
}

#[test]
fn test_fatsecret_foods_search_with_results() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "query": "chicken",
        "page": 0,
        "max_results": 5
    });

    let result = run_binary("fatsecret_foods_search", &input);
    assert!(result.is_ok(), "Binary should execute");
    let value = result.unwrap();
    assert!(value["foods"].is_object() || value.get("success") == Some(&json!(false)));
}

// =============================================================================
// fatsecret_foods_autocomplete Tests
// =============================================================================

#[test]
fn test_fatsecret_foods_autocomplete_empty_expression() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_foods_autocomplete", &input);
}

#[test]
fn test_fatsecret_foods_autocomplete_with_expression() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "expression": "chick"
    });

    let result = run_binary("fatsecret_foods_autocomplete", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_food_find_barcode Tests
// =============================================================================

#[test]
fn test_fatsecret_food_find_barcode_missing_barcode() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_food_find_barcode", &input);
}

#[test]
fn test_fatsecret_food_find_barcode_with_barcode() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "barcode": "5000112637922"
    });

    let result = run_binary("fatsecret_food_find_barcode", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_foods_get_favorites Tests
// =============================================================================

#[test]
fn test_fatsecret_foods_get_favorites_requires_auth() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_foods_get_favorites", &input);
}

#[test]
fn test_fatsecret_foods_get_favorites_with_auth() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "access_token": "test_token",
        "access_secret": "test_secret"
    });

    let result = run_binary("fatsecret_foods_get_favorites", &input);
    assert!(result.is_ok(), "Binary should execute with tokens");
}

// =============================================================================
// fatsecret_food_add_favorite Tests
// =============================================================================

#[test]
fn test_fatsecret_food_add_favorite_missing_fields() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_food_add_favorite", &input);
}

#[test]
fn test_fatsecret_food_add_favorite_with_food_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "food_id": "1633"
    });

    let result = run_binary("fatsecret_food_add_favorite", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_food_delete_favorite Tests
// =============================================================================

#[test]
fn test_fatsecret_food_delete_favorite_missing_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_food_delete_favorite", &input);
}

#[test]
fn test_fatsecret_food_delete_favorite_with_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "food_id": "1633"
    });

    let result = run_binary("fatsecret_food_delete_favorite", &input);
    assert!(result.is_ok(), "Binary should execute");
}
