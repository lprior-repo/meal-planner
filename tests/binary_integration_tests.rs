//! Integration tests for `FatSecret` CLI binaries
//!
//! This module has been split into focused test files:
//! - tests/fatsecret/fatsecret_binary_existence_tests.rs - Binary existence tests
//! - tests/fatsecret/fatsecret_error_handling_tests.rs - Error handling tests
//! - tests/fatsecret/fatsecret_api_validation_tests.rs - Real API tests
//! - tests/windmill/windmill_scripts_tests.rs - Windmill script tests
//!
//! Run with: cargo test --test <test_file_name>
//!
//! Credentials are automatically loaded from:
//! 1. Environment variables (`FATSECRET_CONSUMER_KEY`, etc.)
//! 2. Windmill resources (u/admin/fatsecret_api)
//! 3. `pass` password manager (meal-planner/fatsecret/*)

#![allow(clippy::unwrap_used, clippy::indexing_slicing, clippy::panic)]

use std::io::Write;
use std::process::{Command, Stdio};
use serde_json::Value;

fn binary_exists(binary_name: &str) -> bool {
    let paths = [
        format!("./bin/{}", binary_name),
        format!("target/debug/{}", binary_name),
        format!("target/release/{}", binary_name),
    ];
    paths.iter().any(|p| std::path::Path::new(p).exists())
}

#[test]
fn test_invalid_json_handling() {
    let binaries = ["fatsecret_food_get", "fatsecret_foods_autocomplete"];

    for binary in binaries {
        if !binary_exists(binary) {
            continue;
        }

        let binary_path = format!("./bin/{}", binary);
        let mut child = Command::new(&binary_path)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .unwrap();

        if let Some(ref mut stdin) = child.stdin {
            stdin.write_all(b"not valid json").unwrap();
        }

        let output = child.wait_with_output().unwrap();
        let exit_code = output.status.code().unwrap_or(-1);
        let stdout = String::from_utf8_lossy(&output.stdout);

        assert_eq!(exit_code, 1, "{} should exit with code 1", binary);
        let parse_result: Result<Value, _> = serde_json::from_str(&stdout);
        assert!(
            parse_result.is_ok(),
            "{binary} should return valid JSON error, got: {stdout}"
        );
        let json_output = parse_result.unwrap();
        assert_eq!(json_output["success"], false);
    }
}
