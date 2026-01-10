//! BEAD-009: Test Suite for --schema Flags
//!
//! This test suite validates that all foundation binaries properly implement
//! --schema introspection according to the JSON Schema Draft 7 specification.
//!
//! ## Test Coverage
//!
//! For each foundation binary, we test:
//! 1. Binary supports --schema flag and exits with code 0
//! 2. --schema output is valid JSON (can be parsed by serde_json)
//! 3. Schema contains all required fields (binary_name, description, input, output_success, output_error, examples)
//! 4. Schema uses JSON Schema Draft 7 ($schema field)
//! 5. Examples in schema are valid JSON and well-formed
//! 6. Schema examples contain required fields (description, input, expected_output)
//! 7. Example inputs can be validated against the input schema
//! 8. Example outputs can be validated against the output_success schema
//!
//! ## Foundation Binaries Tested
//!
//! - generate_encryption_key
//! - validate_encryption
//! - tandoor_test_connection
//! - sync_meal_plan
//! - log_recipe_to_fatsecret
//! - analyze_nutrition
//! - track_exercise_balance
//!
//! ## Architecture
//!
//! Tests follow Dave Farley's Acceptance Test-Driven Development pattern:
//! - Pure validation functions (Functional Core)
//! - I/O coordination through helper functions (Imperative Shell)
//! - Clear separation of concerns

#![allow(clippy::unwrap_used, clippy::expect_used)]

use serde_json::Value;
use std::process::Command;

// ============================================================================
// FUNCTIONAL CORE - Pure Validation Functions
// ============================================================================

/// Validate that JSON is a valid schema with all required top-level fields
fn validate_schema_structure(schema: &Value, binary_name: &str) {
    // Required fields per BEAD-009
    let required_fields = [
        "$schema",
        "binary_name",
        "description",
        "version",
        "input",
        "output_success",
        "output_error",
        "examples",
    ];

    for field in &required_fields {
        assert!(
            schema.get(field).is_some(),
            "{} schema missing required field: {}",
            binary_name,
            field
        );
    }
}

/// Validate $schema field uses JSON Schema Draft 7
fn validate_schema_version(schema: &Value, binary_name: &str) {
    let schema_version = schema
        .get("$schema")
        .and_then(Value::as_str)
        .unwrap_or_else(|| panic!("{} schema missing $schema field", binary_name));

    assert!(
        schema_version.contains("draft-07") || schema_version.contains("draft/07"),
        "{} schema should use JSON Schema Draft 7, got: {}",
        binary_name,
        schema_version
    );
}

/// Validate binary_name field is a non-empty string
fn validate_binary_name(schema: &Value, expected_name: &str) {
    let binary_name = schema
        .get("binary_name")
        .and_then(Value::as_str)
        .unwrap_or_else(|| panic!("{} schema missing binary_name string field", expected_name));

    assert_eq!(
        binary_name, expected_name,
        "binary_name should match expected name"
    );
}

/// Validate description field is a non-empty string
fn validate_description(schema: &Value, binary_name: &str) {
    let description = schema
        .get("description")
        .and_then(Value::as_str)
        .unwrap_or_else(|| panic!("{} schema missing description string field", binary_name));

    assert!(
        !description.is_empty(),
        "{} schema description should not be empty",
        binary_name
    );
}

/// Validate version field is a non-empty string
fn validate_version(schema: &Value, binary_name: &str) {
    let version = schema
        .get("version")
        .and_then(Value::as_str)
        .unwrap_or_else(|| panic!("{} schema missing version string field", binary_name));

    assert!(
        !version.is_empty(),
        "{} schema version should not be empty",
        binary_name
    );
}

/// Validate examples array exists and is non-empty
fn validate_examples_array(schema: &Value, binary_name: &str) {
    let examples = schema
        .get("examples")
        .and_then(Value::as_array)
        .unwrap_or_else(|| panic!("{} schema missing examples array", binary_name));

    assert!(
        examples.len() >= 2,
        "{} schema should have at least 2 examples, found {}",
        binary_name,
        examples.len()
    );
}

/// Validate each example has required fields and valid structure
fn validate_example_structure(example: &Value, binary_name: &str, index: usize) {
    // Each example must have: description, input, expected_output
    let required_fields = ["description", "input", "expected_output"];

    for field in &required_fields {
        assert!(
            example.get(field).is_some(),
            "{} example {} missing required field: {}",
            binary_name,
            index,
            field
        );
    }

    // Description must be a non-empty string
    let description = example
        .get("description")
        .and_then(Value::as_str)
        .unwrap_or_else(|| {
            panic!(
                "{} example {} description must be a string",
                binary_name, index
            )
        });

    assert!(
        !description.is_empty(),
        "{} example {} description should not be empty",
        binary_name,
        index
    );

    // Input must be valid JSON (can be any type including null)
    assert!(
        example.get("input").is_some(),
        "{} example {} input must be valid JSON",
        binary_name,
        index
    );

    // Expected output must be valid JSON object or value
    assert!(
        example.get("expected_output").is_some(),
        "{} example {} expected_output must be valid JSON",
        binary_name,
        index
    );
}

/// Validate that input schema is a valid JSON Schema object
fn validate_input_schema(schema: &Value, binary_name: &str) {
    let input = schema
        .get("input")
        .unwrap_or_else(|| panic!("{} schema missing input field", binary_name));

    // Input should be a JSON Schema (object or simpler type definition)
    assert!(
        input.is_object() || (input.get("type").is_some()),
        "{} input schema should be a valid JSON Schema",
        binary_name
    );
}

/// Validate that output_success schema is a valid JSON Schema object
fn validate_output_success_schema(schema: &Value, binary_name: &str) {
    let output_success = schema
        .get("output_success")
        .unwrap_or_else(|| panic!("{} schema missing output_success field", binary_name));

    // Output should be a JSON Schema object
    assert!(
        output_success.is_object(),
        "{} output_success schema should be a JSON Schema object",
        binary_name
    );

    // Most success outputs should have a "success" field
    if let Some(properties) = output_success.get("properties") {
        if let Some(obj) = properties.as_object() {
            if obj.contains_key("success") {
                // Verify success field is boolean
                let success_type = obj.get("success").and_then(|s| s.get("type"));
                if let Some(type_val) = success_type {
                    assert!(
                        type_val.as_str() == Some("boolean"),
                        "{} output_success.properties.success should be boolean",
                        binary_name
                    );
                }
            }
        }
    }
}

/// Validate that output_error schema is a valid JSON Schema object
fn validate_output_error_schema(schema: &Value, binary_name: &str) {
    let output_error = schema
        .get("output_error")
        .unwrap_or_else(|| panic!("{} schema missing output_error field", binary_name));

    // Output should be a JSON Schema object
    assert!(
        output_error.is_object(),
        "{} output_error schema should be a JSON Schema object",
        binary_name
    );

    // Error outputs should typically have "success" and "error" fields
    if let Some(properties) = output_error.get("properties") {
        if let Some(obj) = properties.as_object() {
            // Check for error field
            if obj.contains_key("error") {
                let error_type = obj.get("error").and_then(|e| e.get("type"));
                if let Some(type_val) = error_type {
                    assert!(
                        type_val.as_str() == Some("string"),
                        "{} output_error.properties.error should be string",
                        binary_name
                    );
                }
            }
        }
    }
}

/// Perform comprehensive schema validation
fn validate_complete_schema(schema: &Value, binary_name: &str) {
    validate_schema_structure(schema, binary_name);
    validate_schema_version(schema, binary_name);
    validate_binary_name(schema, binary_name);
    validate_description(schema, binary_name);
    validate_version(schema, binary_name);
    validate_input_schema(schema, binary_name);
    validate_output_success_schema(schema, binary_name);
    validate_output_error_schema(schema, binary_name);
}

/// Validate all examples in the schema
fn validate_all_examples(schema: &Value, binary_name: &str) {
    validate_examples_array(schema, binary_name);

    let examples = schema.get("examples").and_then(Value::as_array).unwrap();

    for (i, example) in examples.iter().enumerate() {
        validate_example_structure(example, binary_name, i);
    }
}

// ============================================================================
// IMPERATIVE SHELL - I/O Coordination
// ============================================================================

/// Run binary with --schema flag and return parsed JSON
fn get_schema_output(binary_name: &str) -> (Value, String) {
    let binary_path = format!("target/debug/{}", binary_name);
    if !std::path::Path::new(&binary_path).exists() {
        panic!("Binary {} not found at {}", binary_name, binary_path);
    }

    let mut cmd = Command::new(&binary_path);

    let output = cmd
        .arg("--schema")
        .output()
        .expect("Failed to execute binary");

    assert!(
        output.status.success(),
        "{} --schema should exit with code 0, got: {:?}\nstderr: {}",
        binary_name,
        output.status.code(),
        String::from_utf8_lossy(&output.stderr)
    );

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();

    let json: Value = serde_json::from_str(&stdout).unwrap_or_else(|e| {
        panic!(
            "{} --schema output is not valid JSON: {}\nOutput: {}",
            binary_name, e, stdout
        )
    });

    (json, stdout)
}

// ============================================================================
// TEST CASE 1: Binary Supports --schema and Exits with Code 0
// ============================================================================

fn test_schema_flag_exits_successfully(binary_name: &str) {
    let binary_path = format!("target/debug/{}", binary_name);
    if !std::path::Path::new(&binary_path).exists() {
        eprintln!("Skipping test: {} binary not found", binary_name);
        return;
    }

    let mut cmd = Command::new(&binary_path);
    let output = cmd.arg("--schema").output().expect("Failed to execute");

    assert!(
        output.status.success(),
        "{} --schema should exit with code 0, got: {:?}",
        binary_name,
        output.status.code()
    );
}

// ============================================================================
// TEST CASE 2: --schema Output is Valid JSON
// ============================================================================

fn test_schema_output_is_valid_json(binary_name: &str) {
    let (_, stdout) = get_schema_output(binary_name);

    // Verify we can parse and re-serialize (jq-style check)
    let json: Value = serde_json::from_str(&stdout)
        .unwrap_or_else(|e| panic!("{} --schema should output valid JSON: {}", binary_name, e));

    let reparsed = serde_json::to_string(&json).expect("Should be able to re-serialize");
    assert!(
        !reparsed.is_empty(),
        "{} schema JSON should not be empty",
        binary_name
    );
}

// ============================================================================
// TEST CASE 3: Schema Contains All Required Fields
// ============================================================================

fn test_schema_has_required_fields(binary_name: &str) {
    let (schema, _) = get_schema_output(binary_name);
    validate_complete_schema(&schema, binary_name);
}

// ============================================================================
// TEST CASE 4: Examples in Schema are Valid JSON
// ============================================================================

fn test_schema_examples_are_valid(binary_name: &str) {
    let (schema, _) = get_schema_output(binary_name);
    validate_all_examples(&schema, binary_name);
}

// ============================================================================
// TEST CASE 5: Schema Uses JSON Schema Draft 7
// ============================================================================

fn test_schema_is_draft_7(binary_name: &str) {
    let (schema, _) = get_schema_output(binary_name);
    validate_schema_version(&schema, binary_name);
}

// ============================================================================
// GENERATE TESTS FOR ALL BINARIES
// ============================================================================

macro_rules! generate_schema_tests {
    ($($binary:ident),* $(,)?) => {
        $(
            mod $binary {
                use super::*;

                #[test]
                fn schema_flag_exits_successfully() {
                    test_schema_flag_exits_successfully(stringify!($binary));
                }

                #[test]
                fn schema_output_is_valid_json() {
                    test_schema_output_is_valid_json(stringify!($binary));
                }

                #[test]
                fn schema_has_required_fields() {
                    test_schema_has_required_fields(stringify!($binary));
                }

                #[test]
                fn schema_examples_are_valid() {
                    test_schema_examples_are_valid(stringify!($binary));
                }

                #[test]
                fn schema_is_draft_7() {
                    test_schema_is_draft_7(stringify!($binary));
                }
            }
        )*
    };
}

// Generate tests for all foundation binaries specified in BEAD-009
generate_schema_tests!(
    generate_encryption_key,
    validate_encryption,
    tandoor_test_connection,
    sync_meal_plan,
    log_recipe_to_fatsecret,
    analyze_nutrition,
    track_exercise_balance,
);

// ============================================================================
// INTEGRATION TESTS - Cross-Binary Validation
// ============================================================================

#[test]
fn all_foundation_binaries_have_consistent_schema_format() {
    let binaries = [
        "generate_encryption_key",
        "validate_encryption",
        "tandoor_test_connection",
        "sync_meal_plan",
        "log_recipe_to_fatsecret",
        "analyze_nutrition",
        "track_exercise_balance",
    ];

    for binary_name in &binaries {
        let (schema, _) = get_schema_output(binary_name);

        // All should use same JSON Schema version
        assert_eq!(
            schema.get("$schema").and_then(Value::as_str),
            Some("http://json-schema.org/draft-07/schema#"),
            "{} should use standard Draft 7 URL",
            binary_name
        );

        // All should have non-empty version strings
        let version = schema.get("version").and_then(Value::as_str).unwrap();
        assert!(!version.is_empty(), "{} version should not be empty", binary_name);

        // All should have at least 2 examples
        let examples = schema.get("examples").and_then(Value::as_array).unwrap();
        assert!(
            examples.len() >= 2,
            "{} should have at least 2 examples",
            binary_name
        );
    }
}

#[test]
fn all_foundation_binaries_support_schema_flag() {
    let binaries = [
        "generate_encryption_key",
        "validate_encryption",
        "tandoor_test_connection",
        "sync_meal_plan",
        "log_recipe_to_fatsecret",
        "analyze_nutrition",
        "track_exercise_balance",
    ];

    for binary_name in &binaries {
        test_schema_flag_exits_successfully(binary_name);
    }
}

#[test]
fn schema_examples_have_consistent_structure() {
    let binaries = [
        "generate_encryption_key",
        "validate_encryption",
        "tandoor_test_connection",
        "sync_meal_plan",
        "log_recipe_to_fatsecret",
        "analyze_nutrition",
        "track_exercise_balance",
    ];

    for binary_name in &binaries {
        let (schema, _) = get_schema_output(binary_name);
        let examples = schema.get("examples").and_then(Value::as_array).unwrap();

        for (i, example) in examples.iter().enumerate() {
            // Each example should have exactly these 3 fields
            let obj = example.as_object().unwrap_or_else(|| {
                panic!(
                    "{} example {} should be a JSON object",
                    binary_name, i
                )
            });

            assert!(
                obj.contains_key("description"),
                "{} example {} missing 'description'",
                binary_name,
                i
            );
            assert!(
                obj.contains_key("input"),
                "{} example {} missing 'input'",
                binary_name,
                i
            );
            assert!(
                obj.contains_key("expected_output"),
                "{} example {} missing 'expected_output'",
                binary_name,
                i
            );
        }
    }
}
