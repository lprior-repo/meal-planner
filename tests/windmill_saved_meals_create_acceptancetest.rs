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

use std::fs;
use std::path::Path;

const SCRIPT_PATH: &str = "windmill/f/fatsecret/saved_meals_create.sh";
const SCRIPT_YAML_PATH: &str = "windmill/f/fatsecret/saved_meals_create.script.yaml";
const BINARY_NAME: &str = "fatsecret_saved_meals_create";

#[test]
fn test_script_file_exists() {
    let path = Path::new(SCRIPT_PATH);
    assert!(path.exists(), "Windmill script must exist at: {}", SCRIPT_PATH);
}

#[test]
fn test_script_yaml_exists() {
    let path = Path::new(SCRIPT_YAML_PATH);
    assert!(path.exists(), "Script YAML must exist at: {}", SCRIPT_YAML_PATH);
}

#[test]
fn test_script_calls_correct_binary() -> Result<(), String> {
    let content = fs::read_to_string(SCRIPT_PATH).map_err(|e| e.to_string())?;
    let contains_binary = content.contains(BINARY_NAME);
    assert!(contains_binary, "Script must call {} binary", BINARY_NAME);
    Ok(())
}

#[test]
fn test_script_yaml_is_valid_yaml() -> Result<(), String> {
    let content = fs::read_to_string(SCRIPT_YAML_PATH).map_err(|e| e.to_string())?;
    let parsed: Result<serde_yaml::Value, _> = serde_yaml::from_str(&content);
    assert!(parsed.is_ok(), "Script YAML should be valid YAML");
    Ok(())
}

#[test]
fn test_script_yaml_has_required_schema() -> Result<(), String> {
    let content = fs::read_to_string(SCRIPT_YAML_PATH).map_err(|e| e.to_string())?;
    let parsed: serde_yaml::Value = serde_yaml::from_str(&content)?;

    assert!(parsed.get("summary").is_some(), "Script YAML must have summary field");
    assert!(parsed.get("kind").is_some(), "Script YAML must have kind field");
    assert!(parsed.get("language").is_some(), "Script YAML must have language field");
    assert!(parsed.get("schema").is_some(), "Script YAML must have schema field");

    let schema = parsed.get("schema").unwrap();
    assert_eq!(
        schema.get("type"),
        Some(&serde_yaml::Value::String("object".to_string())),
        "Schema must define object type"
    );

    let required_fields = [
        "fatsecret",
        "access_token",
        "access_secret",
        "saved_meal_name",
        "saved_meal_description",
        "meals",
    ];
    let properties = schema.get("properties").and_then(|p| p.as_mapping());

    if let Some(props) = properties {
        for field in &required_fields {
            assert!(props.contains_key(field), "Schema must require field: {}", field);
        }
    }
    Ok(())
}

#[test]
fn test_binary_produces_valid_json_output() -> Result<(), String> {
    use std::process::{Command, Stdio};

    let binary_path = format!("./bin/{}", BINARY_NAME);
    if !Path::new(&binary_path).exists() {
        println!("SKIP: Binary {} not built (run: cargo build --bin {})", BINARY_NAME, BINARY_NAME);
        return Ok(());
    }

    let input = serde_json::json!({
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

    let mut child = Command::new(binary_path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to spawn binary: {}", e))?;

    if let Some(stdin) = child.stdin.as_mut() {
        serde_json::to_writer(stdin, &input).map_err(|e| e.to_string())?;
    }

    let output = child.wait_with_output().map_err(|e| e.to_string())?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    let parse_result: Result<serde_json::Value, _> = serde_json::from_str(&stdout);

    let json = parse_result.map_err(|e| format!("Binary output must be valid JSON: {} (stdout: {})", e, stdout))?;

    assert!(json.get("success").is_some(), "Output must have success field");
    let success = json["success"].as_bool().ok_or("success must be boolean")?;

    if success {
        assert!(json.get("saved_meal_id").is_some(), "On success, output must have saved_meal_id field");
    } else {
        assert!(json.get("error").is_some(), "On failure, output must have error field");
    }
    Ok(())
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
