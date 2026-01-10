//! Schema Introspection Tests for BEAD-003
//!
//! Tests that all foundation binaries support --schema flag and output valid JSON Schema Draft 7

use serde_json::Value;
use std::process::Command;

/// Test that binary outputs valid JSON when invoked with --schema
fn test_schema_valid_json(binary_name: &str) {
    let binary_path = format!("target/debug/{}", binary_name);
    if !std::path::Path::new(&binary_path).exists() {
        eprintln!("Skipping test: {} binary not found", binary_name);
        return;
    }

    let mut cmd = Command::new(&binary_path);
    let output = cmd.arg("--schema").output().expect("Failed to execute");

    // Should exit with code 0
    assert!(
        output.status.success(),
        "{} --schema should exit with code 0",
        binary_name
    );

    // Should output to stdout
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Should be valid JSON
    let json: Value = serde_json::from_str(&stdout).unwrap_or_else(|e| {
        panic!("{} --schema output is not valid JSON: {}\nOutput: {}", binary_name, e, stdout)
    });

    // Verify with jq-style check (parse and reformat)
    let reparsed = serde_json::to_string(&json).expect("Should be able to serialize");
    assert!(!reparsed.is_empty(), "JSON should not be empty");
}

/// Test that schema contains required fields
fn test_schema_required_fields(binary_name: &str) {
    let binary_path = format!("target/debug/{}", binary_name);
    if !std::path::Path::new(&binary_path).exists() {
        eprintln!("Skipping test: {} binary not found", binary_name);
        return;
    }

    let mut cmd = Command::new(&binary_path);
    let output = cmd.arg("--schema").output().expect("Failed to execute");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let json: Value = serde_json::from_str(&stdout)
        .unwrap_or_else(|e| panic!("{} --schema output is not valid JSON: {}", binary_name, e));

    // Required fields
    assert!(
        json.get("binary_name").and_then(Value::as_str).is_some(),
        "{} schema should have 'binary_name' string field",
        binary_name
    );

    assert!(
        json.get("description").and_then(Value::as_str).is_some(),
        "{} schema should have 'description' string field",
        binary_name
    );

    assert!(
        json.get("version").and_then(Value::as_str).is_some(),
        "{} schema should have 'version' string field",
        binary_name
    );

    assert!(
        json.get("input").is_some(),
        "{} schema should have 'input' field",
        binary_name
    );

    assert!(
        json.get("output_success").is_some(),
        "{} schema should have 'output_success' field",
        binary_name
    );

    assert!(
        json.get("output_error").is_some(),
        "{} schema should have 'output_error' field",
        binary_name
    );

    assert!(
        json.get("examples").and_then(Value::as_array).is_some(),
        "{} schema should have 'examples' array field",
        binary_name
    );
}

/// Test that schema provides at least 2 examples
fn test_schema_has_examples(binary_name: &str) {
    let binary_path = format!("target/debug/{}", binary_name);
    if !std::path::Path::new(&binary_path).exists() {
        eprintln!("Skipping test: {} binary not found", binary_name);
        return;
    }

    let mut cmd = Command::new(&binary_path);
    let output = cmd.arg("--schema").output().expect("Failed to execute");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let json: Value = serde_json::from_str(&stdout)
        .unwrap_or_else(|e| panic!("{} --schema output is not valid JSON: {}", binary_name, e));

    let examples = json.get("examples").and_then(Value::as_array)
        .unwrap_or_else(|| panic!("{} schema should have 'examples' array", binary_name));

    assert!(
        examples.len() >= 2,
        "{} schema should have at least 2 examples, found {}",
        binary_name,
        examples.len()
    );

    // Each example should have description, input, and expected_output
    for (i, example) in examples.iter().enumerate() {
        assert!(
            example.get("description").and_then(Value::as_str).is_some(),
            "{} example {} should have 'description'",
            binary_name,
            i
        );

        assert!(
            example.get("input").is_some(),
            "{} example {} should have 'input'",
            binary_name,
            i
        );

        assert!(
            example.get("expected_output").is_some(),
            "{} example {} should have 'expected_output'",
            binary_name,
            i
        );
    }
}

/// Test that schema is JSON Schema Draft 7
fn test_schema_draft_7(binary_name: &str) {
    let binary_path = format!("target/debug/{}", binary_name);
    if !std::path::Path::new(&binary_path).exists() {
        eprintln!("Skipping test: {} binary not found", binary_name);
        return;
    }

    let mut cmd = Command::new(&binary_path);
    let output = cmd.arg("--schema").output().expect("Failed to execute");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let json: Value = serde_json::from_str(&stdout)
        .unwrap_or_else(|e| panic!("{} --schema output is not valid JSON: {}", binary_name, e));

    let schema_version = json.get("$schema").and_then(Value::as_str)
        .unwrap_or_else(|| panic!("{} schema should have '$schema' field", binary_name));

    assert!(
        schema_version.contains("draft-07") || schema_version.contains("draft/07"),
        "{} schema should be JSON Schema Draft 7, got: {}",
        binary_name,
        schema_version
    );
}

// Generate tests for each binary using macros
macro_rules! generate_schema_tests {
    ($($binary:ident),* $(,)?) => {
        $(
            mod $binary {
                use super::*;

                #[test]
                fn valid_json() {
                    test_schema_valid_json(stringify!($binary));
                }

                #[test]
                fn required_fields() {
                    test_schema_required_fields(stringify!($binary));
                }

                #[test]
                fn has_examples() {
                    test_schema_has_examples(stringify!($binary));
                }

                #[test]
                fn is_draft_7() {
                    test_schema_draft_7(stringify!($binary));
                }
            }
        )*
    };
}

// Generate tests for all foundation binaries
generate_schema_tests!(
    generate_encryption_key,
    validate_encryption,
    tandoor_test_connection,
    sync_meal_plan,
    log_recipe_to_fatsecret,
    analyze_nutrition,
    track_exercise_balance,
);
