//! Windmill Integration Tests for Tandoor Recipe Get
//!
//! Tests the tandoor_recipe_get Windmill script via the Windmill CLI.
//! These tests verify:
//! - Script exists and is properly configured
//! - Script can be executed via Windmill
//! - Response format matches expected CUE contract
//!
//! Run with: cargo test --test tandoor_recipe_get_windmill_test -- --ignored
//!
//! Environment variables:
//! - WINDMILL_BASE_URL: Windmill API URL (default: http://localhost:8000)
//! - WINDMILL_TOKEN: API token for authentication
//! - WINDMILL_WORKSPACE: Workspace name (default: meal-planner)

#![allow(
    clippy::unwrap_used,
    clippy::indexing_slicing,
    clippy::expect_used,
    clippy::cast_possible_wrap,
    clippy::too_many_lines
)]

use serde_json::{json, Value};
use std::env;
use std::process::Command;

const DEFAULT_BASE_URL: &str = "http://localhost:8000";
const DEFAULT_WORKSPACE: &str = "meal-planner";

fn get_windmill_base_url() -> String {
    env::var("WINDMILL_BASE_URL").unwrap_or_else(|_| DEFAULT_BASE_URL.to_string())
}

fn get_windmill_token() -> String {
    env::var("WINDMILL_TOKEN").expect("WINDMILL_TOKEN must be set for integration tests")
}

fn get_windmill_workspace() -> String {
    env::var("WINDMILL_WORKSPACE").unwrap_or_else(|_| DEFAULT_WORKSPACE.to_string())
}

fn script_exists_in_repo(script_name: &str) -> bool {
    std::path::Path::new(&format!("windmill/f/tandoor/{}.sh", script_name)).exists()
}

fn check_resource_configured(resource_path: &str) -> Result<(), String> {
    let base_url = get_windmill_base_url();
    let token = get_windmill_token();
    let workspace = get_windmill_workspace();

    let url = format!(
        "{}/api/w/{}/resources/{}",
        base_url, workspace, resource_path
    );

    let output = Command::new("curl")
        .args([
            "-s",
            "-H",
            &format!("Authorization: Bearer {}", token),
            &url,
        ])
        .output()
        .map_err(|e| format!("curl failed: {}", e))?;

    if !output.status.success() {
        return Err(format!(
            "Resource check failed: {}",
            String::from_utf8_lossy(&output.stderr)
        ));
    }

    let response = String::from_utf8_lossy(&output.stdout);
    if response.contains("not found") || response.is_empty() {
        return Err(format!("Resource {} not configured", resource_path));
    }

    Ok(())
}

fn run_windmill_script(script_path: &str, args: &Value) -> Result<Value, String> {
    let base_url = get_windmill_base_url();
    let args_json = serde_json::to_string(args).map_err(|e| e.to_string())?;

    let output = Command::new("wmill")
        .args([
            "--base-url",
            &base_url,
            "script",
            "run",
            script_path,
            "-d",
            &args_json,
        ])
        .current_dir("windmill")
        .output()
        .map_err(|e| format!("Failed to run wmill: {}", e))?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);

    if !output.status.success() {
        return Err(format!("Script failed: {}", stderr));
    }

    let json_start = stdout.rfind('{');
    let json_end = stdout.rfind('}');

    match (json_start, json_end) {
        (Some(start), Some(end)) if end > start => {
            let json_str = &stdout[start..=end];
            serde_json::from_str(json_str)
                .map_err(|e| format!("Failed to parse JSON: {} (output: {})", e, json_str))
        }
        _ => Err(format!(
            "No JSON found in output. stdout: {}, stderr: {}",
            stdout, stderr
        )),
    }
}

macro_rules! skip_if_not_deployed {
    ($script_name:expr) => {
        if !script_exists_in_repo($script_name) {
            println!("SKIP: Script f/tandoor/{} not deployed", $script_name);
            return;
        }
    };
}

macro_rules! skip_if_resource_not_configured {
    ($resource_path:expr) => {
        if let Err(e) = check_resource_configured($resource_path) {
            println!("SKIP: {} - {}", $resource_path, e);
            return;
        }
    };
}

// =============================================================================
// GATE-3: Pure Core Functions for Flow Validation (≤25 lines each)
// =============================================================================

fn validate_recipe_id(recipe_id: i64) -> Result<(), String> {
    if recipe_id <= 0 {
        Err(format!("recipe_id must be positive, got {}", recipe_id))
    } else {
        Ok(())
    }
}

fn validate_tandoor_resource(tandoor: &Value) -> Result<(), String> {
    if !tandoor.is_object() {
        return Err("tandoor must be an object".to_string());
    }
    let base_url = tandoor.get("base_url").and_then(|v| v.as_str());
    let api_token = tandoor.get("api_token").and_then(|v| v.as_str());
    match (base_url, api_token) {
        (Some(url), Some(token)) if url.starts_with("http") && !token.is_empty() => Ok(()),
        _ => Err("tandoor requires base_url (http URL) and api_token".to_string()),
    }
}

fn validate_input(input: &Value) -> Result<(), String> {
    let tandoor = input
        .get("tandoor")
        .ok_or("missing required field: tandoor")?;
    validate_tandoor_resource(tandoor)?;
    let recipe_id = input
        .get("recipe_id")
        .ok_or("missing required field: recipe_id")?
        .as_i64()
        .ok_or("recipe_id must be an integer")?;
    validate_recipe_id(recipe_id)
}

fn extract_recipe_id(input: &Value) -> Option<i64> {
    input.get("recipe_id")?.as_i64()
}

fn extract_tandoor_resource(input: &Value) -> Option<Value> {
    input.get("tandoor").cloned()
}

fn format_success_response(recipe: &Value) -> Value {
    json!({
        "success": true,
        "recipe": recipe
    })
}

fn format_error_response(message: &str) -> Value {
    json!({
        "success": false,
        "error": message
    })
}

// =============================================================================
// GATE-1: Acceptance Tests for Windmill Flow
// =============================================================================

#[test]
fn test_tandoor_recipe_get_script_exists() {
    assert!(
        script_exists_in_repo("recipe_get"),
        "Script windmill/f/tandoor/recipe_get.sh should exist"
    );
}

#[test]
fn test_tandoor_recipe_get_script_format() {
    let script_path = "windmill/f/tandoor/recipe_get.sh";
    assert!(
        std::path::Path::new(script_path).exists(),
        "Script file should exist at {}",
        script_path
    );

    let content = std::fs::read_to_string(script_path).expect("Should read script");
    assert!(
        content.contains("tandoor_recipe_get"),
        "Script should call tandoor_recipe_get binary"
    );
}

#[test]
fn test_tandoor_recipe_get_script_yaml_exists() {
    let yaml_path = "windmill/f/tandoor/recipe_get.script.yaml";
    assert!(
        std::path::Path::new(yaml_path).exists(),
        "Script YAML should exist at {}",
        yaml_path
    );
}

// =============================================================================
// GATE-2: Unit Tests for Flow Logic (Pure Core Functions)
// =============================================================================

#[test]
fn test_validate_recipe_id_positive() {
    assert!(validate_recipe_id(1).is_ok());
    assert!(validate_recipe_id(100).is_ok());
    assert!(validate_recipe_id(i64::MAX).is_ok());
}

#[test]
fn test_validate_recipe_id_non_positive() {
    assert!(validate_recipe_id(0).is_err());
    assert!(validate_recipe_id(-1).is_err());
    assert!(validate_recipe_id(-100).is_err());
}

#[test]
fn test_validate_tandoor_resource_valid() {
    let valid = json!({
        "base_url": "http://localhost:8090",
        "api_token": "test-token"
    });
    assert!(validate_tandoor_resource(&valid).is_ok());

    let valid_https = json!({
        "base_url": "https://example.com",
        "api_token": "secure-token"
    });
    assert!(validate_tandoor_resource(&valid_https).is_ok());
}

#[test]
fn test_validate_tandoor_resource_invalid() {
    let missing_base_url = json!({
        "api_token": "test-token"
    });
    assert!(validate_tandoor_resource(&missing_base_url).is_err());

    let missing_token = json!({
        "base_url": "http://localhost:8090"
    });
    assert!(validate_tandoor_resource(&missing_token).is_err());

    let invalid_url = json!({
        "base_url": "not-a-url",
        "api_token": "test-token"
    });
    assert!(validate_tandoor_resource(&invalid_url).is_err());

    let empty_token = json!({
        "base_url": "http://localhost:8090",
        "api_token": ""
    });
    assert!(validate_tandoor_resource(&empty_token).is_err());
}

#[test]
fn test_validate_input_valid() {
    let valid_input = json!({
        "tandoor": {
            "base_url": "http://localhost:8090",
            "api_token": "test-token"
        },
        "recipe_id": 123
    });
    assert!(validate_input(&valid_input).is_ok());
}

#[test]
fn test_validate_input_missing_tandoor() {
    let missing_tandoor = json!({
        "recipe_id": 123
    });
    assert!(validate_input(&missing_tandoor).is_err());
}

#[test]
fn test_validate_input_missing_recipe_id() {
    let missing_id = json!({
        "tandoor": {
            "base_url": "http://localhost:8090",
            "api_token": "test-token"
        }
    });
    assert!(validate_input(&missing_id).is_err());
}

#[test]
fn test_validate_input_invalid_recipe_id_type() {
    let invalid_type = json!({
        "tandoor": {
            "base_url": "http://localhost:8090",
            "api_token": "test-token"
        },
        "recipe_id": "not-a-number"
    });
    assert!(validate_input(&invalid_type).is_err());
}

#[test]
fn test_extract_recipe_id() {
    let input = json!({
        "tandoor": {},
        "recipe_id": 42
    });
    assert_eq!(extract_recipe_id(&input), Some(42));
}

#[test]
fn test_extract_tandoor_resource() {
    let tandoor = json!({
        "base_url": "http://localhost:8090",
        "api_token": "test"
    });
    let input = json!({
        "tandoor": tandoor,
        "recipe_id": 1
    });
    let extracted = extract_tandoor_resource(&input);
    assert!(extracted.is_some());
    assert_eq!(extracted.unwrap()["base_url"], "http://localhost:8090");
}

#[test]
fn test_format_success_response() {
    let recipe = json!({
        "id": 1,
        "name": "Test Recipe"
    });
    let response = format_success_response(&recipe);
    assert_eq!(response["success"], true);
    assert!(response["recipe"].is_object());
    assert_eq!(response["recipe"]["id"], 1);
}

#[test]
fn test_format_error_response() {
    let response = format_error_response("Not found");
    assert_eq!(response["success"], false);
    assert_eq!(response["error"], "Not found");
}

// =============================================================================
// GATE-1: Integration Tests (require Windmill deployment)
// =============================================================================

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_tandoor_recipe_get() {
    skip_if_not_deployed!("recipe_get");
    skip_if_resource_not_configured!("u/admin/tandoor_api");

    let result = run_windmill_script(
        "f/tandoor/recipe_get.sh",
        &json!({
            "tandoor": "$res:u/admin/tandoor_api",
            "recipe_id": 1
        }),
    );

    assert!(result.is_ok(), "Script failed: {:?}", result.err());
    let output = result.unwrap();

    assert_eq!(output["success"], true, "Expected success: true");
    assert!(output["recipe"].is_object(), "Expected recipe object");
    assert_eq!(output["recipe"]["id"], 1, "Expected recipe ID 1");
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_tandoor_recipe_get_not_found() {
    skip_if_not_deployed!("recipe_get");
    skip_if_resource_not_configured!("u/admin/tandoor_api");

    let result = run_windmill_script(
        "f/tandoor/recipe_get.sh",
        &json!({
            "tandoor": "$res:u/admin/tandoor_api",
            "recipe_id": 999999999
        }),
    );

    assert!(result.is_ok(), "Script should complete without panic");
    let output = result.unwrap();
    assert!(
        output["success"] == false || output.get("error").is_some(),
        "Expected either success:false or error field for non-existent recipe"
    );
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_tandoor_recipe_get_invalid_id() {
    skip_if_not_deployed!("recipe_get");
    skip_if_resource_not_configured!("u/admin/tandoor_api");

    let result = run_windmill_script(
        "f/tandoor/recipe_get.sh",
        &json!({
            "tandoor": "$res:u/admin/tandoor_api",
            "recipe_id": -1
        }),
    );

    assert!(result.is_ok(), "Script should handle invalid ID gracefully");
}

#[test]
#[ignore = "requires Windmill API connection"]
fn test_windmill_tandoor_recipe_get_deployment_status() {
    println!("=== Tandoor Recipe Get Windmill Deployment Status ===");

    println!("\nScript: f/tandoor/recipe_get.sh");
    if script_exists_in_repo("recipe_get") {
        println!("  ✓ Script file exists in repository");
    } else {
        println!("  ✗ Script file NOT found");
    }

    println!("\nResource: u/admin/tandoor_api");
    if let Err(e) = check_resource_configured("u/admin/tandoor_api") {
        println!("  ⚠ Resource not configured: {}", e);
    } else {
        println!("  ✓ Resource configured");
    }

    println!("\nManual testing instructions:");
    println!("  1. Deploy script: wmill sync push --yes");
    println!("  2. Run in Windmill UI: f/tandoor/recipe_get");
    println!("  3. Input: {{\"tandoor\": \"$res:u/admin/tandoor_api\", \"recipe_id\": 1}}");
    println!("  4. Verify response contains success=true and recipe object");
}
