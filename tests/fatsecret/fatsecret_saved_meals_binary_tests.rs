//! Integration tests for FatSecret Saved Meals binaries
//!
//! Tests: fatsecret_saved_meals_get, fatsecret_saved_meals_get_items,
//!        fatsecret_saved_meals_create, fatsecret_saved_meals_edit,
//!        fatsecret_saved_meals_delete

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use serde_json::json;

use crate::fatsecret::common::expect_failure;

#[test]
fn test_fatsecret_saved_meals_get_no_params() {
    // Missing OAuth tokens should fail
    expect_failure("fatsecret_saved_meals_get", &json!({}));
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_saved_meals_get_with_credentials() {
    // Requires real OAuth tokens
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_saved_meals_get_response_format() {
    // Requires real OAuth tokens
}

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
    // Requires real OAuth tokens
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_saved_meals_get_items_response_format() {
    // Requires real OAuth tokens
}

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
    // Requires real OAuth tokens
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_saved_meals_create_response_format() {
    // Requires real OAuth tokens
}

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
    // Requires real OAuth tokens
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_saved_meals_edit_response_format() {
    // Requires real OAuth tokens
}

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
    // Requires real OAuth tokens
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_saved_meals_delete_response_format() {
    // Requires real OAuth tokens
}
