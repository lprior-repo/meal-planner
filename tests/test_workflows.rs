//! Integration Test Workflows (BEAD-011)
//!
//! End-to-end integration tests with realistic data flows.
//! Tests complete workflows from setup through execution to validation.
//!
//! # Workflows
//!
//! 1. **encryption_setup** - Generate and validate encryption keys
//! 2. **sync_meal_plan_valid** - Sync valid meal plan entries
//! 3. **sync_meal_plan_invalid** - Handle invalid entries gracefully
//! 4. **validation_rejection_workflow** - Multiple validation failures

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

mod helpers;

use helpers::support::binary_runner::binary_exists;
use serde_json::{json, Value};
use std::env;
use std::io::Write;
use std::process::{Command, Stdio};
use std::sync::Mutex;

// Mutex to ensure tests that modify OAUTH_ENCRYPTION_KEY run serially
static ENCRYPTION_TEST_LOCK: once_cell::sync::Lazy<Mutex<()>> =
    once_cell::sync::Lazy::new(|| Mutex::new(()));

// Valid-looking credentials (16+ chars) to pass initial validation
const TEST_CONSUMER_KEY: &str = "test_consumer_key_16_chars_min";
const TEST_CONSUMER_SECRET: &str = "test_consumer_secret_16_chars";

// =============================================================================
// Workflow 1: Encryption Setup
// =============================================================================

/// Test complete encryption setup workflow
///
/// Steps:
/// 1. Run generate_encryption_key
/// 2. Extract key from output
/// 3. Set as OAUTH_ENCRYPTION_KEY env var
/// 4. Run validate_encryption
/// 5. Verify success
#[test]
fn workflow_encryption_setup() {
    let _lock = ENCRYPTION_TEST_LOCK.lock().unwrap();

    if !binary_exists("generate_encryption_key") {
        eprintln!("Skipping test: generate_encryption_key binary not found");
        return;
    }

    if !binary_exists("validate_encryption") {
        eprintln!("Skipping test: validate_encryption binary not found");
        return;
    }

    // Step 1: Run generate_encryption_key
    let generate_result = run_generate_encryption_key();
    assert!(
        generate_result.is_ok(),
        "generate_encryption_key should succeed: {:?}",
        generate_result
    );

    let generate_output = generate_result.unwrap();

    // Step 2: Verify output structure
    assert_eq!(
        generate_output["success"], true,
        "generate_encryption_key should return success: {}",
        generate_output
    );

    let key = generate_output["key"]
        .as_str()
        .expect("Output should have 'key' field");

    assert!(
        !key.is_empty(),
        "Generated key should not be empty"
    );

    assert_eq!(
        key.len(),
        64,
        "Generated key should be 64 characters long"
    );

    assert!(
        key.chars().all(|c| c.is_ascii_hexdigit()),
        "Generated key should be valid hex: {}",
        key
    );

    // Step 3: Set as OAUTH_ENCRYPTION_KEY env var
    env::set_var("OAUTH_ENCRYPTION_KEY", key);

    // Step 4: Run validate_encryption
    let validate_input = json!({});
    let validate_result = run_validate_encryption(&validate_input);

    assert!(
        validate_result.is_ok(),
        "validate_encryption should succeed: {:?}",
        validate_result
    );

    let validate_output = validate_result.unwrap();

    // Step 5: Verify success
    assert_eq!(
        validate_output["success"], true,
        "validate_encryption should return success: {}",
        validate_output
    );

    assert!(
        validate_output["message"]
            .as_str()
            .unwrap()
            .contains("valid and functional"),
        "Message should confirm encryption is functional: {}",
        validate_output["message"]
    );

    // Cleanup
    env::remove_var("OAUTH_ENCRYPTION_KEY");
}

/// Test encryption setup with detailed validation
#[test]
fn workflow_encryption_setup_detailed() {
    let _lock = ENCRYPTION_TEST_LOCK.lock().unwrap();

    if !binary_exists("generate_encryption_key") || !binary_exists("validate_encryption") {
        eprintln!("Skipping test: required binaries not found");
        return;
    }

    // Generate key
    let generate_result = run_generate_encryption_key();
    assert!(generate_result.is_ok());

    let key = generate_result.unwrap()["key"]
        .as_str()
        .expect("Should have key")
        .to_string();

    // Set environment variable
    env::set_var("OAUTH_ENCRYPTION_KEY", &key);

    // Run detailed validation
    let validate_input = json!({
        "detailed": true
    });

    let validate_result = run_validate_encryption(&validate_input);
    assert!(validate_result.is_ok());

    let validate_output = validate_result.unwrap();

    // Verify detailed output
    assert_eq!(validate_output["success"], true);

    let details = &validate_output["details"];
    assert!(
        details.is_object(),
        "Should have details object in output. Got: {}",
        validate_output
    );

    assert_eq!(details["key_is_set"], true);
    assert_eq!(details["key_length"], 64);
    assert_eq!(details["key_is_valid_hex"], true);
    assert_eq!(details["key_correct_length"], true);

    // Cleanup
    env::remove_var("OAUTH_ENCRYPTION_KEY");
}

// =============================================================================
// Workflow 2: Sync Meal Plan - Valid Data
// =============================================================================

/// Test successful meal plan sync with valid data
///
/// Steps:
/// 1. Prepare valid meal plan entries (JSON)
/// 2. Run sync_meal_plan
/// 3. Verify output structure
/// 4. Check entries_synced > 0
/// 5. Verify errors array is empty
#[test]
fn workflow_sync_meal_plan_valid() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    // Step 1: Prepare valid meal plan entries
    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_valid_token_12345678",
        "access_secret": "test_valid_secret_12345678",
        "entries": [
            {
                "date": "2025-01-15",
                "meal_type": "breakfast",
                "recipe_name": "Oatmeal with Berries",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            },
            {
                "date": "2025-01-15",
                "meal_type": "lunch",
                "recipe_name": "Grilled Chicken Salad",
                "servings": 1.5,
                "calories": 450.0,
                "protein": 40.0,
                "carbohydrate": 15.0,
                "fat": 20.0
            },
            {
                "date": "2025-01-15",
                "meal_type": "dinner",
                "recipe_name": "Salmon with Vegetables",
                "servings": 1.0,
                "calories": 550.0,
                "protein": 45.0,
                "carbohydrate": 30.0,
                "fat": 25.0
            }
        ]
    });

    // Step 2: Run sync_meal_plan
    let result = run_sync_meal_plan(&input);

    // Note: This will fail because we don't have real OAuth credentials,
    // but we can verify the structure is correct
    let output = result.unwrap_or_else(|_| {
        // If it fails, run again to get the JSON output
        run_sync_meal_plan(&input).unwrap()
    });

    // Step 3: Verify output structure
    assert!(
        output.get("success").is_some(),
        "Output should have 'success' field"
    );
    assert!(
        output.get("entries_synced").is_some(),
        "Output should have 'entries_synced' field"
    );
    assert!(
        output.get("entries_failed").is_some(),
        "Output should have 'entries_failed' field"
    );
    assert!(
        output.get("total_calories").is_some(),
        "Output should have 'total_calories' field"
    );
    assert!(
        output.get("total_protein").is_some(),
        "Output should have 'total_protein' field"
    );
    assert!(
        output.get("days_processed").is_some(),
        "Output should have 'days_processed' field"
    );
    assert!(
        output.get("synced_entries").is_some(),
        "Output should have 'synced_entries' array"
    );
    assert!(
        output.get("errors").is_some(),
        "Output should have 'errors' array"
    );

    // Verify array types
    assert!(
        output["synced_entries"].is_array(),
        "synced_entries should be an array"
    );
    assert!(
        output["errors"].is_array(),
        "errors should be an array"
    );

    // Step 4 & 5: If we had real credentials, we would verify:
    // - entries_synced > 0
    // - errors array is empty
    // But with test credentials, we expect API failures (not validation failures)
}

/// Test sync with single valid entry
#[test]
fn workflow_sync_meal_plan_single_entry() {
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
                "date": "2025-01-20",
                "meal_type": "snack",
                "recipe_name": "Apple",
                "servings": 1.0,
                "calories": 95.0,
                "protein": 0.5,
                "carbohydrate": 25.0,
                "fat": 0.3
            }
        ]
    });

    let output = run_sync_meal_plan(&input).unwrap();

    // Verify structure
    assert!(output["success"].is_boolean());
    assert!(output["entries_synced"].is_number());
    assert!(output["entries_failed"].is_number());
    assert!(output["synced_entries"].is_array());
    assert!(output["errors"].is_array());
}

// =============================================================================
// Workflow 3: Sync Meal Plan - Invalid Data
// =============================================================================

/// Test meal plan sync with invalid data
///
/// Steps:
/// 1. Prepare invalid entries (negative calories, invalid meal_type)
/// 2. Run sync_meal_plan
/// 3. Verify success=false
/// 4. Verify errors array has messages
/// 5. Verify entries_synced=0
#[test]
fn workflow_sync_meal_plan_invalid() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    // Step 1: Prepare invalid entries
    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-15",
                "meal_type": "invalid_meal",  // Invalid meal type
                "recipe_name": "Test Recipe",
                "servings": 1.0,
                "calories": -100.0,  // Negative calories (invalid)
                "protein": 10.0,
                "carbohydrate": 20.0,
                "fat": 5.0
            },
            {
                "date": "invalid-date-format",  // Invalid date
                "meal_type": "elevenses",  // Invalid meal type
                "recipe_name": "Another Test",
                "servings": 1.0,
                "calories": 200.0,
                "protein": 5.0,
                "carbohydrate": 30.0,
                "fat": 3.0
            }
        ]
    });

    // Step 2: Run sync_meal_plan
    let output = run_sync_meal_plan(&input).unwrap();

    // Step 3: Verify success=false
    assert_eq!(
        output["success"], false,
        "Should return success: false for invalid data"
    );

    // Step 4: Verify errors array has messages
    let errors = output["errors"]
        .as_array()
        .expect("Should have errors array");

    assert!(
        !errors.is_empty(),
        "Should have at least one error message"
    );

    // Verify error messages contain expected content
    let errors_str = errors
        .iter()
        .map(|e| e.as_str().unwrap_or(""))
        .collect::<Vec<_>>()
        .join(" ");

    assert!(
        errors_str.contains("Invalid meal_type"),
        "Errors should mention invalid meal_type: {:?}",
        errors
    );

    // Step 5: Verify entries_synced=0
    assert_eq!(
        output["entries_synced"], 0,
        "Should have synced 0 entries with invalid data"
    );

    assert!(
        output["entries_failed"].as_u64().unwrap() > 0,
        "Should have at least one failed entry"
    );
}

/// Test invalid meal types are rejected
#[test]
fn workflow_sync_meal_plan_invalid_meal_types() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let invalid_meal_types = vec![
        "brunch",
        "second_breakfast",
        "afternoon_tea",
        "midnight_snack",
        "",
        "INVALID",
    ];

    for invalid_type in invalid_meal_types {
        let input = json!({
            "fatsecret": {
                "consumer_key": TEST_CONSUMER_KEY,
                "consumer_secret": TEST_CONSUMER_SECRET
            },
            "access_token": "test_token",
            "access_secret": "test_secret",
            "entries": [
                {
                    "date": "2025-01-15",
                    "meal_type": invalid_type,
                    "recipe_name": "Test Recipe",
                    "servings": 1.0,
                    "calories": 300.0,
                    "protein": 10.0,
                    "carbohydrate": 50.0,
                    "fat": 5.0
                }
            ]
        });

        let output = run_sync_meal_plan(&input).unwrap();

        assert_eq!(
            output["success"], false,
            "Invalid meal_type '{}' should fail",
            invalid_type
        );

        let errors = output["errors"].as_array().unwrap();
        assert!(
            !errors.is_empty(),
            "Should have error for invalid meal_type '{}'",
            invalid_type
        );

        let error_msg = errors[0].as_str().unwrap();
        assert!(
            error_msg.contains("Invalid meal_type"),
            "Error should mention invalid meal_type for '{}': {}",
            invalid_type,
            error_msg
        );
    }
}

/// Test invalid dates are rejected
#[test]
fn workflow_sync_meal_plan_invalid_dates() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    let invalid_dates = vec![
        "2025-13-01",  // Invalid month
        "2025-01-32",  // Invalid day
        "01/15/2025",  // Wrong format
        "2025/01/15",  // Wrong separator
        "not-a-date",
        "",
    ];

    for invalid_date in invalid_dates {
        let input = json!({
            "fatsecret": {
                "consumer_key": TEST_CONSUMER_KEY,
                "consumer_secret": TEST_CONSUMER_SECRET
            },
            "access_token": "test_token",
            "access_secret": "test_secret",
            "entries": [
                {
                    "date": invalid_date,
                    "meal_type": "breakfast",
                    "recipe_name": "Test Recipe",
                    "servings": 1.0,
                    "calories": 300.0,
                    "protein": 10.0,
                    "carbohydrate": 50.0,
                    "fat": 5.0
                }
            ]
        });

        let output = run_sync_meal_plan(&input).unwrap();

        assert_eq!(
            output["success"], false,
            "Invalid date '{}' should fail",
            invalid_date
        );

        let errors = output["errors"].as_array().unwrap();
        assert!(
            !errors.is_empty(),
            "Should have error for invalid date '{}'",
            invalid_date
        );

        let error_msg = errors[0].as_str().unwrap();
        assert!(
            error_msg.contains("Invalid date") || error_msg.contains(&invalid_date),
            "Error should mention invalid date for '{}': {}",
            invalid_date,
            error_msg
        );
    }
}

// =============================================================================
// Workflow 4: Validation Rejection - Multiple Failures
// =============================================================================

/// Test multiple validation failures in one request
///
/// Steps:
/// 1. Create request with multiple types of validation failures
/// 2. Run sync_meal_plan
/// 3. Verify all errors are captured
/// 4. Verify proper error messages for each failure type
#[test]
fn workflow_validation_rejection_multiple_failures() {
    if !binary_exists("sync_meal_plan") {
        eprintln!("Skipping test: sync_meal_plan binary not found");
        return;
    }

    // Step 1: Create request with multiple validation failures
    let input = json!({
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "entries": [
            {
                "date": "2025-01-15",
                "meal_type": "invalid_type_1",  // Invalid meal type
                "recipe_name": "Entry 1",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            },
            {
                "date": "not-a-date",  // Invalid date
                "meal_type": "breakfast",
                "recipe_name": "Entry 2",
                "servings": 1.0,
                "calories": 200.0,
                "protein": 5.0,
                "carbohydrate": 30.0,
                "fat": 3.0
            },
            {
                "date": "2025-01-15",
                "meal_type": "invalid_type_2",  // Another invalid meal type
                "recipe_name": "Entry 3",
                "servings": 1.0,
                "calories": 400.0,
                "protein": 15.0,
                "carbohydrate": 40.0,
                "fat": 10.0
            },
            {
                "date": "2025-99-99",  // Invalid date
                "meal_type": "lunch",
                "recipe_name": "Entry 4",
                "servings": 1.0,
                "calories": 500.0,
                "protein": 20.0,
                "carbohydrate": 60.0,
                "fat": 15.0
            }
        ]
    });

    // Step 2: Run sync_meal_plan
    let output = run_sync_meal_plan(&input).unwrap();

    // Step 3: Verify all errors are captured
    assert_eq!(
        output["success"], false,
        "Should return success: false with multiple validation failures"
    );

    let errors = output["errors"]
        .as_array()
        .expect("Should have errors array");

    assert!(
        errors.len() >= 4,
        "Should have at least 4 errors (one for each invalid entry), got: {:?}",
        errors
    );

    // Step 4: Verify proper error messages for each failure type
    let errors_str = errors
        .iter()
        .map(|e| e.as_str().unwrap_or(""))
        .collect::<Vec<_>>()
        .join("\n");

    // Check for meal_type errors
    let meal_type_errors = errors
        .iter()
        .filter(|e| {
            e.as_str()
                .map(|s| s.contains("Invalid meal_type"))
                .unwrap_or(false)
        })
        .count();

    assert!(
        meal_type_errors >= 2,
        "Should have at least 2 meal_type errors, got: {}. Errors: {:?}",
        meal_type_errors,
        errors
    );

    // Check for date errors
    let date_errors = errors
        .iter()
        .filter(|e| {
            e.as_str()
                .map(|s| s.contains("Invalid date"))
                .unwrap_or(false)
        })
        .count();

    assert!(
        date_errors >= 2,
        "Should have at least 2 date errors, got: {}. Errors: {:?}",
        date_errors,
        errors
    );

    // Verify error messages are actionable
    assert!(
        errors_str.contains("breakfast") || errors_str.contains("lunch") || errors_str.contains("dinner"),
        "Meal type errors should list valid options: {}",
        errors_str
    );

    // Verify no entries were synced
    assert_eq!(
        output["entries_synced"], 0,
        "No entries should be synced when all have validation errors"
    );

    assert_eq!(
        output["entries_failed"].as_u64().unwrap(),
        4,
        "All 4 entries should have failed"
    );
}

/// Test partial validation failures (some valid, some invalid)
#[test]
fn workflow_validation_rejection_partial_failures() {
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
                "date": "2025-01-15",
                "meal_type": "breakfast",  // Valid
                "recipe_name": "Valid Entry",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            },
            {
                "date": "2025-01-15",
                "meal_type": "invalid",  // Invalid
                "recipe_name": "Invalid Entry",
                "servings": 1.0,
                "calories": 200.0,
                "protein": 5.0,
                "carbohydrate": 30.0,
                "fat": 3.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input).unwrap();

    // Should fail because there are errors
    assert_eq!(output["success"], false);

    // Should have validation errors
    let errors = output["errors"].as_array().unwrap();
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
        "Should have exactly 1 validation error"
    );

    // At least one entry should have failed
    assert!(
        output["entries_failed"].as_u64().unwrap() >= 1,
        "Should have at least 1 failed entry"
    );
}

/// Test that error messages are actionable
#[test]
fn workflow_validation_error_messages_actionable() {
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
                "date": "2025-01-15",
                "meal_type": "brunch",  // Common mistake
                "recipe_name": "Test",
                "servings": 1.0,
                "calories": 300.0,
                "protein": 10.0,
                "carbohydrate": 50.0,
                "fat": 5.0
            }
        ]
    });

    let output = run_sync_meal_plan(&input).unwrap();
    let errors = output["errors"].as_array().unwrap();

    assert!(!errors.is_empty(), "Should have errors");

    let error_msg = errors[0].as_str().unwrap();

    // Error should mention the invalid value
    assert!(
        error_msg.contains("brunch"),
        "Error should mention the invalid value 'brunch': {}",
        error_msg
    );

    // Error should list valid options
    assert!(
        error_msg.contains("breakfast")
            && error_msg.contains("lunch")
            && error_msg.contains("dinner")
            && error_msg.contains("snack"),
        "Error should list all valid meal types: {}",
        error_msg
    );

    // Error should explain what's wrong
    assert!(
        error_msg.contains("Invalid meal_type") || error_msg.contains("must be"),
        "Error should explain what's wrong: {}",
        error_msg
    );
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Run generate_encryption_key binary
fn run_generate_encryption_key() -> Result<Value, String> {
    let binary_path = if std::path::Path::new("./bin/generate_encryption_key").exists() {
        "./bin/generate_encryption_key"
    } else if std::path::Path::new("./target/debug/generate_encryption_key").exists() {
        "./target/debug/generate_encryption_key"
    } else if std::path::Path::new("./target/release/generate_encryption_key").exists() {
        "./target/release/generate_encryption_key"
    } else {
        return Err("generate_encryption_key binary not found".to_string());
    };

    let output = Command::new(binary_path)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .output()
        .map_err(|e| format!("Failed to execute binary: {}", e))?;

    if !output.status.success() {
        return Err(format!(
            "Binary failed with exit code {}: {}",
            output.status.code().unwrap_or(-1),
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    serde_json::from_str(&stdout).map_err(|e| {
        format!(
            "Failed to parse JSON output: {}\nOutput: {}",
            e, stdout
        )
    })
}

/// Run validate_encryption binary with JSON input
fn run_validate_encryption(input: &Value) -> Result<Value, String> {
    let binary_path = if std::path::Path::new("./bin/validate_encryption").exists() {
        "./bin/validate_encryption"
    } else if std::path::Path::new("./target/debug/validate_encryption").exists() {
        "./target/debug/validate_encryption"
    } else if std::path::Path::new("./target/release/validate_encryption").exists() {
        "./target/release/validate_encryption"
    } else {
        return Err("validate_encryption binary not found".to_string());
    };

    // validate_encryption reads from command-line args, not stdin
    let json_str = input.to_string();

    let output = Command::new(binary_path)
        .arg(&json_str)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .output()
        .map_err(|e| format!("Failed to execute binary: {}", e))?;

    if !output.status.success() {
        return Err(format!(
            "Binary failed with exit code {}: {}",
            output.status.code().unwrap_or(-1),
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    serde_json::from_str(&stdout).map_err(|e| {
        format!(
            "Failed to parse JSON output: {}\nOutput: {}",
            e, stdout
        )
    })
}

/// Run sync_meal_plan binary with JSON input
fn run_sync_meal_plan(input: &Value) -> Result<Value, String> {
    let binary_path = if std::path::Path::new("./bin/sync_meal_plan").exists() {
        "./bin/sync_meal_plan"
    } else if std::path::Path::new("./target/debug/sync_meal_plan").exists() {
        "./target/debug/sync_meal_plan"
    } else if std::path::Path::new("./target/release/sync_meal_plan").exists() {
        "./target/release/sync_meal_plan"
    } else {
        return Err("sync_meal_plan binary not found".to_string());
    };

    let mut child = Command::new(binary_path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to spawn binary: {}", e))?;

    if let Some(ref mut stdin) = child.stdin {
        let json_str = input.to_string();
        stdin
            .write_all(json_str.as_bytes())
            .map_err(|e| format!("Failed to write to stdin: {}", e))?;
    }

    let output = child
        .wait_with_output()
        .map_err(|e| format!("Failed to wait for child: {}", e))?;

    let stdout = String::from_utf8_lossy(&output.stdout);

    // sync_meal_plan always outputs JSON, even on failure
    serde_json::from_str(&stdout).map_err(|e| {
        format!(
            "Failed to parse JSON output: {}\nOutput: {}\nstderr: {}",
            e,
            stdout,
            String::from_utf8_lossy(&output.stderr)
        )
    })
}
