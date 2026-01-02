//! Integration tests for FatSecret Recipe binaries
//!
//! Tests: fatsecret_recipes_search, fatsecret_recipe_get, fatsecret_recipes_autocomplete,
//!        fatsecret_recipes_get_favorites, fatsecret_recipe_add_favorite,
//!        fatsecret_recipe_delete_favorite, fatsecret_recipe_types_get

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use super::common::{get_fatsecret_credentials, run_binary, expect_failure};
use serde_json::json;

// =============================================================================
// fatsecret_recipes_search Tests
// =============================================================================

#[test]
fn test_fatsecret_recipes_search_missing_expression() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_recipes_search", &input);
}

#[test]
fn test_fatsecret_recipes_search_with_expression() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "search_expression": "pasta",
        "page_number": 1
    });

    let result = run_binary("fatsecret_recipes_search", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_recipe_get Tests
// =============================================================================

#[test]
fn test_fatsecret_recipe_get_missing_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_recipe_get", &input);
}

#[test]
fn test_fatsecret_recipe_get_with_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "recipe_id": "1"
    });

    let result = run_binary("fatsecret_recipe_get", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_recipes_autocomplete Tests
// =============================================================================

#[test]
fn test_fatsecret_recipes_autocomplete_missing_expression() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_recipes_autocomplete", &input);
}

#[test]
fn test_fatsecret_recipes_autocomplete_with_expression() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "expression": "chick"
    });

    let result = run_binary("fatsecret_recipes_autocomplete", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_recipes_get_favorites Tests
// =============================================================================

#[test]
fn test_fatsecret_recipes_get_favorites_no_auth() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_recipes_get_favorites", &input);
}

#[test]
fn test_fatsecret_recipes_get_favorites_with_auth() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "access_token": "test",
        "access_secret": "test"
    });

    let result = run_binary("fatsecret_recipes_get_favorites", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_recipe_add_favorite Tests
// =============================================================================

#[test]
fn test_fatsecret_recipe_add_favorite_missing_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_recipe_add_favorite", &input);
}

#[test]
fn test_fatsecret_recipe_add_favorite_with_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "recipe_id": "1"
    });

    let result = run_binary("fatsecret_recipe_add_favorite", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_recipe_delete_favorite Tests
// =============================================================================

#[test]
fn test_fatsecret_recipe_delete_favorite_missing_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json()
    });

    expect_failure("fatsecret_recipe_delete_favorite", &input);
}

#[test]
fn test_fatsecret_recipe_delete_favorite_with_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "fatsecret": creds.to_json(),
        "recipe_id": "1"
    });

    let result = run_binary("fatsecret_recipe_delete_favorite", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_recipe_types_get Tests
// =============================================================================

#[test]
fn test_fatsecret_recipe_types_get_no_params() {
    let input = json!({});
    let result = run_binary("fatsecret_recipe_types_get", &input);
    assert!(result.is_ok(), "Binary should execute without params");
}
