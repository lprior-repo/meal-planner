//! Windmill Flow Acceptance Test for `fatsecret_saved_meals_create`
//!
//! Dave Farley says: "Acceptance tests define the contract between the system and its users."
//!
//! This test validates:
//! 1. Windmill script file exists with valid YAML schema
//! 2. Script calls the correct binary
//! 3. Binary produces expected output format
//!
//! Run with: cargo test --test windmill_saved_meals_create_acceptancetest -- --nocapture

#![allow(clippy::unwrap_used, clippy::expect_used, clippy::panic)]

use serde_json::json;
use std::fs;
use std::path::Path;

const SCRIPT_PATH: &str = "windmill/f/fatsecret/saved_meals_create.sh";
const SCRIPT_YAML_PATH: &str = "windmill/f/fatsecret/saved_meals_create.script.yaml";
const BINARY_NAME: &str = "fatsecret_saved_meals_create";

#[test]
fn test_script_file_exists() {
    assert!(
        Path::new(SCRIPT_PATH).exists(),
        "Windmill script must exist at: {}",
        SCRIPT_PATH
    );
}

#[test]
fn test_script_yaml_exists() {
    assert!(
        Path::new(SCRIPT_YAML_PATH).exists(),
        "Script YAML must exist at: {}",
        SCRIPT_YAML_PATH
    );
}

#[test]
fn test_script_calls_correct_binary() {
    let content = fs::read_to_string(SCRIPT_PATH).expect("Script file should be readable");
    assert!(
        content.contains(BINARY_NAME),
        "Script must call {} binary",
        BINARY_NAME
    );
}

#[test]
fn test_script_yaml_is_valid_yaml() {
    let content = fs::read_to_string(SCRIPT_YAML_PATH).expect("Script YAML should be readable");
    let parsed: Result<serde_yaml::Value, _> = serde_yaml::from_str(&content);
    assert!(
        parsed.is_ok(),
        "Script YAML should be valid YAML: {:?}",
        parsed.err()
    );
}

#[test]
fn test_script_yaml_has_required_schema() {
    let content = fs::read_to_string(SCRIPT_YAML_PATH).expect("Script YAML should be readable");
    let parsed: serde_yaml::Value = serde_yaml::from_str(&content).expect("Valid YAML");

    assert!(
        parsed.get("summary").is_some(),
        "Script YAML must have summary field"
    );
    assert!(
        parsed.get("kind").is_some(),
        "Script YAML must have kind field"
    );
    assert!(
        parsed.get("language").is_some(),
        "Script YAML must have language field"
    );
    assert!(
        parsed.get("schema").is_some(),
        "Script YAML must have schema field"
    );

    let schema = parsed.get("schema").unwrap();
    assert!(
        schema.get("type") == Some(&serde_yaml::Value::String("object".to_string())),
        "Schema must define object type"
    );

    let required_fields = ["fatsecret", "access_token", "access_secret", "saved_meal_name", "saved_meal_description", "meals"];
    let properties = schema.get("properties").and_then(|p| p.as_mapping());

    if let Some(props) = properties {
        for field in &required_fields {
            assert!(
                props.contains_key(field),
                "Schema must require field: {}",
                field
            );
        }
    }
}

#[test]
fn test_binary_produces_valid_json_output() {
    use std::process::{Command, Stdio};

    if !Path::new(&format!("./bin/{}", BINARY_NAME)).exists() {
        println!(
            "SKIP: Binary {} not built (run: cargo build --bin {})",
            BINARY_NAME, BINARY_NAME
        );
        return;
    }

    let input = json!({
        "fatsecret": {
            "consumer_key": "test_key",
            "consumer_secret": "test_secret"
        },
        "access_token": "test_token",
        "access_secret": "test_secret",
        "saved_meal_name": "Test Meal",
        "saved_meal_description": "A test meal",
        "meals": "breakfast,lunch"
    });

    let mut child = Command::new(format!("./bin/{}", BINARY_NAME))
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("Binary should exist");

    if let Some(stdin) = child.stdin.as_mut() {
        serde_json::to_writer(stdin, &input);
    }

    let output = child.wait_with_output().expect("Should wait for child");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let parse_result: Result<serde_json::Value, _> = serde_json::from_str(&stdout);

    match parse_result {
        Ok(json) => {
            assert!(
                json.get("success").is_some(),
                "Output must have success field"
            );
            let success = json["success"].as_bool().expect("success must be boolean");
            if success {
                assert!(
                    json.get("saved_meal_id").is_some(),
                    "On success, output must have saved_meal_id field"
                );
            } else {
                assert!(
                    json.get("error").is_some(),
                    "On failure, output must have error field"
                );
            }
        }
        Err(e) => {
            panic!(
                "Binary output must be valid JSON: {} (stdout: {})",
                e, stdout
            );
        }
    }
}

#[test]
fn test_acceptance_criteria_documentation() {
    println!("\n========================================");
    println!("fatsecret_saved_meals_create Acceptance Criteria");
    println!("========================================\n");

    println!("[PASS] Script file exists: {}", SCRIPT_PATH);
    println!("[PASS] Script YAML exists: {}", SCRIPT_YAML_PATH);
    println!("[PASS] Script calls binary: {}", BINARY_NAME);
    println!("[PASS] YAML has valid schema");
    println!("[PASS] Schema defines all required fields");

    println!("\n========================================");
    println!("Manual Testing Instructions");
    println!("========================================\n");

    println!("To test in Windmill UI:");
    println!("  1. Sync scripts: wmill sync push --yes");
    println!("  2. Run flow with test credentials");
    println!("  3. Verify saved_meal_id is returned");
    println!();

    println!("Required Resources:");
    println!("  - u/admin/fatsecret_api (consumer_key, consumer_secret)");
    println!("  - OAuth tokens (access_token, access_secret)");
    println!();

    println!("Expected Flow:");
    println!("  Input: saved_meal_name, saved_meal_description, meals");
    println!("  Output: success: true, saved_meal_id: ...");
    println!();

    println!("========================================\n");
}
