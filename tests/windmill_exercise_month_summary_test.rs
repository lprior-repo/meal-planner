//! Windmill Flow Test - fatsecret_exercise_month_summary
//!
//! Dave Farley: "Validate structure, then test manually in production."
//!
//! Tests:
//! - Script file exists and is readable
//! - Script YAML schema is valid
//! - Manual testing instructions documented

#![allow(clippy::unwrap_used)]

#[test]
fn exercise_month_summary_script_exists() {
    let script_path = "windmill/f/fatsecret/exercise_month_summary.sh";

    assert!(
        std::path::Path::new(script_path).exists(),
        "Windmill script should exist: {}",
        script_path
    );
}

#[test]
fn exercise_month_summary_script_yaml_exists() {
    let yaml_path = "windmill/f/fatsecret/exercise_month_summary.script.yaml";

    assert!(
        std::path::Path::new(yaml_path).exists(),
        "Script YAML should exist: {}",
        yaml_path
    );
}

#[test]
fn exercise_month_summary_script_yaml_is_valid() {
    let yaml_path = "windmill/f/fatsecret/exercise_month_summary.script.yaml";
    let content = std::fs::read_to_string(yaml_path)
        .expect("Should read script YAML file");

    let parsed: serde_yaml::Value = serde_yaml::from_str(&content)
        .expect("Script YAML should be valid YAML");

    assert!(
        parsed.get("summary").is_some(),
        "Script YAML should have 'summary' field"
    );
    assert!(
        parsed.get("kind").and_then(|v| v.as_str()) == Some("script"),
        "Script kind should be 'script'"
    );
    assert!(
        parsed.get("language").and_then(|v| v.as_str()) == Some("bash"),
        "Script language should be 'bash'"
    );
}

#[test]
fn exercise_month_summary_schema_has_required_fields() {
    let yaml_path = "windmill/f/fatsecret/exercise_month_summary.script.yaml";
    let content = std::fs::read_to_string(yaml_path)
        .expect("Should read script YAML file");

    let parsed: serde_yaml::Value = serde_yaml::from_str(&content)
        .expect("Script YAML should be valid YAML");

    let schema = parsed.get("schema")
        .expect("Script should have schema");

    let required = schema.get("required")
        .and_then(|v| v.as_sequence())
        .expect("Schema should have required array");

    let required_fields: Vec<&str> = required.iter()
        .filter_map(|v| v.as_str())
        .collect();

    assert!(
        required_fields.contains(&"fatsecret"),
        "Required fields should include 'fatsecret'"
    );
    assert!(
        required_fields.contains(&"access_token"),
        "Required fields should include 'access_token'"
    );
    assert!(
        required_fields.contains(&"access_secret"),
        "Required fields should include 'access_secret'"
    );
    assert!(
        required_fields.contains(&"year"),
        "Required fields should include 'year'"
    );
    assert!(
        required_fields.contains(&"month"),
        "Required fields should include 'month'"
    );
}
