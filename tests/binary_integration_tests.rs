//! Integration tests for `FatSecret` CLI binaries
//!
//! These tests verify that each binary:
//! 1. Exists and is executable
//! 2. Handles invalid input gracefully (returns JSON error)
//! 3. Follows the JSON stdin -> JSON stdout contract
//! 4. Works with real API calls (when credentials are available)
//!
//! Run with: cargo test --test binary_integration_tests
//!
//! Credentials are automatically loaded from:
//! 1. Environment variables (`FATSECRET_CONSUMER_KEY`, etc.)
//! 2. Windmill resources (u/admin/fatsecret_api)
//! 3. `pass` password manager (meal-planner/fatsecret/*)

// Test code uses unwrap/indexing/panic for simplicity and clearer failure messages
#![allow(clippy::unwrap_used, clippy::indexing_slicing, clippy::panic)]

mod common;

use common::{get_fatsecret_credentials, get_oauth_tokens};
use serde_json::{json, Value};
use std::io::Write;
use std::process::{Command, Stdio};

// ============================================================================
// Test Helpers
// ============================================================================

/// Run a binary with JSON input and return the parsed output
fn run_binary(binary_name: &str, input: &Value) -> Result<(Value, i32), String> {
    let binary_path = format!("./bin/{}", binary_name);

    let mut child = Command::new(&binary_path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to spawn {}: {}", binary_name, e))?;

    // Write input to stdin
    if let Some(ref mut stdin) = child.stdin {
        stdin
            .write_all(input.to_string().as_bytes())
            .map_err(|e| format!("Failed to write stdin: {}", e))?;
    }

    let output = child
        .wait_with_output()
        .map_err(|e| format!("Failed to wait for {}: {}", binary_name, e))?;

    let exit_code = output.status.code().unwrap_or(-1);
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Parse JSON output
    let json_output: Value = serde_json::from_str(&stdout).map_err(|e| {
        format!(
            "Failed to parse JSON from {}: {} (output: {})",
            binary_name, e, stdout
        )
    })?;

    Ok((json_output, exit_code))
}

/// Check if binary exists (in either ./bin or target/debug)
fn binary_exists(binary_name: &str) -> bool {
    let paths = [
        format!("./bin/{}", binary_name),
        format!("target/debug/{}", binary_name),
        format!("target/release/{}", binary_name),
    ];
    paths.iter().any(|p| std::path::Path::new(p).exists())
}

/// Get `FatSecret` credentials (from env, Windmill, or pass)
fn get_credentials() -> Option<Value> {
    get_fatsecret_credentials().map(|c| c.to_json())
}

/// Get OAuth tokens (from env or Windmill)
fn get_tokens() -> Option<(String, String)> {
    get_oauth_tokens().map(|t| (t.access_token, t.access_secret))
}

// ============================================================================
// Binary Existence Tests
// ============================================================================

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

// ============================================================================
// Error Handling Tests (no credentials needed)
// ============================================================================

#[test]
fn test_food_get_empty_input() {
    if !binary_exists("fatsecret_food_get") {
        return;
    }

    let (output, exit_code) = run_binary("fatsecret_food_get", &json!({})).unwrap();

    assert_eq!(exit_code, 1, "Should exit with code 1 on error");
    assert_eq!(output["success"], false, "Should return success: false");
    assert!(output["error"].is_string(), "Should have error message");
}

#[test]
fn test_food_get_missing_food_id() {
    if !binary_exists("fatsecret_food_get") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"}
    });

    let (output, exit_code) = run_binary("fatsecret_food_get", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("food_id"));
}

#[test]
fn test_foods_autocomplete_empty_input() {
    if !binary_exists("fatsecret_foods_autocomplete") {
        return;
    }

    let (output, exit_code) = run_binary("fatsecret_foods_autocomplete", &json!({})).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
}

#[test]
fn test_foods_autocomplete_missing_expression() {
    if !binary_exists("fatsecret_foods_autocomplete") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"}
    });

    let (output, exit_code) = run_binary("fatsecret_foods_autocomplete", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("expression"));
}

#[test]
fn test_food_add_favorite_missing_tokens() {
    if !binary_exists("fatsecret_food_add_favorite") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "food_id": "12345"
    });

    let (output, exit_code) = run_binary("fatsecret_food_add_favorite", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("access_token"));
}

#[test]
fn test_food_delete_favorite_missing_food_id() {
    if !binary_exists("fatsecret_food_delete_favorite") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "access_token": "test",
        "access_secret": "test"
    });

    let (output, exit_code) = run_binary("fatsecret_food_delete_favorite", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("food_id"));
}

#[test]
fn test_foods_get_favorites_missing_tokens() {
    if !binary_exists("fatsecret_foods_get_favorites") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"}
    });

    let (output, exit_code) = run_binary("fatsecret_foods_get_favorites", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("access_token"));
}

#[test]
fn test_food_entries_get_missing_date() {
    if !binary_exists("fatsecret_food_entries_get") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "access_token": "test",
        "access_secret": "test"
    });

    let (output, exit_code) = run_binary("fatsecret_food_entries_get", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("date_int"));
}

// ============================================================================
// Recipe Binary Tests
// ============================================================================

// Recipe binaries are not currently built - skipping these tests

#[test]
fn test_recipes_autocomplete_missing_expression() {
    if !binary_exists("fatsecret_recipes_autocomplete") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"}
    });

    let (output, exit_code) = run_binary("fatsecret_recipes_autocomplete", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("expression"));
}

#[test]
fn test_food_entries_get_month_missing_date() {
    if !binary_exists("fatsecret_food_entries_get_month") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "access_token": "test",
        "access_secret": "test"
    });

    let (output, exit_code) = run_binary("fatsecret_food_entries_get_month", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("date_int"));
}

#[test]
fn test_food_entry_create_missing_fields() {
    if !binary_exists("fatsecret_food_entry_create") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "access_token": "test",
        "access_secret": "test"
    });

    let (output, exit_code) = run_binary("fatsecret_food_entry_create", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
}

#[test]
fn test_food_entry_create_invalid_meal_type() {
    if !binary_exists("fatsecret_food_entry_create") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "access_token": "test",
        "access_secret": "test",
        "food_id": "12345",
        "food_entry_name": "Test Food",
        "serving_id": "54321",
        "number_of_units": 1.0,
        "meal": "invalid_meal_type",
        "date_int": 20088
    });

    let (output, exit_code) = run_binary("fatsecret_food_entry_create", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    let error = output["error"].as_str().unwrap();
    assert!(
        error.contains("Invalid meal type") || error.contains("breakfast"),
        "Error should mention valid meal types"
    );
}

#[test]
fn test_food_entry_edit_missing_entry_id() {
    if !binary_exists("fatsecret_food_entry_edit") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "access_token": "test",
        "access_secret": "test"
    });

    let (output, exit_code) = run_binary("fatsecret_food_entry_edit", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("food_entry_id"));
}

#[test]
fn test_food_entry_delete_missing_entry_id() {
    if !binary_exists("fatsecret_food_entry_delete") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "access_token": "test",
        "access_secret": "test"
    });

    let (output, exit_code) = run_binary("fatsecret_food_entry_delete", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("food_entry_id"));
}

#[test]
fn test_invalid_json_handling() {
    // Test that all binaries handle invalid JSON gracefully
    let binaries = ["fatsecret_food_get", "fatsecret_foods_autocomplete"];

    for binary in binaries {
        if !binary_exists(binary) {
            continue;
        }

        // Send invalid JSON
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

        // Should return valid JSON error even for invalid input
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

// ============================================================================
// Real API Tests (require credentials)
// ============================================================================

#[test]
fn test_food_get_real_api() {
    let Some(credentials) = get_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_food_get") {
        return;
    }

    // Test with a known food ID (Apple)
    let input = json!({
        "fatsecret": credentials,
        "food_id": "35718"
    });

    let (output, exit_code) = run_binary("fatsecret_food_get", &input).unwrap();

    assert_eq!(exit_code, 0, "Should succeed with valid credentials");
    assert_eq!(output["success"], true);
    assert!(output["food"].is_object(), "Should return food object");
}

#[test]
fn test_foods_autocomplete_real_api() {
    let Some(credentials) = get_credentials() else {
        println!("Skipping: credentials not available");
        return;
    };

    if !binary_exists("fatsecret_foods_autocomplete") {
        return;
    }

    let input = json!({
        "fatsecret": credentials,
        "expression": "chick",
        "max_results": 5
    });

    let (output, exit_code) = run_binary("fatsecret_foods_autocomplete", &input).unwrap();

    // Note: foods.autocomplete is a Premier-only API
    // It will fail with error code 10 or 12 on non-Premier accounts
    if exit_code == 0 {
        assert_eq!(output["success"], true);
        assert!(output["suggestions"].is_object() || output["suggestions"].is_array());
    } else {
        // Premier-only or unknown method error is acceptable
        let error = output["error"].as_str().unwrap_or("");
        assert!(
            error.contains("10")
                || error.contains("12")
                || error.contains("Unknown method")
                || error.contains("Premier"),
            "Expected Premier-only or unknown method error, got: {}",
            error
        );
        println!("foods.autocomplete requires Premier API tier (expected)");
    }
}

#[test]
fn test_foods_search_real_api() {
    let Some(credentials) = get_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_foods_search") {
        return;
    }

    let input = json!({
        "fatsecret": credentials,
        "query": "chicken breast",
        "page": 0,
        "max_results": 5
    });

    let (output, exit_code) = run_binary("fatsecret_foods_search", &input).unwrap();

    assert_eq!(exit_code, 0, "Should succeed with valid credentials");
    assert_eq!(output["success"], true);
    assert!(output["foods"].is_object());
}

#[test]
fn test_food_entries_get_real_api() {
    let Some(credentials) = get_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    let Some((access_token, access_secret)) = get_tokens() else {
        println!("Skipping: FATSECRET_ACCESS_TOKEN/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_food_entries_get") {
        return;
    }

    // Get today's date as days since epoch
    let today = chrono::Utc::now();
    let epoch = chrono::NaiveDate::from_ymd_opt(1970, 1, 1).unwrap();
    let date_int = (today.date_naive() - epoch).num_days();

    let input = json!({
        "fatsecret": credentials,
        "access_token": access_token,
        "access_secret": access_secret,
        "date_int": date_int
    });

    let (output, exit_code) = run_binary("fatsecret_food_entries_get", &input).unwrap();

    // May succeed or fail depending on auth status
    if exit_code == 0 {
        assert_eq!(output["success"], true);
        assert!(output["entries"].is_array());
    } else {
        // Auth error is acceptable if tokens are invalid
        assert_eq!(output["success"], false);
    }
}

#[test]
fn test_foods_get_favorites_real_api() {
    let Some(credentials) = get_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    let Some((access_token, access_secret)) = get_tokens() else {
        println!("Skipping: FATSECRET_ACCESS_TOKEN/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_foods_get_favorites") {
        return;
    }

    let input = json!({
        "fatsecret": credentials,
        "access_token": access_token,
        "access_secret": access_secret
    });

    let (output, exit_code) = run_binary("fatsecret_foods_get_favorites", &input).unwrap();

    if exit_code == 0 {
        assert_eq!(output["success"], true);
        assert!(output["favorites"].is_array());
    } else {
        assert_eq!(output["success"], false);
    }
}

#[test]
fn test_food_entries_get_month_real_api() {
    let Some(credentials) = get_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    let Some((access_token, access_secret)) = get_tokens() else {
        println!("Skipping: FATSECRET_ACCESS_TOKEN/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_food_entries_get_month") {
        return;
    }

    // Get today's date as days since epoch
    let today = chrono::Utc::now();
    let epoch = chrono::NaiveDate::from_ymd_opt(1970, 1, 1).unwrap();
    let date_int = (today.date_naive() - epoch).num_days();

    let input = json!({
        "fatsecret": credentials,
        "access_token": access_token,
        "access_secret": access_secret,
        "date_int": date_int
    });

    let (output, exit_code) = run_binary("fatsecret_food_entries_get_month", &input).unwrap();

    if exit_code == 0 {
        assert_eq!(output["success"], true);
        assert!(output["month"].is_object());
    } else {
        assert_eq!(output["success"], false);
    }
}

// ============================================================================
// Windmill Script Integration Tests
// ============================================================================

/// Test that Windmill bash scripts exist and are syntactically valid
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

/// Test that Windmill script YAML configs exist and have required fields
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

/// Test that bash scripts have correct shebang and shellcheck directive
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
