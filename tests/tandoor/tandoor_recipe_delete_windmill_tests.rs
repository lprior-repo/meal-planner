//! Windmill Integration Tests for Tandoor Recipe Delete
//!
//! Dave Farley says: "Validate structure, then test manually in production."
//!
//! Tests:
//! - Script files exist and are valid
//! - Schema validation
//! - Manual testing instructions documented

#![allow(clippy::unwrap_used, clippy::too_many_lines)]

use serde_json::json;
use std::env;
use std::process::{Command, Stdio};

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

fn get_tandoor_creds() -> (String, String) {
    let base_url =
        env::var("TANDOOR_BASE_URL").unwrap_or_else(|_| "http://localhost:8090".to_string());

    let api_token = env::var("TANDOOR_API_TOKEN").unwrap_or_else(|_| {
        Command::new("pass")
            .args(["show", "meal-planner/tandoor/api_token"])
            .output()
            .ok()
            .and_then(|o| String::from_utf8(o.stdout).ok())
            .unwrap_or_default()
            .trim()
            .to_string()
    });

    (base_url, api_token)
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

fn run_windmill_script(script_path: &str, args: &serde_json::Value) -> Result<serde_json::Value, String> {
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

fn run_binary(binary_name: &str, input: &str) -> Result<serde_json::Value, String> {
    let mut child = Command::new("cargo")
        .args(["run", "--release", "--bin", binary_name])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .map_err(|e| e.to_string())?;

    use std::io::Write;
    if let Some(stdin) = child.stdin.as_mut() {
        stdin
            .write_all(input.as_bytes())
            .map_err(|e| e.to_string())?;
    }

    let output = child.wait_with_output().map_err(|e| e.to_string())?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    serde_json::from_str(&stdout).map_err(|e| format!("Parse error: {} - Raw: {}", e, stdout))
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
fn test_tandoor_recipe_delete_script_exists() {
    println!("\n=== Checking Tandoor Recipe Delete Script ===");

    let script_path = "windmill/f/tandoor/recipe_delete.sh";
    println!("\nScript: {}", script_path);

    if !std::path::Path::new(script_path).exists() {
        panic!("Script file should exist: {}", script_path);
    }
    println!("  ✓ Script file exists");

    let yaml_path = "windmill/f/tandoor/recipe_delete.script.yaml";
    if !std::path::Path::new(yaml_path).exists() {
        panic!("Script YAML should exist: {}", yaml_path);
    }
    println!("  ✓ Script YAML exists");

    println!("\n✓ Tandoor recipe_delete script files exist");
}

#[test]
fn test_tandoor_recipe_delete_schema() {
    println!("\n=== Validating Tandoor Recipe Delete Schema ===");

    let yaml_path = "windmill/f/tandoor/recipe_delete.script.yaml";
    let content = std::fs::read_to_string(yaml_path)
        .unwrap_or_else(|e| panic!("Failed to read {}: {}", yaml_path, e));

    assert!(content.contains("summary:"), "Should have summary");
    assert!(content.contains("description:"), "Should have description");
    assert!(content.contains("recipe_id"), "Should have recipe_id property");
    assert!(content.contains("tandoor"), "Should have tandoor property");

    println!("  ✓ Has summary");
    println!("  ✓ Has description");
    println!("  ✓ Has recipe_id property");
    println!("  ✓ Has tandoor property");

    println!("\n✓ Schema validation passed");
}

#[test]
fn test_tandoor_recipe_delete_binary() {
    println!("\n=== Testing Tandoor Recipe Delete Binary ===");

    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "recipe_id": 999999999
    })
    .to_string();

    let result = run_binary("tandoor_recipe_delete", &input);
    assert!(result.is_ok(), "Delete should complete without panicking: {:?}", result);
    println!("  ✓ Binary executes without panic");

    let output = result.unwrap();
    assert!(output["success"].is_boolean(), "Response should have success field");
    println!("  ✓ Response has success field");

    println!("\n✓ Binary test passed");
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_tandoor_recipe_delete() {
    skip_if_not_deployed!("recipe_delete");
    skip_if_resource_not_configured!("u/admin/tandoor_api");

    let (tandoor_url, tandoor_token) = get_tandoor_creds();

    let result = run_windmill_script(
        "f/tandoor/recipe_delete.sh",
        &json!({
            "tandoor": {"base_url": tandoor_url, "api_token": tandoor_token},
            "recipe_id": 999999999
        }),
    );

    assert!(result.is_ok(), "Script failed: {:?}", result.err());
    let output = result.unwrap();

    assert_eq!(output["success"], true, "Expected success: true");
}

#[test]
fn test_coverage() {
    println!("\n========================================");
    println!("Tandoor Recipe Delete Test Coverage");
    println!("========================================\n");

    println!("✅ Tests validated:");
    println!("   [x] Script files exist (recipe_delete.sh, recipe_delete.script.yaml)");
    println!("   [x] Schema has required fields (summary, description, recipe_id, tandoor)");
    println!("   [x] Binary executes without panic");
    println!("   [x] Response has success field");
    println!();

    println!("📝 Manual Testing Instructions:");
    println!();
    println!("   For Windmill deployment:");
    println!("   1. Deploy script:");
    println!("      wmill script push f/tandoor/recipe_delete.sh");
    println!();
    println!("   2. Configure resource:");
    println!("      - u/admin/tandoor_api (base_url + api_token)");
    println!();
    println!("   3. Test in Windmill UI:");
    println!("      - Run script with valid recipe_id");
    println!("      - Verify success response");
    println!("      - Test with invalid recipe_id (expect error)");
    println!();

    println!("   Example test input:");
    println!(r#"{{"tandoor": {{"base_url": "http://localhost:8090", "api_token": "..."}}, "recipe_id": 123}}"#);
    println!();

    println!("========================================\n");
}
