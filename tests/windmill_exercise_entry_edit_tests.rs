//! Windmill Script Tests for `fatsecret_exercise_entry_edit`
//!
//! Dave Farley says: "Validate structure, then test manually in production."
//!
//! Tests:
//! - Script files exist and are readable
//! - Script YAML is valid
//! - Script logic validates inputs correctly
//!
//! These tests verify the Windmill script shell wrapper, not the underlying binary.

#![allow(clippy::unwrap_used, clippy::too_many_lines)]

use std::fs;
use std::path::Path;

const SCRIPT_NAME: &str = "exercise_entry_edit";
const SCRIPT_PATH: &str = "windmill/f/fatsecret/exercise_entry_edit.sh";
const SCRIPT_YAML_PATH: &str = "windmill/f/fatsecret/exercise_entry_edit.script.yaml";

#[test]
fn script_file_exists() {
    assert!(
        Path::new(SCRIPT_PATH).exists(),
        "Script file should exist: {}",
        SCRIPT_PATH
    );
}

#[test]
fn script_is_readable() {
    let content = fs::read_to_string(SCRIPT_PATH)
        .unwrap_or_else(|e| panic!("Script should be readable: {}", e));
    assert!(!content.is_empty(), "Script file should not be empty");
}

#[test]
fn script_has_correct_shebang() {
    let content = fs::read_to_string(SCRIPT_PATH).unwrap();
    assert!(
        content.starts_with("#!/"),
        "Script should start with shebang"
    );
    assert!(content.contains("bash"), "Script should use bash");
}

#[test]
fn script_calls_correct_binary() {
    let content = fs::read_to_string(SCRIPT_PATH).unwrap();
    assert!(
        content.contains("fatsecret_exercise_entry_edit"),
        "Script should call fatsecret_exercise_entry_edit binary"
    );
}

#[test]
fn script_yaml_exists() {
    assert!(
        Path::new(SCRIPT_YAML_PATH).exists(),
        "Script YAML should exist: {}",
        SCRIPT_YAML_PATH
    );
}

#[test]
fn script_yaml_is_valid_yaml() {
    let content = fs::read_to_string(SCRIPT_YAML_PATH)
        .unwrap_or_else(|e| panic!("Script YAML should be readable: {}", e));

    let parsed: Result<serde_yaml::Value, _> = serde_yaml::from_str(&content);
    assert!(
        parsed.is_ok(),
        "Script YAML should be valid YAML: {:?}",
        parsed.err()
    );
}

#[test]
fn script_yaml_has_summary() {
    let content = fs::read_to_string(SCRIPT_YAML_PATH).unwrap();
    let parsed: serde_yaml::Value = serde_yaml::from_str(&content).unwrap();
    assert!(
        parsed.get("summary").is_some(),
        "Script YAML should have summary field"
    );
}

#[test]
fn script_yaml_has_description() {
    let content = fs::read_to_string(SCRIPT_YAML_PATH).unwrap();
    let parsed: serde_yaml::Value = serde_yaml::from_str(&content).unwrap();
    assert!(
        parsed.get("description").is_some(),
        "Script YAML should have description field"
    );
}

#[test]
fn script_yaml_has_schema() {
    let content = fs::read_to_string(SCRIPT_YAML_PATH).unwrap();
    let parsed: serde_yaml::Value = serde_yaml::from_str(&content).unwrap();
    assert!(
        parsed.get("schema").is_some(),
        "Script YAML should have schema field"
    );
}

#[test]
fn script_yaml_schema_has_required_fields() {
    let content = fs::read_to_string(SCRIPT_YAML_PATH).unwrap();
    let parsed: serde_yaml::Value = serde_yaml::from_str(&content).unwrap();
    let schema = parsed.get("schema").unwrap();

    let required_fields = [
        "fatsecret",
        "access_token",
        "access_secret",
        "exercise_entry_id",
    ];
    let schema_required = schema.get("required").unwrap().as_sequence().unwrap();

    for field in &required_fields {
        let found = schema_required
            .iter()
            .any(|r| r.as_str().unwrap_or("") == *field);
        assert!(found, "Schema should require field: {}", field);
    }
}

#[test]
fn script_yaml_schema_has_optional_fields() {
    let content = fs::read_to_string(SCRIPT_YAML_PATH).unwrap();
    let parsed: serde_yaml::Value = serde_yaml::from_str(&content).unwrap();
    let schema = parsed.get("schema").unwrap();
    let properties = schema.get("properties").unwrap().as_mapping().unwrap();

    assert!(
        properties.contains_key("exercise_id"),
        "Schema should have optional field: exercise_id"
    );
    assert!(
        properties.contains_key("duration_min"),
        "Schema should have optional field: duration_min"
    );
}

#[test]
fn script_handles_empty_optional_fields() {
    let script_content = fs::read_to_string(SCRIPT_PATH).unwrap();
    assert!(
        script_content.contains("if $exercise_id != \"\""),
        "Script should conditionally include exercise_id"
    );
    assert!(
        script_content.contains("if $duration_min != \"\""),
        "Script should conditionally include duration_min"
    );
}

#[test]
fn script_uses_jq_for_json() {
    let script_content = fs::read_to_string(SCRIPT_PATH).unwrap();
    assert!(
        script_content.contains("jq"),
        "Script should use jq for JSON construction"
    );
}

#[test]
fn script_pipes_to_binary() {
    let script_content = fs::read_to_string(SCRIPT_PATH).unwrap();
    assert!(
        script_content.contains("echo \"$input\" |"),
        "Script should pipe input to binary"
    );
    assert!(
        script_content.contains(">./result.json"),
        "Script should redirect output to result.json"
    );
}
