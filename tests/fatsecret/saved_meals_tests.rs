//! Integration tests for FatSecret Saved Meals binaries
//!
//! Tests: fatsecret_saved_meals_get, fatsecret_saved_meals_get_items,
//!        fatsecret_saved_meals_create, fatsecret_saved_meals_edit,
//!        fatsecret_saved_meals_delete

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use super::common::{run_binary, expect_failure};
use serde_json::json;

// =============================================================================
// fatsecret_saved_meals_get Tests
// =============================================================================

#[test]
fn test_fatsecret_saved_meals_get_no_params() {
    let result = run_binary("fatsecret_saved_meals_get", &json!({}));
    assert!(result.is_ok(), "Binary should execute without params");
}

// =============================================================================
// fatsecret_saved_meals_get_items Tests
// =============================================================================

#[test]
fn test_fatsecret_saved_meals_get_items_missing_id() {
    let input = json!({});
    expect_failure("fatsecret_saved_meals_get_items", &input);
}

#[test]
fn test_fatsecret_saved_meals_get_items_with_id() {
    let input = json!({
        "saved_meal_id": "1"
    });

    let result = run_binary("fatsecret_saved_meals_get_items", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_saved_meals_create Tests
// =============================================================================

#[test]
fn test_fatsecret_saved_meals_create_missing_name() {
    let input = json!({});
    expect_failure("fatsecret_saved_meals_create", &input);
}

#[test]
fn test_fatsecret_saved_meals_create_with_name() {
    let input = json!({
        "saved_meal_name": "Test Meal",
        "meal_type": "lunch"
    });

    let result = run_binary("fatsecret_saved_meals_create", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_saved_meals_edit Tests
// =============================================================================

#[test]
fn test_fatsecret_saved_meals_edit_missing_id() {
    let input = json!({});
    expect_failure("fatsecret_saved_meals_edit", &input);
}

#[test]
fn test_fatsecret_saved_meals_edit_with_id() {
    let input = json!({
        "saved_meal_id": "1",
        "saved_meal_name": "Updated Meal"
    });

    let result = run_binary("fatsecret_saved_meals_edit", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// fatsecret_saved_meals_delete Tests
// =============================================================================

#[test]
fn test_fatsecret_saved_meals_delete_missing_id() {
    let input = json!({});
    expect_failure("fatsecret_saved_meals_delete", &input);
}

#[test]
fn test_fatsecret_saved_meals_delete_with_id() {
    let input = json!({
        "saved_meal_id": "1"
    });

    let result = run_binary("fatsecret_saved_meals_delete", &input);
    assert!(result.is_ok(), "Binary should execute");
}
