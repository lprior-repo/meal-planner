//! Windmill Integration Tests for Tandoor Batch Update Script
//!
//! Tests verify that the Windmill bash script `recipe_batch_update.sh` correctly
//! wraps and calls the Rust binary `tandoor_recipe_batch_update`.
//!
//! Run with: cargo test --test windmill_tandoor_batch_update_tests -- --ignored
//!
//! Requirements:
//! - Windmill running with workers that have binaries mounted
//! - Deployed script: f/tandoor/recipe_batch_update.sh
//! - Configured resource: u/admin/tandoor_api (base_url, api_token)

#![allow(
    clippy::unwrap_used,
    clippy::indexing_slicing,
    clippy::expect_used,
    clippy::cast_possible_wrap,
    clippy::integer_division,
    clippy::too_many_lines,
    clippy::ignored_unit_patterns
)]

use serde_json::{json, Value};
use std::env;
use std::path::Path;
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
    Path::new(&format!("windmill/f/tandoor/{}", script_name)).exists()
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

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_recipe_batch_update_script_exists() {
    assert!(
        script_exists_in_repo("recipe_batch_update.sh"),
        "recipe_batch_update.sh should exist in windmill/f/tandoor/"
    );
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_recipe_batch_update_yaml_valid() {
    let yaml_path = "windmill/f/tandoor/recipe_batch_update.script.yaml";
    let content = std::fs::read_to_string(yaml_path).expect("Should read yaml file");

    assert!(content.contains("language: bash"), "Should specify bash language");
    assert!(content.contains("kind: script"), "Should specify script kind");
    assert!(content.contains("summary:"), "Should have summary");
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_recipe_batch_update_schema_valid() {
    let yaml_path = "windmill/f/tandoor/recipe_batch_update.script.yaml";
    let content = std::fs::read_to_string(yaml_path).expect("Should read yaml file");

    assert!(
        content.contains("schema:"),
        "Should have schema definition"
    );
    assert!(
        content.contains("tandoor"),
        "Schema should require tandoor field"
    );
    assert!(
        content.contains("updates"),
        "Schema should require updates field"
    );
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_recipe_batch_update_shellcheck_valid() {
    let script_path = "windmill/f/tandoor/recipe_batch_update.sh";
    let content = std::fs::read_to_string(script_path).expect("Should read script file");

    assert!(
        content.contains("# shellcheck shell=bash"),
        "Should have shellcheck directive"
    );
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_recipe_batch_update_runs() {
    skip_if_not_deployed!("recipe_batch_update.sh");
    skip_if_resource_not_configured!("u/admin/tandoor_api");

    let result = run_windmill_script(
        "f/tandoor/recipe_batch_update.sh",
        &json!({
            "tandoor": "$res:u/admin/tandoor_api",
            "updates": [
                {"id": 1, "name": "Test Batch Update via Windmill"}
            ]
        }),
    );

    assert!(result.is_ok(), "Script should execute: {:?}", result.err());
    let output = result.unwrap();

    assert_eq!(
        output["success"], true,
        "Expected success: true, got: {:?}",
        output
    );
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_recipe_batch_update_returns_updated_count() {
    skip_if_not_deployed!("recipe_batch_update.sh");
    skip_if_resource_not_configured!("u/admin/tandoor_api");

    let result = run_windmill_script(
        "f/tandoor/recipe_batch_update.sh",
        &json!({
            "tandoor": "$res:u/admin/tandoor_api",
            "updates": [
                {"id": 1, "name": "Updated Name 1"},
                {"id": 2, "description": "Updated Desc 2"}
            ]
        }),
    );

    assert!(result.is_ok(), "Script should execute: {:?}", result.err());
    let output = result.unwrap();

    let updated_count = output["updated_count"]
        .as_i64()
        .expect("Should have updated_count field");
    assert!(
        updated_count >= 0,
        "Updated count should be non-negative, got: {}",
        updated_count
    );
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_recipe_batch_update_empty_updates_handled() {
    skip_if_not_deployed!("recipe_batch_update.sh");
    skip_if_resource_not_configured!("u/admin/tandoor_api");

    let result = run_windmill_script(
        "f/tandoor/recipe_batch_update.sh",
        &json!({
            "tandoor": "$res:u/admin/tandoor_api",
            "updates": []
        }),
    );

    assert!(result.is_err(), "Empty updates should produce an error");
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_recipe_batch_update_coverage_summary() {
    println!("\n========================================");
    println!("Windmill Tandoor Batch Update Test Coverage");
    println!("========================================\n");

    println!("Test Categories:");
    println!("  [x] Script existence check");
    println!("  [x] YAML configuration validation");
    println!("  [x] Schema validation");
    println!("  [x] ShellCheck directive presence");
    println!("  [x] Script execution via Windmill CLI");
    println!("  [x] Updated count response validation");
    println!("  [x] Empty updates error handling");
    println!();

    println!("========================================\n");
}
