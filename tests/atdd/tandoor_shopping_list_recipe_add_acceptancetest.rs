//! Acceptance test for tandoor_shopping_list_recipe_add binary
//!
//! Tests the full binary behavior: input parsing → API call → output serialization

use assert_cmd::Command;
use serde_json::json;

const BINARY_NAME: &str = "tandoor_shopping_list_recipe_add";

#[test]
fn test_accepts_valid_input_from_stdin() {
    let input = json!({
        "tandoor": {
            "base_url": "http://localhost:8090",
            "api_token": "test_token"
        },
        "mealplan_id": 123,
        "recipe_id": 456,
        "servings": 4.0
    });

    let mut cmd = Command::cargo_bin(BINARY_NAME).unwrap();
    cmd.write_stdin(input.to_string())
        .assert()
        .success();
}

#[test]
fn test_accepts_valid_input_from_cli_arg() {
    let input = json!({
        "tandoor": {
            "base_url": "http://localhost:8090",
            "api_token": "test_token"
        },
        "mealplan_id": 123,
        "recipe_id": 456,
        "servings": 4.0
    });

    let mut cmd = Command::cargo_bin(BINARY_NAME).unwrap();
    cmd.arg(input.to_string())
        .assert()
        .success();
}

#[test]
fn test_outputs_success_with_entries() {
    let input = json!({
        "tandoor": {
            "base_url": "http://localhost:8090",
            "api_token": "test_token"
        },
        "mealplan_id": 123,
        "recipe_id": 456,
        "servings": 4.0
    });

    let mut cmd = Command::cargo_bin(BINARY_NAME).unwrap();
    let output = cmd.write_stdin(input.to_string())
        .output()
        .expect("Failed to execute binary");

    assert!(output.status.success(), "Binary should succeed");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("\"success\":true"), "Output should indicate success");
}

#[test]
fn test_outputs_error_on_invalid_json() {
    let invalid_input = "{invalid json}";

    let mut cmd = Command::cargo_bin(BINARY_NAME).unwrap();
    let output = cmd.write_stdin(invalid_input.to_string())
        .output()
        .expect("Failed to execute binary");

    assert!(!output.status.success(), "Binary should fail on invalid JSON");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("\"success\":false"), "Output should indicate failure");
}

#[test]
fn test_outputs_error_on_missing_fields() {
    let incomplete_input = json!({
        "tandoor": {
            "base_url": "http://localhost:8090",
            "api_token": "test_token"
        }
        // missing mealplan_id, recipe_id, servings
    });

    let mut cmd = Command::cargo_bin(BINARY_NAME).unwrap();
    let output = cmd.write_stdin(incomplete_input.to_string())
        .output()
        .expect("Failed to execute binary");

    assert!(!output.status.success(), "Binary should fail on missing required fields");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("\"success\":false"), "Output should indicate failure");
}
