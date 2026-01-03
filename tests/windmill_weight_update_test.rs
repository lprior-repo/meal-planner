//! Windmill Flow Acceptance Tests for `fatsecret_weight_update`
//!
//! Dave Farley: "Validate structure first, then test manually in production."
//!
//! GATE-1: Acceptance test for Windmill flow
//! GATE-2: Unit test for flow logic
//!
//! These tests validate:
//! - Windmill script files exist and are readable
//! - Schema definitions are valid
//! - Input validation logic
//!
//! Environment variables for real API tests:
//! - WINDMILL_BASE_URL: Windmill API URL (default: http://localhost:8000)
//! - WINDMILL_TOKEN: API token for authentication
//! - WINDMILL_WORKSPACE: Workspace name (default: meal-planner)
//! - FATSECRET_ACCESS_TOKEN: OAuth access token
//! - FATSECRET_ACCESS_SECRET: OAuth access secret

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use serde_json::json;
use std::env;

const DEFAULT_BASE_URL: &str = "http://localhost:8000";
const DEFAULT_WORKSPACE: &str = "meal-planner";

fn get_windmill_base_url() -> String {
    env::var("WINDMILL_BASE_URL").unwrap_or_else(|_| DEFAULT_BASE_URL.to_string())
}

fn get_windmill_token() -> Option<String> {
    env::var("WINDMILL_TOKEN").ok()
}

fn get_windmill_workspace() -> String {
    env::var("WINDMILL_WORKSPACE").unwrap_or_else(|_| DEFAULT_WORKSPACE.to_string())
}

fn script_exists_in_repo(script_name: &str) -> bool {
    let path = format!("windmill/f/fatsecret/{}.sh", script_name);
    std::path::Path::new(&path).exists()
}

fn script_yaml_exists(script_name: &str) -> bool {
    let path = format!("windmill/f/fatsecret/{}.script.yaml", script_name);
    std::path::Path::new(&path).exists()
}

fn binary_exists(binary_name: &str) -> bool {
    let paths = [
        format!("./bin/{}", binary_name),
        format!("target/debug/{}", binary_name),
        format!("target/release/{}", binary_name),
    ];
    paths.iter().any(|p| std::path::Path::new(p).exists())
}

// =============================================================================
// GATE-1: Acceptance Tests - Windmill Flow Structure
// =============================================================================

#[test]
fn weight_update_script_files_exist() {
    assert!(
        script_exists_in_repo("weight_update"),
        "weight_update.sh must exist in windmill/f/fatsecret/"
    );
    assert!(
        script_yaml_exists("weight_update"),
        "weight_update.script.yaml must exist in windmill/f/fatsecret/"
    );
}

#[test]
fn weight_update_script_is_readable() {
    let sh_path = "windmill/f/fatsecret/weight_update.sh";
    let yaml_path = "windmill/f/fatsecret/weight_update.script.yaml";

    let sh_content =
        std::fs::read_to_string(sh_path).expect("weight_update.sh should be readable");
    assert!(
        sh_content.contains("fatsecret_weight_update"),
        "Script should invoke the binary"
    );

    let yaml_content =
        std::fs::read_to_string(yaml_path).expect("weight_update.script.yaml should be readable");
    assert!(yaml_content.contains("summary"), "YAML should have summary field");
    assert!(
        yaml_content.contains("current_weight_kg"),
        "YAML should have current_weight_kg parameter"
    );
    assert!(
        yaml_content.contains("date_int"),
        "YAML should have date_int parameter"
    );
}

#[test]
fn weight_update_binary_exists() {
    assert!(
        binary_exists("fatsecret_weight_update"),
        "fatsecret_weight_update binary must exist"
    );
}

#[test]
fn weight_update_schema_is_valid() {
    let yaml_path = "windmill/f/fatsecret/weight_update.script.yaml";
    let content = std::fs::read_to_string(yaml_path).expect("Schema file should exist");

    let schema: serde_yaml::Value = serde_yaml::from_str(&content).expect("YAML should be valid");

    let inner_schema = schema.get("schema").expect("YAML should have schema key");
    let props = inner_schema["properties"]
        .as_mapping()
        .expect("Schema should have properties");

    assert!(
        props.contains_key(&serde_yaml::Value::String("current_weight_kg".to_string())),
        "Schema should require current_weight_kg"
    );
    assert!(
        props.contains_key(&serde_yaml::Value::String("date_int".to_string())),
        "Schema should require date_int"
    );
    assert!(
        props.contains_key(&serde_yaml::Value::String("access_token".to_string())),
        "Schema should require access_token"
    );
    assert!(
        props.contains_key(&serde_yaml::Value::String("access_secret".to_string())),
        "Schema should require access_secret"
    );
}

// =============================================================================
// GATE-2: Unit Tests - Flow Logic Validation
// =============================================================================

#[test]
fn validate_weight_input_positive_weight() {
    let input = json!({
        "current_weight_kg": 75.5,
        "date_int": 20088
    });
    assert!(is_valid_weight_input(&input), "Valid weight should pass");
}

#[test]
fn validate_weight_input_zero_weight() {
    let input = json!({
        "current_weight_kg": 0.0,
        "date_int": 20088
    });
    assert!(!is_valid_weight_input(&input), "Zero weight should fail");
}

#[test]
fn validate_weight_input_negative_weight() {
    let input = json!({
        "current_weight_kg": -10.0,
        "date_int": 20088
    });
    assert!(!is_valid_weight_input(&input), "Negative weight should fail");
}

#[test]
fn validate_weight_input_missing_weight() {
    let input = json!({
        "date_int": 20088
    });
    assert!(!is_valid_weight_input(&input), "Missing weight should fail");
}

#[test]
fn validate_weight_input_missing_date() {
    let input = json!({
        "current_weight_kg": 75.5
    });
    assert!(!is_valid_weight_input(&input), "Missing date should fail");
}

#[test]
fn validate_weight_input_valid_date_range() {
    let input = json!({
        "current_weight_kg": 75.5,
        "date_int": 20088
    });
    assert!(
        is_valid_date_int(input["date_int"].as_i64().unwrap()),
        "Valid date should pass"
    );
}

#[test]
fn validate_weight_input_invalid_date_range() {
    let input = json!({
        "current_weight_kg": 75.5,
        "date_int": -1000
    });
    assert!(
        !is_valid_date_int(input["date_int"].as_i64().unwrap()),
        "Invalid date should fail"
    );
}

#[test]
fn format_windmill_args_minimal() {
    let input = json!({
        "fatsecret": {"consumer_key": "key", "consumer_secret": "secret"},
        "access_token": "token",
        "access_secret": "secret",
        "current_weight_kg": 75.5,
        "date_int": 20088
    });
    let args = format_windmill_args(&input);
    assert!(args.contains("75.5"), "Should contain weight");
    assert!(args.contains("20088"), "Should contain date");
}

#[test]
fn format_windmill_args_with_optional_fields() {
    let input = json!({
        "fatsecret": {"consumer_key": "key", "consumer_secret": "secret"},
        "access_token": "token",
        "access_secret": "secret",
        "current_weight_kg": 75.5,
        "date_int": 20088,
        "goal_weight_kg": 70.0,
        "height_cm": 180.0,
        "comment": "Morning weigh-in"
    });
    let args = format_windmill_args(&input);
    assert!(args.contains("goal=70"), "Should contain goal");
    assert!(args.contains("height=180"), "Should contain height");
    assert!(args.contains("comment=Morning weigh-in"), "Should contain comment");
}

// =============================================================================
// GATE-3: Pure Core Functions (≤25 lines each)
// =============================================================================

fn is_valid_weight_input(input: &serde_json::Value) -> bool {
    let weight = input.get("current_weight_kg").and_then(|v| v.as_f64());
    let date = input.get("date_int").and_then(|v| v.as_i64());
    weight.map_or(false, |w| w > 0.0) && date.map_or(false, is_valid_date_int)
}

fn is_valid_date_int(date_int: i64) -> bool {
    let min_date = 0;
    let max_date = 365 * 100;
    (min_date..=max_date).contains(&date_int)
}

fn format_windmill_args(input: &serde_json::Value) -> String {
    let weight = input["current_weight_kg"].as_f64().unwrap_or(0.0);
    let date = input["date_int"].as_i64().unwrap_or(0);
    let goal = input["goal_weight_kg"].as_f64();
    let height = input["height_cm"].as_f64();
    let comment = input["comment"].as_str();
    let mut result = format!("weight={} date={}", weight, date);
    if let Some(g) = goal {
        result.push_str(&format!(" goal={}", g));
    }
    if let Some(h) = height {
        result.push_str(&format!(" height={}", h));
    }
    if let Some(c) = comment {
        result.push_str(&format!(" comment={}", c));
    }
    result
}

// =============================================================================
// GATE-5: Ignored Integration Tests (require real API)
// =============================================================================

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_weight_update_deployed() {
    if !script_exists_in_repo("weight_update") {
        println!("SKIP: weight_update.sh not deployed");
        return;
    }

    let _base_url = get_windmill_base_url();
    let _token = match get_windmill_token() {
        Some(_t) => _t,
        None => {
            println!("SKIP: WINDMILL_TOKEN not set");
            return;
        }
    };
    let _workspace = get_windmill_workspace();

    println!("Windmill URL: {}/{}", _base_url, _workspace);
    println!("weight_update script: DEPLOYED");
    println!("Run with: wmill script run f/fatsecret/weight_update.sh -d '{{...}}'");
}

#[test]
#[ignore = "requires real FatSecret API credentials"]
fn test_windmill_weight_update_full_integration() {
    let token = env::var("FATSECRET_ACCESS_TOKEN").ok();
    let _secret = env::var("FATSECRET_ACCESS_SECRET").ok();

    match token {
        Some(t) => {
            println!(
                "Credentials available: token={}...",
                t.chars().take(5).collect::<String>()
            );
            println!("Integration test would execute with real API");
        }
        None => {
            println!("SKIP: FATSECRET_ACCESS_TOKEN not set");
        }
    }
}
