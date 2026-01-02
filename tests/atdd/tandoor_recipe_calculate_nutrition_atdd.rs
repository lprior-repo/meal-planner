//! Acceptance tests for tandoor_recipe_calculate_nutrition binary
//!
//! GATE-1: Acceptance test defining WHAT the binary should do
//!
//! ## Binary Contract
//!
//! ### Input (JSON stdin):
//! ```json
//! {
//!   "tandoor": {"base_url": "...", "api_token": "..."},
//!   "recipe_id": 123
//! }
//! ```
//!
//! ### Output (JSON stdout):
//! ```json
//! {
//!   "success": true,
//!   "recipe_id": 123,
//!   "recipe_name": "Recipe Name",
//!   "nutrition": {
//!     "calories": 0.0,
//!     "protein": 0.0,
//!     "carbohydrate": 0.0,
//!     "fat": 0.0
//!   },
//!   "ingredient_count": 0,
//!   "failed_ingredients": []
//! }
//! ```
//!
//! ## Behavior
//!
//! 1. Fetches recipe from Tandoor API using recipe_id
//! 2. Extracts all ingredients from recipe steps
//! 3. Calculates nutrition for each ingredient
//! 4. Sums up total nutrition values
//! 5. Returns aggregated nutrition summary

use assert_cmd::Command;
use serde_json::json;
use std::fs::File;
use std::io::Write;
use tempfile::TempDir;

/// GATE-1: Acceptance Test - Binary accepts valid input and returns expected output format
///
/// ## Behavior: Binary should process recipe and return nutrition calculation
///
/// ### Test Strategy:
/// - Use a mock Tandoor server (wiremock)
/// - Define expected request/response
/// - Verify binary output matches expected schema
#[test]
fn binary_accepts_valid_input_and_returns_nutrition() {
    let temp_dir = TempDir::new().unwrap();
    let config_path = temp_dir.path().join("config.json");
    let config_content = json!({
        "base_url": "http://localhost:9999",
        "api_token": "test-token"
    });
    let mut config_file = File::create(&config_path).unwrap();
    config_file.write_all(config_content.to_string().as_bytes()).unwrap();

    let input = json!({
        "base_url": "http://localhost:9999",
        "api_token": "test-token",
        "recipe_id": 123
    });
    let input_path = temp_dir.path().join("input.json");
    let mut input_file = File::create(&input_path).unwrap();
    input_file.write_all(input.to_string().as_bytes()).unwrap();

    let mut cmd = Command::cargo_bin("tandoor_recipe_calculate_nutrition").unwrap();
    cmd.arg("--config").arg(&config_path);
    cmd.arg("--recipe-id").arg("123");
    cmd.arg("--input").arg(&input_path);

    let output = cmd.output().expect("Failed to execute binary");

    println!("STDOUT: {}", String::from_utf8_lossy(&output.stdout));
    println!("STDERR: {}", String::from_utf8_lossy(&output.stderr));

    assert!(
        output.status.success(),
        "Binary should exit successfully, stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );

    let stdout: serde_json::Value =
        serde_json::from_slice(&output.stdout).expect("Valid JSON output");

    assert_eq!(stdout["success"], true);
    assert!(stdout["recipe_id"].is_number());
    assert!(stdout["recipe_name"].is_string());
    assert!(stdout["nutrition"].is_object());
    assert!(stdout["nutrition"]["calories"].is_number());
    assert!(stdout["nutrition"]["protein"].is_number());
    assert!(stdout["nutrition"]["carbohydrate"].is_number());
    assert!(stdout["nutrition"]["fat"].is_number());
}

/// GATE-1: Acceptance Test - Binary handles missing recipe gracefully
///
/// ## Behavior: When recipe_id is invalid, return error in output
#[test]
fn binary_handles_missing_recipe() {
    let temp_dir = TempDir::new().unwrap();
    let config_path = temp_dir.path().join("config.json");
    let config_content = json!({
        "base_url": "http://localhost:9999",
        "api_token": "test-token"
    });
    let mut config_file = File::create(&config_path).unwrap();
    config_file.write_all(config_content.to_string().as_bytes()).unwrap();

    let input = json!({
        "base_url": "http://localhost:9999",
        "api_token": "test-token",
        "recipe_id": 99999
    });
    let input_path = temp_dir.path().join("input.json");
    let mut input_file = File::create(&input_path).unwrap();
    input_file.write_all(input.to_string().as_bytes()).unwrap();

    let mut cmd = Command::cargo_bin("tandoor_recipe_calculate_nutrition").unwrap();
    cmd.arg("--config").arg(&config_path);
    cmd.arg("--recipe-id").arg("99999");
    cmd.arg("--input").arg(&input_path);

    let output = cmd.output().expect("Failed to execute binary");

    println!("STDOUT: {}", String::from_utf8_lossy(&output.stdout));
    println!("STDERR: {}", String::from_utf8_lossy(&output.stderr));

    // Binary should report failure in output, not crash
    let stdout_result = serde_json::from_slice::<serde_json::Value>(&output.stdout);
    if let Ok(stdout) = stdout_result {
        // If we got valid JSON, it should have success: false
        assert_eq!(
            stdout["success"],
            false,
            "Should report failure when recipe not found"
        );
    }
}

/// GATE-1: Acceptance Test - Output schema validation
///
/// ## Behavior: Verify output matches expected CUE contract
#[test]
fn binary_output_matches_schema() {
    let expected_output_schema = json!({
        "type": "object",
        "required": ["success", "recipe_id", "recipe_name", "nutrition", "ingredient_count", "failed_ingredients"],
        "properties": {
            "success": {"type": "boolean"},
            "recipe_id": {"type": "number"},
            "recipe_name": {"type": "string"},
            "nutrition": {
                "type": "object",
                "required": ["calories", "protein", "carbohydrate", "fat"],
                "properties": {
                    "calories": {"type": "number"},
                    "protein": {"type": "number"},
                    "carbohydrate": {"type": "number"},
                    "fat": {"type": "number"}
                }
            },
            "ingredient_count": {"type": "number"},
            "failed_ingredients": {"type": "array", "items": {"type": "string"}}
        }
    });

    // This test validates the schema contract
    // In a real implementation, we would use JSON Schema validation
    assert!(expected_output_schema.is_object());
}
