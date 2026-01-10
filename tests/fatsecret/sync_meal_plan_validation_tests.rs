//! Test validation for sync_meal_plan binary
//!
//! BEAD-001: meal_type validation
//! BEAD-004: numeric bounds validation
//! BEAD-006: empty string validation
//!
//! These tests verify that invalid values are properly rejected
//! with actionable error messages instead of being silently accepted.

#![allow(clippy::unwrap_used, clippy::indexing_slicing, clippy::panic)]

use super::support::binary_runner::binary_exists;
use serde_json::{json, Value};
use std::io::Write;
use std::process::{Command, Stdio};

// Valid-looking credentials (16+ chars) to pass initial validation
const TEST_CONSUMER_KEY: &str = "test_consumer_key_16_chars_min";
const TEST_CONSUMER_SECRET: &str = "test_consumer_secret_16_chars";

/// Helper to run sync_meal_plan and always get JSON output (even on error)
fn run_sync_meal_plan(input: &Value) -> Value {
    let binary_path = if std::path::Path::new("./target/debug/sync_meal_plan").exists() {
        "./target/debug/sync_meal_plan"
    } else if std::path::Path::new("./bin/sync_meal_plan").exists() {
        "./bin/sync_meal_plan"
    } else {
        panic!("sync_meal_plan binary not found");
    };

    let mut child = Command::new(binary_path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("Failed to spawn binary");

    if let Some(ref mut stdin) = child.stdin {
        let json_str = input.to_string();
        stdin
            .write_all(json_str.as_bytes())
            .expect("Failed to write to stdin");
    }

    let output = child.wait_with_output().expect("Failed to wait for child");
    let stdout = String::from_utf8_lossy(&output.stdout);

    serde_json::from_str(&stdout).expect(&format!(
        "Failed to parse JSON output. stdout: {}\nstderr: {}",
        stdout,
        String::from_utf8_lossy(&output.stderr)
    ))
}

#[test]
fn test_valid_meal_types_accepted() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let valid_meal_types = ["breakfast", "lunch", "dinner", "snack"];

    for meal_type in &valid_meal_types {
        let input = json!({
            "fatsecret": {
                "consumer_key": TEST_CONSUMER_KEY,
                "consumer_secret": TEST_CONSUMER_SECRET
            },
            "access_token": "test_token",
            "access_secret": "test_secret",
            "entries": [
                {
                    "date": "2025-01-01",
                    "meal_type": meal_type,
                    "recipe_name": "Test Recipe",
                    "servings": 1.0,
                    "calories": 300.0,
                    "protein": 10.0,
                    "carbohydrate": 50.0,
                    "fat": 5.0
                }
            ]
        });

        let output = run_sync_meal_plan(&input);

        // Valid meal_types should not produce validation errors
        let errors = output["errors"].as_array().expect("Should have errors array");
        let has_validation_error = errors.iter().any(|e| {
            e.as_str()
                .map(|s| s.contains("Invalid meal_type"))
                .unwrap_or(false)
        });

        assert!(
            !has_validation_error,
            "Valid meal_type '{}' should not produce validation error. Errors: {:?}",
            meal_type,
            errors
        );
    }
}

#[test]
fn test_valid_meal_types_case_insensitive() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let case_variations = ["BREAKFAST", "Lunch", "DiNnEr", "SNACK"];

    for meal_type in &case_variations {
        let input = json!({
            "fatsecret": {
                "consumer_key": TEST_CONSUMER_KEY,
                "consumer_secret": TEST_CONSUMER_SECRET
            },
            "access_token": "test_token",
            "access_secret": "test_secret",
            "entries": [
                {
                    "date": "2025-01-01",
                    "meal_type": meal_type,
                    "recipe_name": "Test Recipe",
                    "servings": 1.0,
                    "calories": 300.0,
                    "protein": 10.0,
                    "carbohydrate": 50.0,
                    "fat": 5.0
                }
            ]
        });

        let output = run_sync_meal_plan(&input);

        let errors = output["errors"].as_array().expect("Should have errors array");
        let has_validation_error = errors.iter().any(|e| {
            e.as_str()
                .map(|s| s.contains("Invalid meal_type"))
                .unwrap_or(false)
        });

        assert!(
            !has_validation_error,
            "Case variation '{}' should not produce validation error. Errors: {:?}",
            meal_type,
            errors
        );
    }
}

#[test]
fn test_invalid_meal_type_typo_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "breakfest",  // Common typo
                "recipe_name": "Test Recipe",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    // Should return success: false
    assert_eq!(
        output["success"], false,
        "Invalid meal_type should result in success: false"
    );

    // Should have error in errors array
    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(
        !errors.is_empty(),
        "Should have at least one error for invalid meal_type"
    );

    // Error message should mention the invalid meal_type
    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("Invalid meal_type"),
        "Error should mention 'Invalid meal_type', got: {}",
        error_msg
    );
    assert!(
        error_msg.contains("breakfest"),
        "Error should mention the invalid value 'breakfest', got: {}",
        error_msg
    );

    // Error should be actionable (list valid options)
    assert!(
        error_msg.contains("breakfast") || error_msg.contains("lunch") || error_msg.contains("dinner") || error_msg.contains("snack"),
        "Error should list valid meal types, got: {}",
        error_msg
    );

    // Entry should not be synced
    assert_eq!(
        output["entries_synced"], 0,
        "Invalid entry should not be synced"
    );
    assert_eq!(
        output["entries_failed"], 1,
        "Invalid entry should be counted as failed"
    );
}

#[test]
fn test_invalid_meal_type_empty_string_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "",  // Empty string
                "recipe_name": "Test Recipe",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    assert_eq!(output["success"], false);

    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(!errors.is_empty());

    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(error_msg.contains("Invalid meal_type"));
}

#[test]
fn test_invalid_meal_type_custom_value_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "afternoon_snack",  // Not a valid FatSecret meal type
                "recipe_name": "Test Recipe",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    assert_eq!(output["success"], false);

    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(!errors.is_empty());

    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("Invalid meal_type") && error_msg.contains("afternoon_snack"),
        "Error should mention invalid value, got: {}",
        error_msg
    );
}

#[test]
fn test_mixed_valid_and_invalid_meal_types() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "breakfast",  // Valid
                "recipe_name": "Oatmeal",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            },
            {
                "date": "2025-01-01",
                "meal_type": "invalid_type",  // Invalid
                "recipe_name": "Bad Entry",
                "servings": 1.0,
                "calories": 200.0,
                "protein": 5.0,
                "carbohydrate": 30.0,
                "fat": 3.0
            },
            {
                "date": "2025-01-01",
                "meal_type": "lunch",  // Valid
                "recipe_name": "Sandwich",
                "servings": 1.0,
                "calories": 400.0,
                "protein": 15.0,
                "carbohydrate": 40.0,
                "fat": 10.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    // Should return success: false because there are errors
    assert_eq!(
        output["success"], false,
        "Should return success: false when any entry has errors"
    );

    // Should have at least 1 error for the invalid meal_type
    let errors = output["errors"].as_array().expect("Should have errors array");
    let validation_errors: Vec<_> = errors
        .iter()
        .filter(|e| {
            e.as_str()
                .map(|s| s.contains("Invalid meal_type"))
                .unwrap_or(false)
        })
        .collect();

    assert_eq!(
        validation_errors.len(),
        1,
        "Should have exactly 1 validation error for invalid meal_type. Got: {:?}",
        errors
    );

    let error_msg = validation_errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("invalid_type"),
        "Error should mention the invalid value, got: {}",
        error_msg
    );

    // entries_failed should be at least 1 (the invalid one)
    // Note: The valid entries may also fail due to invalid credentials
    assert!(
        output["entries_failed"].as_u64().unwrap() >= 1,
        "Should have at least 1 failed entry"
    );
}

#[test]
fn test_error_message_format() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "elevenses",
                "recipe_name": "Test Recipe",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    let errors = output["errors"].as_array().expect("Should have errors array");
    let error_msg = errors[0].as_str().expect("Error should be a string");

    // The exact format specified in the requirements:
    // "Invalid meal_type X: must be breakfast, lunch, dinner, or snack"
    assert!(
        error_msg.starts_with("Invalid meal_type"),
        "Error should start with 'Invalid meal_type', got: {}",
        error_msg
    );
    assert!(
        error_msg.contains("elevenses"),
        "Error should contain the invalid value, got: {}",
        error_msg
    );
    assert!(
        error_msg.contains("must be") && error_msg.contains("breakfast") && error_msg.contains("lunch") && error_msg.contains("dinner"),
        "Error should list valid options, got: {}",
        error_msg
    );
}

// ============================================================================
// BEAD-004: Numeric Bounds Validation Tests
// ============================================================================

#[test]
fn test_negative_calories_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "breakfast",
                "recipe_name": "Test Recipe",
                "servings": 1.0,
                "calories": -100.0,  // Negative calories
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    // Should return success: false
    assert_eq!(
        output["success"], false,
        "Negative calories should result in success: false"
    );

    // Should have error in errors array
    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(
        !errors.is_empty(),
        "Should have at least one error for negative calories"
    );

    // Error message should mention the validation issue
    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("calories") && (error_msg.contains("negative") || error_msg.contains("must be") || error_msg.contains("0")),
        "Error should mention calories validation issue, got: {}",
        error_msg
    );

    // Entry should not be synced
    assert_eq!(
        output["entries_synced"], 0,
        "Invalid entry should not be synced"
    );
    assert_eq!(
        output["entries_failed"], 1,
        "Invalid entry should be counted as failed"
    );
}

#[test]
fn test_excessive_calories_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "breakfast",
                "recipe_name": "Test Recipe",
                "servings": 1.0,
                "calories": 999999.0,  // Excessive calories
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    assert_eq!(output["success"], false);

    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(!errors.is_empty());

    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("calories") && (error_msg.contains("exceed") || error_msg.contains("maximum") || error_msg.contains("100000")),
        "Error should mention calories exceeds maximum, got: {}",
        error_msg
    );

    assert_eq!(output["entries_synced"], 0);
    assert_eq!(output["entries_failed"], 1);
}

#[test]
fn test_negative_protein_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "lunch",
                "recipe_name": "Test Recipe",
                "servings": 1.0,
                "calories": 300.0,
                "protein": -10.0,  // Negative protein
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    assert_eq!(output["success"], false);

    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(!errors.is_empty());

    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("protein") && (error_msg.contains("negative") || error_msg.contains("must be")),
        "Error should mention protein validation issue, got: {}",
        error_msg
    );

    assert_eq!(output["entries_synced"], 0);
    assert_eq!(output["entries_failed"], 1);
}

#[test]
fn test_excessive_protein_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "lunch",
                "recipe_name": "Test Recipe",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 50000.0,  // Excessive protein
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    assert_eq!(output["success"], false);

    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(!errors.is_empty());

    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("protein") && (error_msg.contains("exceed") || error_msg.contains("maximum") || error_msg.contains("10000")),
        "Error should mention protein exceeds maximum, got: {}",
        error_msg
    );

    assert_eq!(output["entries_synced"], 0);
}

#[test]
fn test_negative_carbohydrate_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "dinner",
                "recipe_name": "Test Recipe",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": -50.0,  // Negative carbohydrate
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    assert_eq!(output["success"], false);

    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(!errors.is_empty());

    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("carbohydrate") && (error_msg.contains("negative") || error_msg.contains("must be")),
        "Error should mention carbohydrate validation issue, got: {}",
        error_msg
    );

    assert_eq!(output["entries_synced"], 0);
}

#[test]
fn test_excessive_carbohydrate_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "dinner",
                "recipe_name": "Test Recipe",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 15000.0,  // Excessive carbohydrate
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    assert_eq!(output["success"], false);

    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(!errors.is_empty());

    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("carbohydrate") && (error_msg.contains("exceed") || error_msg.contains("maximum") || error_msg.contains("10000")),
        "Error should mention carbohydrate exceeds maximum, got: {}",
        error_msg
    );
}

#[test]
fn test_negative_fat_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "snack",
                "recipe_name": "Test Recipe",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": -5.0  // Negative fat
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    assert_eq!(output["success"], false);

    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(!errors.is_empty());

    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("fat") && (error_msg.contains("negative") || error_msg.contains("must be")),
        "Error should mention fat validation issue, got: {}",
        error_msg
    );

    assert_eq!(output["entries_synced"], 0);
}

#[test]
fn test_excessive_fat_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "snack",
                "recipe_name": "Test Recipe",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 20000.0  // Excessive fat
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    assert_eq!(output["success"], false);

    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(!errors.is_empty());

    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("fat") && (error_msg.contains("exceed") || error_msg.contains("maximum") || error_msg.contains("10000")),
        "Error should mention fat exceeds maximum, got: {}",
        error_msg
    );
}

#[test]
fn test_zero_servings_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "breakfast",
                "recipe_name": "Test Recipe",
                "servings": 0.0,  // Zero servings (must be > 0)
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    assert_eq!(output["success"], false);

    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(!errors.is_empty());

    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("servings") && (error_msg.contains("must be greater than") || error_msg.contains("positive") || error_msg.contains("> 0")),
        "Error should mention servings must be positive, got: {}",
        error_msg
    );

    assert_eq!(output["entries_synced"], 0);
}

#[test]
fn test_negative_servings_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "breakfast",
                "recipe_name": "Test Recipe",
                "servings": -1.0,  // Negative servings
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    assert_eq!(output["success"], false);

    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(!errors.is_empty());

    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("servings") && (error_msg.contains("must be greater than") || error_msg.contains("positive")),
        "Error should mention servings must be positive, got: {}",
        error_msg
    );
}

#[test]
fn test_excessive_servings_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "breakfast",
                "recipe_name": "Test Recipe",
                "servings": 5000.0,  // Excessive servings
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    assert_eq!(output["success"], false);

    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(!errors.is_empty());

    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("servings") && (error_msg.contains("exceed") || error_msg.contains("maximum") || error_msg.contains("1000")),
        "Error should mention servings exceeds maximum, got: {}",
        error_msg
    );
}

#[test]
fn test_valid_edge_case_zero_calories() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "breakfast",
                "recipe_name": "Water",
                "servings": 1.0,
                "calories": 0.0,  // Zero calories is valid (e.g., water)
                "protein": 0.0,
                "carbohydrate": 0.0,
                "fat": 0.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    // Should not have validation errors for zero calories
    let errors = output["errors"].as_array().expect("Should have errors array");
    let has_validation_error = errors.iter().any(|e| {
        e.as_str()
            .map(|s| s.contains("calories") && (s.contains("negative") || s.contains("must be")))
            .unwrap_or(false)
    });

    assert!(
        !has_validation_error,
        "Zero calories should be valid (e.g., water). Errors: {:?}",
        errors
    );
}

#[test]
fn test_valid_edge_case_maximum_values() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "breakfast",
                "recipe_name": "Max Values Test",
                "servings": 1000.0,  // Maximum servings
                "calories": 100000.0,  // Maximum calories
                "protein": 10000.0,  // Maximum protein
                "carbohydrate": 10000.0,  // Maximum carbohydrate
                "fat": 10000.0  // Maximum fat
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    // Should not have validation errors for maximum valid values
    let errors = output["errors"].as_array().expect("Should have errors array");
    let has_validation_error = errors.iter().any(|e| {
        e.as_str()
            .map(|s| s.contains("exceed") || s.contains("maximum"))
            .unwrap_or(false)
    });

    assert!(
        !has_validation_error,
        "Maximum valid values should be accepted. Errors: {:?}",
        errors
    );
}

#[test]
fn test_multiple_validation_errors() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "breakfast",
                "recipe_name": "Multiple Errors",
                "servings": -1.0,  // Invalid: negative
                "calories": -100.0,  // Invalid: negative
                "protein": 20000.0,  // Invalid: too high
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    assert_eq!(output["success"], false);

    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(
        !errors.is_empty(),
        "Should have validation errors"
    );

    // Should report the first validation error encountered
    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("servings") || error_msg.contains("calories") || error_msg.contains("protein"),
        "Error should mention one of the invalid fields, got: {}",
        error_msg
    );

    assert_eq!(output["entries_synced"], 0);
}

#[test]
fn test_mixed_valid_and_invalid_numeric_entries() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "breakfast",
                "recipe_name": "Valid Entry",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            },
            {
                "date": "2025-01-01",
                "meal_type": "lunch",
                "recipe_name": "Invalid Entry",
                "servings": 1.0,
                "calories": -100.0,  // Invalid: negative
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            },
            {
                "date": "2025-01-01",
                "meal_type": "dinner",
                "recipe_name": "Another Valid Entry",
                "servings": 2.0,
                "calories": 600.0,
                "protein": 20.0,
                "carbohydrate": 80.0,
                "fat": 15.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    // Should return success: false because there are errors
    assert_eq!(
        output["success"], false,
        "Should return success: false when any entry has errors"
    );

    // Should have at least 1 error for the invalid entry
    let errors = output["errors"].as_array().expect("Should have errors array");
    let validation_errors: Vec<_> = errors
        .iter()
        .filter(|e| {
            e.as_str()
                .map(|s| s.contains("calories") && (s.contains("negative") || s.contains("must be")))
                .unwrap_or(false)
        })
        .collect();

    assert_eq!(
        validation_errors.len(),
        1,
        "Should have exactly 1 validation error for negative calories. Got: {:?}",
        errors
    );

    // entries_failed should be at least 1 (the invalid one)
    assert!(
        output["entries_failed"].as_u64().unwrap() >= 1,
        "Should have at least 1 failed entry"
    );
}

// ============================================================================
// BEAD-006: Empty String Validation Tests
// ============================================================================

#[test]
fn test_recipe_name_valid_accepted() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "breakfast",
                "recipe_name": "Chicken Salad",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    // Valid recipe_name should not produce validation errors
    let errors = output["errors"].as_array().expect("Should have errors array");
    let has_validation_error = errors.iter().any(|e| {
        e.as_str()
            .map(|s| s.contains("recipe_name") && (s.contains("empty") || s.contains("required")))
            .unwrap_or(false)
    });

    assert!(
        !has_validation_error,
        "Valid recipe_name should not produce validation error. Errors: {:?}",
        errors
    );
}

#[test]
fn test_recipe_name_empty_string_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "breakfast",
                "recipe_name": "",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    assert_eq!(
        output["success"], false,
        "Empty recipe_name should result in success: false"
    );

    let errors = output["errors"].as_array().expect("Should have errors array");
    assert!(
        !errors.is_empty(),
        "Should have at least one error for empty recipe_name"
    );

    let error_msg = errors[0].as_str().expect("Error should be a string");
    assert!(
        error_msg.contains("recipe_name") && (error_msg.contains("empty") || error_msg.contains("cannot be empty") || error_msg.contains("required")),
        "Error should mention recipe_name is empty/required, got: {}",
        error_msg
    );

    assert_eq!(
        output["entries_synced"], 0,
        "Invalid entry should not be synced"
    );
    assert_eq!(
        output["entries_failed"], 1,
        "Invalid entry should be counted as failed"
    );
}

#[test]
fn test_recipe_name_whitespace_only_rejected() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let whitespace_values = ["   ", " ", "\t  ", "  \n  "];

    for whitespace in &whitespace_values {
        let input = json!({
            "fatsecret": {
                "consumer_key": TEST_CONSUMER_KEY,
                "consumer_secret": TEST_CONSUMER_SECRET
            },
            "access_token": "test_token",
            "access_secret": "test_secret",
            "entries": [
                {
                    "date": "2025-01-01",
                    "meal_type": "breakfast",
                    "recipe_name": whitespace,
                    "servings": 1.0,
                    "calories": 300.0,
                    "protein": 10.0,
                    "carbohydrate": 50.0,
                    "fat": 5.0
                }
            ]
        });

        let output = run_sync_meal_plan(&input);

        assert_eq!(
            output["success"], false,
            "Whitespace-only recipe_name '{}' should result in success: false",
            whitespace.escape_default()
        );

        let errors = output["errors"].as_array().expect("Should have errors array");
        assert!(
            !errors.is_empty(),
            "Should have at least one error for whitespace-only recipe_name"
        );

        let error_msg = errors[0].as_str().expect("Error should be a string");
        assert!(
            error_msg.contains("recipe_name") && (error_msg.contains("empty") || error_msg.contains("cannot be empty") || error_msg.contains("required")),
            "Error should mention recipe_name is empty/required for '{}', got: {}",
            whitespace.escape_default(),
            error_msg
        );

        assert_eq!(
            output["entries_synced"], 0,
            "Invalid entry should not be synced"
        );
        assert_eq!(
            output["entries_failed"], 1,
            "Invalid entry should be counted as failed"
        );
    }
}

#[test]
fn test_recipe_name_with_leading_trailing_whitespace_trimmed() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-01",
                "meal_type": "breakfast",
                "recipe_name": "  Chicken Salad  ",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input);

    // recipe_name with visible characters (after trimming) should not produce validation errors
    let errors = output["errors"].as_array().expect("Should have errors array");
    let has_validation_error = errors.iter().any(|e| {
        e.as_str()
            .map(|s| s.contains("recipe_name") && (s.contains("empty") || s.contains("required")))
            .unwrap_or(false)
    });

    assert!(
        !has_validation_error,
        "recipe_name with visible characters after trimming should not produce validation error. Errors: {:?}",
        errors
    );
}
