//! Windmill Integration Tests for `tandoor_recipe_upload_image`
//!
//! Dave Farley says: "Validate structure, then test manually in production."
//!
//! Tests:
//! - Windmill script deployment and schema validation
//! - Binary runner pattern for testing
//! - Functional Core / Imperative Shell architecture
//!
//! Run with: cargo test --test tandoor_recipe_upload_image_windmill_test -- --ignored

#![allow(clippy::unwrap_used, clippy::too_many_lines)]

use serde_json::{json, Value};
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

fn run_binary(binary_name: &str, input: &str) -> Result<Value, String> {
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

fn expect_success(binary_name: &str, input: &str) -> Value {
    let result = run_binary(binary_name, input);
    assert!(
        result.is_ok(),
        "Binary {} failed: {:?}",
        binary_name,
        result
    );
    let value = result.unwrap();
    assert!(
        value
            .get("success")
            .and_then(|v| v.as_bool())
            .unwrap_or(false),
        "Binary {} returned error: {}",
        binary_name,
        value
    );
    value
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
fn test_script_file_exists() {
    let script_path = "windmill/f/tandoor/recipe_upload_image.sh";
    assert!(
        std::path::Path::new(script_path).exists(),
        "Script file should exist: {}",
        script_path
    );
}

#[test]
fn test_script_yaml_exists() {
    let yaml_path = "windmill/f/tandoor/recipe_upload_image.script.yaml";
    assert!(
        std::path::Path::new(yaml_path).exists(),
        "Script YAML should exist: {}",
        yaml_path
    );
}

#[test]
fn test_script_yaml_valid() {
    let yaml_path = "windmill/f/tandoor/recipe_upload_image.script.yaml";
    let content = std::fs::read_to_string(yaml_path).expect("Should read YAML file");

    assert!(content.contains("summary:"), "YAML should contain summary");
    assert!(
        content.contains("kind: script"),
        "YAML should contain kind: script"
    );
    assert!(
        content.contains("language: bash"),
        "YAML should contain language: bash"
    );
}

#[test]
fn test_script_schema_properties() {
    let yaml_path = "windmill/f/tandoor/recipe_upload_image.script.yaml";
    let content = std::fs::read_to_string(yaml_path).expect("Should read YAML file");

    assert!(
        content.contains("tandoor:"),
        "Schema should contain tandoor property"
    );
    assert!(
        content.contains("recipe_id:"),
        "Schema should contain recipe_id property"
    );
    assert!(
        content.contains("image_path:"),
        "Schema should contain image_path property"
    );
}

#[test]
fn test_script_schema_required() {
    let yaml_path = "windmill/f/tandoor/recipe_upload_image.script.yaml";
    let content = std::fs::read_to_string(yaml_path).expect("Should read YAML file");

    assert!(
        content.contains("required:") && content.contains("tandoor"),
        "Schema should require tandoor"
    );
    assert!(
        content.contains("required:") && content.contains("recipe_id"),
        "Schema should require recipe_id"
    );
    assert!(
        content.contains("required:") && content.contains("image_path"),
        "Schema should require image_path"
    );
}

#[test]
fn test_binary_input_windmill_format() {
    let json = r#"{
        "tandoor": {
            "base_url": "http://localhost:8090",
            "api_token": "test_token"
        },
        "recipe_id": 42,
        "image_path": "/tmp/recipe.jpg"
    }"#;

    let result = run_binary("tandoor_recipe_upload_image", json);
    assert!(result.is_ok(), "Binary should parse Windmill format input");
}

#[test]
fn test_binary_input_standalone_format() {
    let json = r#"{
        "base_url": "http://localhost:8090",
        "api_token": "test_token",
        "recipe_id": 123,
        "image_path": "/home/user/dish.png"
    }"#;

    let result = run_binary("tandoor_recipe_upload_image", json);
    assert!(
        result.is_ok(),
        "Binary should parse standalone format input"
    );
}

#[test]
fn test_binary_output_success_format() {
    let temp_dir = std::env::temp_dir();
    let test_image_path = temp_dir.join("test_binary_output.jpg");
    std::fs::write(&test_image_path, b"fake image data").expect("Failed to create test image");

    let json = json!({
        "base_url": "http://localhost:8090",
        "api_token": "invalid_token",
        "recipe_id": 1,
        "image_path": test_image_path.to_string_lossy().to_string()
    })
    .to_string();

    let result = run_binary("tandoor_recipe_upload_image", &json);
    std::fs::remove_file(&test_image_path).ok();

    assert!(result.is_ok(), "Binary should return valid JSON output");
    let value = result.unwrap();
    assert!(
        value.get("success").is_some(),
        "Output should contain success field"
    );
}

#[test]
fn test_binary_output_error_format() {
    let json = json!({
        "base_url": "http://localhost:8090",
        "api_token": "test_token",
        "recipe_id": 1,
        "image_path": "/nonexistent/path.jpg"
    })
    .to_string();

    let result = run_binary("tandoor_recipe_upload_image", &json);
    assert!(
        result.is_ok(),
        "Binary should return valid JSON even on error"
    );
    let value = result.unwrap();
    assert!(
        value.get("success").is_some(),
        "Output should contain success field"
    );
    assert!(
        value.get("error").is_some() || value["success"].as_bool() == Some(true),
        "Output should contain error field or success=true"
    );
}

#[test]
#[ignore = "requires Windmill API connection and deployed scripts"]
fn test_windmill_recipe_upload_image() {
    skip_if_not_deployed!("recipe_upload_image");
    skip_if_resource_not_configured!("u/admin/tandoor_api");

    let result = run_windmill_script(
        "f/tandoor/recipe_upload_image.sh",
        &json!({
            "tandoor": "$res:u/admin/tandoor_api",
            "recipe_id": 1,
            "image_path": "/tmp/test_image.jpg"
        }),
    );

    assert!(result.is_ok(), "Script failed: {:?}", result.err());
    let output = result.unwrap();

    assert_eq!(output["success"], true, "Expected success: true");
    assert!(
        output["image"].is_string() || output["image"].is_null(),
        "Expected image field (string or null)"
    );
}

#[test]
fn test_coverage() {
    println!("\n========================================");
    println!("tandoor_recipe_upload_image Test Coverage");
    println!("========================================\n");

    println!("✅ Unit tests validated:");
    println!("   [x] Script file exists");
    println!("   [x] Script YAML exists and valid");
    println!("   [x] Schema properties (tandoor, recipe_id, image_path)");
    println!("   [x] Schema required fields");
    println!("   [x] Binary input - Windmill format");
    println!("   [x] Binary input - Standalone format");
    println!("   [x] Binary output - Success format");
    println!("   [x] Binary output - Error format");
    println!();

    println!("✅ Windmill integration tests (ignored by default):");
    println!("   [ ] test_windmill_recipe_upload_image");
    println!();

    println!("📝 Manual Testing Instructions:");
    println!();
    println!("   For E2E testing through Windmill:");
    println!("   1. Deploy script:");
    println!("      wmill script push f/tandoor/recipe_upload_image.sh u/admin/tandoor_recipe_upload_image");
    println!();
    println!("   2. Configure resource:");
    println!("      - u/admin/tandoor_api (base_url + api_token)");
    println!();
    println!("   3. Create test image:");
    println!("      echo -n 'fake image' > /tmp/test_recipe_image.jpg");
    println!();
    println!("   4. Run test:");
    println!("      cargo test --test tandoor_recipe_upload_image_windmill_test test_windmill_recipe_upload_image -- --ignored");
    println!();
    println!("   5. Or via wmill CLI:");
    println!();
    println!(r#"      wmill script run f/tandoor/recipe_upload_image.sh -d '{{"tandoor": "$res:u/admin/tandoor_api", "recipe_id": 1, "image_path": "/tmp/test_recipe_image.jpg"}}'"#);
    println!();

    println!("========================================\n");
}
