//! Integration tests for FatSecret Recipe Favorites binaries
//!
//! Tests: fatsecret_recipes_get_favorites, fatsecret_recipe_add_favorite,
//!        fatsecret_recipe_delete_favorite

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use serde_json::json;

use crate::fatsecret::support::binary_runner::expect_failure;

#[test]
fn test_fatsecret_recipes_get_favorites_no_auth() {
    // Missing OAuth tokens should fail
    let input = json!({
        "consumer_key": "test",
        "consumer_secret": "test"
    });

    expect_failure("fatsecret_recipes_get_favorites", &input);
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_recipes_get_favorites_with_auth() {
    // Requires real OAuth tokens
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_recipes_get_favorites_response_format() {
    // Requires real OAuth tokens
}

#[test]
fn test_fatsecret_recipe_add_favorite_missing_id() {
    // Missing recipe_id should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test"
    });

    expect_failure("fatsecret_recipe_add_favorite", &input);
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_recipe_add_favorite_with_id() {
    // Requires real OAuth tokens
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_recipe_add_favorite_response_format() {
    // Requires real OAuth tokens
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_recipe_add_favorite_invalid_id() {
    // Requires real OAuth tokens
}

#[test]
fn test_fatsecret_recipe_delete_favorite_missing_id() {
    // Missing recipe_id should fail
    let input = json!({
        "access_token": "test",
        "access_secret": "test"
    });

    expect_failure("fatsecret_recipe_delete_favorite", &input);
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_recipe_delete_favorite_with_id() {
    // Requires real OAuth tokens
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_recipe_delete_favorite_response_format() {
    // Requires real OAuth tokens
}

#[test]
#[ignore = "integration test - requires real FatSecret OAuth tokens"]
fn test_fatsecret_recipe_delete_favorite_nonexistent_id() {
    // Requires real OAuth tokens
}
