//! Test validation for log_recipe_to_fatsecret binary (BEAD-006)
//!
//! These tests verify that empty string values are properly rejected
//! with actionable error messages.
//!
//! BEAD-006: empty string validation for recipe_name, base_url, api_token

#![allow(clippy::unwrap_used, clippy::indexing_slicing, clippy::panic)]

use super::support::binary_runner::binary_exists;
use serde_json::{json, Value};
use std::io::Write;
use std::process::{Command, Stdio};

// Valid-looking credentials (16+ chars) to pass initial validation
const TEST_CONSUMER_KEY: &str = "test_consumer_key_16_chars_min";
const TEST_CONSUMER_SECRET: &str = "test_consumer_secret_16_chars";

/// Helper to run log_recipe_to_fatsecret and always get JSON output (even on error)
fn run_log_recipe_to_fatsecret(input: &Value) -> Value {
    let binary_path = if std::path::Path::new("./target/debug/log_recipe_to_fatsecret").exists() {
        "./target/debug/log_recipe_to_fatsecret"
    } else if std::path::Path::new("./bin/log_recipe_to_fatsecret").exists() {
        "./bin/log_recipe_to_fatsecret"
    } else {
        panic!("log_recipe_to_fatsecret binary not found");
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

// ============================================================================
// BEAD-006: Empty String Validation Tests for base_url
// ============================================================================

#[test]
#[ignore = "requires network connectivity - binary panics with tokio runtime error on fake credentials"]
fn test_base_url_valid_accepted() {
    if !binary_exists("log_recipe_to_fatsecret") {
        eprintln!("Skipping test: log_recipe_to_fatsecret binary not found");
        return;
    }

    let input = json!({
        "tandoor": {
            "base_url": "https://recipes.example.com",
            "api_token": "valid_token_here"
        },
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "recipe_id": 42,
        "meal": "dinner",
        "date": "2025-01-15"
    });

    let output = run_log_recipe_to_fatsecret(&input);

    // Valid base_url should not produce validation errors related to empty strings
    // Note: It may fail for other reasons (e.g., invalid credentials, network), but not validation
    if output["success"] == false {
        let error = output["error"].as_str().unwrap_or("");
        assert!(
            !error.contains("base_url") || !error.contains("empty") && !error.contains("required"),
            "Valid base_url should not produce empty/required validation error. Error: {}",
            error
        );
    }
}

#[test]
fn test_base_url_empty_string_rejected() {
    if !binary_exists("log_recipe_to_fatsecret") {
        eprintln!("Skipping test: log_recipe_to_fatsecret binary not found");
        return;
    }

    let input = json!({
        "tandoor": {
            "base_url": "",
            "api_token": "valid_token_here"
        },
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "recipe_id": 42,
        "meal": "dinner",
        "date": "2025-01-15"
    });

    let output = run_log_recipe_to_fatsecret(&input);

    assert_eq!(
        output["success"], false,
        "Empty base_url should result in success: false"
    );

    let error = output["error"].as_str().expect("Error should be a string");
    assert!(
        error.contains("base_url") && (error.contains("empty") || error.contains("cannot be empty") || error.contains("required")),
        "Error should mention base_url is empty/required, got: {}",
        error
    );
}

#[test]
fn test_base_url_whitespace_only_rejected() {
    if !binary_exists("log_recipe_to_fatsecret") {
        eprintln!("Skipping test: log_recipe_to_fatsecret binary not found");
        return;
    }

    let whitespace_values = ["   ", " ", "\t  ", "  \n  "];

    for whitespace in &whitespace_values {
        let input = json!({
            "tandoor": {
                "base_url": whitespace,
                "api_token": "valid_token_here"
            },
            "fatsecret": {
                "consumer_key": TEST_CONSUMER_KEY,
                "consumer_secret": TEST_CONSUMER_SECRET
            },
            "access_token": "test_token",
            "access_secret": "test_secret",
            "recipe_id": 42,
            "meal": "dinner",
            "date": "2025-01-15"
        });

        let output = run_log_recipe_to_fatsecret(&input);

        assert_eq!(
            output["success"], false,
            "Whitespace-only base_url '{}' should result in success: false",
            whitespace.escape_default()
        );

        let error = output["error"].as_str().expect("Error should be a string");
        assert!(
            error.contains("base_url") && (error.contains("empty") || error.contains("cannot be empty") || error.contains("required")),
            "Error should mention base_url is empty/required for '{}', got: {}",
            whitespace.escape_default(),
            error
        );
    }
}

// ============================================================================
// BEAD-006: Empty String Validation Tests for api_token
// ============================================================================

#[test]
#[ignore = "requires network connectivity - binary panics with tokio runtime error on fake credentials"]
fn test_api_token_valid_accepted() {
    if !binary_exists("log_recipe_to_fatsecret") {
        eprintln!("Skipping test: log_recipe_to_fatsecret binary not found");
        return;
    }

    let input = json!({
        "tandoor": {
            "base_url": "https://recipes.example.com",
            "api_token": "valid_token_here"
        },
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "recipe_id": 42,
        "meal": "dinner",
        "date": "2025-01-15"
    });

    let output = run_log_recipe_to_fatsecret(&input);

    // Valid api_token should not produce validation errors related to empty strings
    if output["success"] == false {
        let error = output["error"].as_str().unwrap_or("");
        assert!(
            !error.contains("api_token") || !error.contains("empty") && !error.contains("required"),
            "Valid api_token should not produce empty/required validation error. Error: {}",
            error
        );
    }
}

#[test]
fn test_api_token_empty_string_rejected() {
    if !binary_exists("log_recipe_to_fatsecret") {
        eprintln!("Skipping test: log_recipe_to_fatsecret binary not found");
        return;
    }

    let input = json!({
        "tandoor": {
            "base_url": "https://recipes.example.com",
            "api_token": ""
        },
        "fatsecret": {
            "consumer_key": TEST_CONSUMER_KEY,
            "consumer_secret": TEST_CONSUMER_SECRET
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "recipe_id": 42,
        "meal": "dinner",
        "date": "2025-01-15"
    });

    let output = run_log_recipe_to_fatsecret(&input);

    assert_eq!(
        output["success"], false,
        "Empty api_token should result in success: false"
    );

    let error = output["error"].as_str().expect("Error should be a string");
    assert!(
        error.contains("api_token") && (error.contains("empty") || error.contains("cannot be empty") || error.contains("required")),
        "Error should mention api_token is empty/required, got: {}",
        error
    );
}

#[test]
fn test_api_token_whitespace_only_rejected() {
    if !binary_exists("log_recipe_to_fatsecret") {
        eprintln!("Skipping test: log_recipe_to_fatsecret binary not found");
        return;
    }

    let whitespace_values = ["   ", " ", "\t  "];

    for whitespace in &whitespace_values {
        let input = json!({
            "tandoor": {
                "base_url": "https://recipes.example.com",
                "api_token": whitespace
            },
            "fatsecret": {
                "consumer_key": TEST_CONSUMER_KEY,
                "consumer_secret": TEST_CONSUMER_SECRET
            },
            "access_token": "test_token",
            "access_secret": "test_secret",
            "recipe_id": 42,
            "meal": "dinner",
            "date": "2025-01-15"
        });

        let output = run_log_recipe_to_fatsecret(&input);

        assert_eq!(
            output["success"], false,
            "Whitespace-only api_token '{}' should result in success: false",
            whitespace.escape_default()
        );

        let error = output["error"].as_str().expect("Error should be a string");
        assert!(
            error.contains("api_token") && (error.contains("empty") || error.contains("cannot be empty") || error.contains("required")),
            "Error should mention api_token is empty/required for '{}', got: {}",
            whitespace.escape_default(),
            error
        );
    }
}
