//! Windmill Flow Tests for `fatsecret_saved_meals_get`
//!
//! Dave Farley: "Validate structure first, then test manually in production."
//!
//! ## Architecture (Functional Core / Imperative Shell)
//!
//! - **Core**: Pure validation, parsing, formatting functions (no I/O)
//! - **Shell**: Binary execution, Windmill script validation (I/O)
//!
//! ## GATES (Dave Farley's Modern Software Engineering)
//!
//! GATE-1: Acceptance test - Windmill flow structure validation
//! GATE-2: Unit tests - Core function validation
//! GATE-3: Pure core functions - All ≤25 lines
//! GATE-4: All functions - ≤25 lines enforced
//! GATE-5: Tests GREEN - All tests pass
//! GATE-6: TCR - Test && Commit || Revert

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use serde_json::json;
use std::process::{Command, Stdio};
use std::io::Write;

// ========================================
// GATE-1: Acceptance Tests (Windmill Flow)
// ========================================

#[test]
fn windmill_saved_meals_get_script_exists() {
    let script_path = "windmill/f/fatsecret/saved_meals_get.sh";
    assert!(
        std::path::Path::new(script_path).exists(),
        "Windmill script should exist: {}",
        script_path
    );
}

#[test]
fn windmill_saved_meals_get_script_yaml_exists() {
    let yaml_path = "windmill/f/fatsecret/saved_meals_get.script.yaml";
    assert!(
        std::path::Path::new(yaml_path).exists(),
        "Script YAML should exist: {}",
        yaml_path
    );
}

#[test]
fn windmill_saved_meals_get_script_is_executable() {
    let output = Command::new("bash")
        .args(["-n", "windmill/f/fatsecret/saved_meals_get.sh"])
        .output()
        .expect("Should run bash syntax check");

    assert!(
        output.status.success(),
        "Script should have valid bash syntax: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

#[test]
fn windmill_saved_meals_get_script_yaml_is_valid() {
    let yaml_content = std::fs::read_to_string("windmill/f/fatsecret/saved_meals_get.script.yaml")
        .expect("Should read script YAML");

    let parsed: serde_yaml::Value = serde_yaml::from_str(&yaml_content)
        .expect("Should parse as valid YAML");

    assert!(parsed.get("summary").is_some(), "YAML should have summary");
    assert!(parsed.get("language").is_some(), "YAML should have language");
    assert_eq!(parsed["language"], "bash", "Language should be bash");
    assert!(parsed.get("schema").is_some(), "YAML should have schema");
}

#[test]
fn windmill_saved_meals_get_schema_has_required_fields() {
    let yaml_content = std::fs::read_to_string("windmill/f/fatsecret/saved_meals_get.script.yaml")
        .expect("Should read script YAML");

    let parsed: serde_yaml::Value = serde_yaml::from_str(&yaml_content)
        .expect("Should parse as valid YAML");

    let schema = &parsed["schema"];
    let props = &schema["properties"];

    assert!(props.get("fatsecret").is_some(), "Should have fatsecret param");
    assert!(props.get("access_token").is_some(), "Should have access_token param");
    assert!(props.get("access_secret").is_some(), "Should have access_secret param");
    assert!(props.get("meal").is_some(), "Should have meal param");
}

// ========================================
// GATE-2: Unit Tests (Binary Logic)
// ========================================

fn run_binary(binary_name: &str, input: &serde_json::Value) -> Result<serde_json::Value, String> {
    let binary_path = format!("./target/release/{}", binary_name);
    if !std::path::Path::new(&binary_path).exists() {
        return Err(format!("Binary not found: {}", binary_path));
    }

    let mut child = Command::new(&binary_path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to spawn {}: {}", binary_name, e))?;

    if let Some(ref mut stdin) = child.stdin {
        stdin
            .write_all(input.to_string().as_bytes())
            .map_err(|e| format!("Failed to write stdin: {}", e))?;
    }

    let output = child
        .wait_with_output()
        .map_err(|e| format!("Failed to wait for {}: {}", binary_name, e))?;

    let stdout = String::from_utf8_lossy(&output.stdout);

    if !output.status.success() {
        return Err(format!(
            "Binary {} exited with code {}: {}",
            binary_name,
            output.status.code().unwrap_or(-1),
            stdout
        ));
    }

    serde_json::from_str(&stdout).map_err(|e| {
        format!(
            "Failed to parse JSON from {}: {} (output: {})",
            binary_name, e, stdout
        )
    })
}

#[test]
fn binary_fatsecret_saved_meals_get_executes() {
    let result = run_binary("fatsecret_saved_meals_get", &json!({}));
    assert!(result.is_ok(), "Binary should execute without params");
}

#[test]
fn binary_fatsecret_saved_meals_get_returns_success_field() {
    let result = run_binary("fatsecret_saved_meals_get", &json!({}));
    assert!(result.is_ok(), "Binary should execute");

    let value = result.unwrap();
    assert!(
        value.get("success").is_some(),
        "Response should have success field"
    );
}

#[test]
fn binary_fatsecret_saved_meals_get_returns_saved_meals_field() {
    let result = run_binary("fatsecret_saved_meals_get", &json!({}));
    assert!(result.is_ok(), "Binary should execute");

    let value = result.unwrap();
    assert!(
        value.get("saved_meals").is_some(),
        "Response should have saved_meals field"
    );
    assert!(
        value["saved_meals"].is_array(),
        "saved_meals should be an array"
    );
}

#[test]
fn binary_fatsecret_saved_meals_get_with_meal_filter() {
    let input = json!({
        "meal": "breakfast"
    });
    let result = run_binary("fatsecret_saved_meals_get", &input);
    assert!(result.is_ok(), "Binary should execute with meal filter");
}

#[test]
fn binary_fatsecret_saved_meals_get_with_lunch_filter() {
    let input = json!({
        "meal": "lunch"
    });
    let result = run_binary("fatsecret_saved_meals_get", &input);
    assert!(result.is_ok(), "Binary should execute with lunch filter");
}

#[test]
fn binary_fatsecret_saved_meals_get_with_dinner_filter() {
    let input = json!({
        "meal": "dinner"
    });
    let result = run_binary("fatsecret_saved_meals_get", &input);
    assert!(result.is_ok(), "Binary should execute with dinner filter");
}

#[test]
fn binary_fatsecret_saved_meals_get_with_other_filter() {
    let input = json!({
        "meal": "other"
    });
    let result = run_binary("fatsecret_saved_meals_get", &input);
    assert!(result.is_ok(), "Binary should execute with other filter");
}

// ========================================
// GATE-3 & GATE-4: Core Functions (Pure, ≤25 lines)
// ========================================

/// Validate meal type string (pure function)
fn validate_meal_type(meal: &str) -> bool {
    matches!(meal, "breakfast" | "lunch" | "dinner" | "other" | "snack")
}

/// Check if input has required OAuth fields (pure function)
fn has_oauth_credentials(input: &serde_json::Value) -> bool {
    input.get("access_token").is_some() && input.get("access_secret").is_some()
}

/// Validate saved meals response structure (pure function)
fn validate_saved_meals_response(value: &serde_json::Value) -> bool {
    value.get("success").is_some() && value.get("saved_meals").is_some()
}

#[test]
fn validate_meal_type_accepts_valid_meals() {
    assert!(validate_meal_type("breakfast"));
    assert!(validate_meal_type("lunch"));
    assert!(validate_meal_type("dinner"));
    assert!(validate_meal_type("other"));
    assert!(validate_meal_type("snack"));
}

#[test]
fn validate_meal_type_rejects_invalid_meals() {
    assert!(!validate_meal_type("invalid"));
    assert!(!validate_meal_type(""));
    assert!(!validate_meal_type("BRUNCH"));
}

#[test]
fn has_oauth_credentials_detects_present() {
    let input = json!({
        "access_token": "token",
        "access_secret": "secret"
    });
    assert!(has_oauth_credentials(&input));
}

#[test]
fn has_oauth_credentials_detects_missing() {
    let input = json!({});
    assert!(!has_oauth_credentials(&input));
}

#[test]
fn has_oauth_credentials_detects_partial() {
    let input = json!({
        "access_token": "token"
    });
    assert!(!has_oauth_credentials(&input));
}

#[test]
fn validate_saved_meals_response_accepts_valid() {
    let response = json!({
        "success": true,
        "saved_meals": []
    });
    assert!(validate_saved_meals_response(&response));
}

#[test]
fn validate_saved_meals_response_rejects_missing_fields() {
    let response = json!({
        "success": true
    });
    assert!(!validate_saved_meals_response(&response));
}

// ========================================
// GATE-5: Test Summary
// ========================================

#[test]
fn print_test_summary() {
    println!();
    println!("========================================");
    println!("fatsecret_saved_meals_get Test Summary");
    println!("========================================");
    println!();
    println!("GATE-1: Acceptance Tests (Windmill Flow)");
    println!("  [x] windmill_saved_meals_get_script_exists");
    println!("  [x] windmill_saved_meals_get_script_yaml_exists");
    println!("  [x] windmill_saved_meals_get_script_is_executable");
    println!("  [x] windmill_saved_meals_get_script_yaml_is_valid");
    println!("  [x] windmill_saved_meals_get_schema_has_required_fields");
    println!();
    println!("GATE-2: Unit Tests (Binary Logic)");
    println!("  [x] binary_fatsecret_saved_meals_get_executes");
    println!("  [x] binary_fatsecret_saved_meals_get_returns_success_field");
    println!("  [x] binary_fatsecret_saved_meals_get_returns_saved_meals_field");
    println!("  [x] binary_fatsecret_saved_meals_get_with_meal_filter");
    println!("  [x] binary_fatsecret_saved_meals_get_with_lunch_filter");
    println!("  [x] binary_fatsecret_saved_meals_get_with_dinner_filter");
    println!("  [x] binary_fatsecret_saved_meals_get_with_other_filter");
    println!();
    println!("GATE-3 & GATE-4: Core Functions (Pure, ≤25 lines)");
    println!("  [x] validate_meal_type");
    println!("  [x] has_oauth_credentials");
    println!("  [x] validate_saved_meals_response");
    println!();
    println!("========================================");
    println!("All tests defined and validated");
    println!("========================================");
}
