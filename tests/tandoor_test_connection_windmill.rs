//! Windmill Integration Tests for Tandoor `test_connection` Script
//!
//! Tests the `tandoor_test_connection` binary through Windmill orchestration.
//! Following Dave Farley's Modern Software Engineering principles:
//! - Functional Core / Imperative Shell
//! - Tests as specification
//! - TCR (Test, Commit, Revert) enforcement
//!
//! Requirements:
//! - Windmill running with workers that have binaries mounted
//! - Deployed script: windmill/f/tandoor/test_connection.sh
//! - Configured resource: u/admin/tandoor_api (base_url + api_token)
//!
//! Run with: cargo test --test tandoor_test_connection_windmill -- --ignored
//!
//! Environment variables:
//! - WINDMILL_BASE_URL: Windmill API URL (default: http://localhost:8000)
//! - WINDMILL_TOKEN: API token for authentication
//! - WINDMILL_WORKSPACE: Workspace name (default: meal-planner)

#![allow(clippy::unwrap_used, clippy::expect_used, clippy::indexing_slicing)]

use serde_json::Value;
use std::env;

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

fn script_exists_in_repo() -> bool {
    std::path::Path::new("windmill/f/tandoor/test_connection.sh").exists()
}

fn check_resource_configured(resource_path: &str) -> Result<(), String> {
    let base_url = get_windmill_base_url();
    let token = get_windmill_token();
    let workspace = get_windmill_workspace();

    let url = format!(
        "{}/api/w/{}/resources/{}",
        base_url, workspace, resource_path
    );

    let output = std::process::Command::new("curl")
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

    let output = std::process::Command::new("wmill")
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
    () => {
        if !script_exists_in_repo() {
            println!("SKIP: Script f/tandoor/test_connection.sh not deployed");
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

/// GATE-1: Acceptance Test for Windmill Flow
/// Validates the complete flow: input → binary → output
#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_tandoor_test_connection_success() {
    skip_if_not_deployed!();
    skip_if_resource_not_configured!("u/admin/tandoor_api");

    let result = run_windmill_script(
        "f/tandoor/test_connection.sh",
        &serde_json::json!({
            "tandoor": "$res:u/admin/tandoor_api"
        }),
    );

    assert!(result.is_ok(), "Script failed: {:?}", result.err());
    let output = result.unwrap();

    assert_eq!(output["success"], true, "Expected success: true");
    assert!(output["message"].is_string(), "Expected message string");
    assert!(
        output["recipe_count"].is_number(),
        "Expected recipe_count number"
    );
}

/// GATE-1b: Acceptance Test - Invalid Credentials
/// Validates error handling when Tandoor API returns auth error
#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_tandoor_test_connection_invalid_credentials() {
    skip_if_not_deployed!();
    skip_if_resource_not_configured!("u/admin/tandoor_api");

    let result = run_windmill_script(
        "f/tandoor/test_connection.sh",
        &serde_json::json!({
            "tandoor": {
                "base_url": "http://localhost:9999",
                "api_token": "invalid_token"
            }
        }),
    );

    assert!(
        result.is_ok(),
        "Script should return (auth errors are handled by binary)"
    );
    let output = result.unwrap();
    assert_eq!(
        output["success"], false,
        "Expected failure with invalid credentials"
    );
}

/// GATE-2: Unit Test Coverage for Flow Logic
/// Tests the integration suite marker (no actual API calls)
#[test]
#[ignore = "requires Windmill"]
fn test_tandoor_test_connection_integration_suite() {
    println!("\n=== Tandoor test_connection Windmill Integration Suite ===\n");

    println!("Script deployment check:");
    if script_exists_in_repo() {
        println!("  ✓ test_connection.sh: DEPLOYED");
    } else {
        println!("  ✗ test_connection.sh: NOT DEPLOYED");
    }

    println!("\nResource configuration check:");
    println!("  Expected: u/admin/tandoor_api");
    println!("  Run: wmill resource get u/admin/tandoor_api\n");

    println!("Test scenarios:");
    println!("  1. test_windmill_tandoor_test_connection_success - Valid credentials");
    println!(
        "  2. test_windmill_tandoor_test_connection_invalid_credentials - Invalid credentials"
    );
    println!("\nManual testing:");
    println!(r#"  wmill script run f/tandoor/test_connection.sh -d '{{"tandoor": "$res:u/admin/tandoor_api"}}'"#);
}
