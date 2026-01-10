//! Integration tests for FatSecret Saved Meals binaries
//!
//! Tests: fatsecret_saved_meals_get, fatsecret_saved_meals_get_items,
//!        fatsecret_saved_meals_create, fatsecret_saved_meals_edit,
//!        fatsecret_saved_meals_delete

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use super::support::binary_runner::expect_failure;
use serde_json::json;

// =============================================================================
// fatsecret_saved_meals_get Tests
// =============================================================================

#[test]
fn test_fatsecret_saved_meals_get_no_params() {
    // Missing OAuth tokens should fail
    expect_failure("fatsecret_saved_meals_get", &json!({}));
}

// =============================================================================
// fatsecret_saved_meals_get_items Tests
// =============================================================================

#[test]
fn test_fatsecret_saved_meals_get_items_missing_id() {
    // Missing saved_meal_id should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test"
    });
    expect_failure("fatsecret_saved_meals_get_items", &input);
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_saved_meals_get_items_with_id() {
    let input = json!({
        "saved_meal_id": "1",
        "access_token": "real_token",
        "access_secret": "real_secret"
    });

    // Would need real tokens to work
    let _ = input;
}

// =============================================================================
// fatsecret_saved_meals_create Tests
// =============================================================================

#[test]
fn test_fatsecret_saved_meals_create_missing_name() {
    // Missing saved_meal_name should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test"
    });
    expect_failure("fatsecret_saved_meals_create", &input);
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_saved_meals_create_with_name() {
    let input = json!({
        "saved_meal_name": "Test Meal",
        "meal_type": "lunch",
        "access_token": "real_token",
        "access_secret": "real_secret"
    });

    // Would need real tokens to work
    let _ = input;
}

// =============================================================================
// fatsecret_saved_meals_edit Tests
// =============================================================================

#[test]
fn test_fatsecret_saved_meals_edit_missing_id() {
    // Missing saved_meal_id should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test"
    });
    expect_failure("fatsecret_saved_meals_edit", &input);
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_saved_meals_edit_with_id() {
    let input = json!({
        "saved_meal_id": "1",
        "saved_meal_name": "Updated Meal",
        "access_token": "real_token",
        "access_secret": "real_secret"
    });

    // Would need real tokens to work
    let _ = input;
}

// =============================================================================
// fatsecret_saved_meals_delete Tests
// =============================================================================

#[test]
fn test_fatsecret_saved_meals_delete_missing_id() {
    // Missing saved_meal_id should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test"
    });
    expect_failure("fatsecret_saved_meals_delete", &input);
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_saved_meals_delete_with_id() {
    let input = json!({
        "saved_meal_id": "1",
        "access_token": "real_token",
        "access_secret": "real_secret"
    });

    // Would need real tokens to work
    let _ = input;
}
