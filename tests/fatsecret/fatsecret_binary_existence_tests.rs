//! Binary existence tests for FatSecret CLI binaries
//!
//! These tests verify that each binary exists and is executable
//!
//! Run with: cargo test --test fatsecret_binary_existence_tests

#![allow(clippy::unwrap_used, clippy::indexing_slicing, clippy::panic)]

use super::common::binary_exists;

#[test]
fn test_all_binaries_exist() {
    let binaries = [
        "fatsecret_food_get",
        "fatsecret_foods_autocomplete",
        "fatsecret_food_add_favorite",
        "fatsecret_food_delete_favorite",
        "fatsecret_foods_get_favorites",
        "fatsecret_food_entries_get",
        "fatsecret_food_entries_get_month",
        "fatsecret_food_entry_create",
        "fatsecret_food_entry_edit",
        "fatsecret_food_entry_delete",
        "fatsecret_exercise_entries_get",
        "fatsecret_exercise_entry_create",
        "fatsecret_exercise_entry_edit",
        "fatsecret_exercise_entry_delete",
        "fatsecret_exercise_month_summary",
    ];

    for binary in binaries {
        assert!(
            binary_exists(binary),
            "Binary {} does not exist in bin/",
            binary
        );
    }
}
