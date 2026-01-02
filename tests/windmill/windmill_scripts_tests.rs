//! Windmill script integration tests
//!
//! These tests verify that Windmill bash scripts exist and are valid
//!
//! Run with: cargo test --test windmill_scripts_tests

#![allow(clippy::unwrap_used, clippy::indexing_slicing, clippy::panic)]

#[test]
fn test_windmill_scripts_exist() {
    let scripts = [
        "windmill/f/fatsecret/food_get.sh",
        "windmill/f/fatsecret/foods_autocomplete.sh",
        "windmill/f/fatsecret/food_find_barcode.sh",
        "windmill/f/fatsecret/food_add_favorite.sh",
        "windmill/f/fatsecret/food_delete_favorite.sh",
        "windmill/f/fatsecret/foods_get_favorites.sh",
        "windmill/f/fatsecret/food_entries_get.sh",
        "windmill/f/fatsecret/food_entries_get_month.sh",
        "windmill/f/fatsecret/food_entry_create.sh",
        "windmill/f/fatsecret/food_entry_edit.sh",
        "windmill/f/fatsecret/food_entry_delete.sh",
    ];

    for script in scripts {
        assert!(
            std::path::Path::new(script).exists(),
            "Windmill script {} does not exist",
            script
        );
    }
}

#[test]
fn test_windmill_yaml_configs_valid() {
    let yamls = [
        "windmill/f/fatsecret/food_get.script.yaml",
        "windmill/f/fatsecret/foods_autocomplete.script.yaml",
        "windmill/f/fatsecret/food_find_barcode.script.yaml",
        "windmill/f/fatsecret/food_add_favorite.script.yaml",
        "windmill/f/fatsecret/food_delete_favorite.script.yaml",
        "windmill/f/fatsecret/foods_get_favorites.script.yaml",
        "windmill/f/fatsecret/food_entries_get.script.yaml",
        "windmill/f/fatsecret/food_entries_get_month.script.yaml",
        "windmill/f/fatsecret/food_entry_create.script.yaml",
        "windmill/f/fatsecret/food_entry_edit.script.yaml",
        "windmill/f/fatsecret/food_entry_delete.script.yaml",
    ];

    for yaml in yamls {
        let read_result = std::fs::read_to_string(yaml);
        assert!(read_result.is_ok(), "Failed to read {yaml}");
        let content = read_result.unwrap();

        assert!(
            content.contains("language:"),
            "{yaml} missing 'language' field"
        );
        assert!(content.contains("kind:"), "{yaml} missing 'kind' field");
        assert!(content.contains("schema:"), "{yaml} missing 'schema' field");
    }
}

#[test]
fn test_windmill_scripts_have_shellcheck() {
    let scripts = [
        "windmill/f/fatsecret/food_get.sh",
        "windmill/f/fatsecret/foods_autocomplete.sh",
        "windmill/f/fatsecret/food_find_barcode.sh",
    ];

    for script in scripts {
        let read_result = std::fs::read_to_string(script);
        assert!(read_result.is_ok(), "Failed to read {script}");
        let content = read_result.unwrap();

        assert!(
            content.contains("# shellcheck shell=bash"),
            "{script} missing shellcheck directive"
        );
    }
}
