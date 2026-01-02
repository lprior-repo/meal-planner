//! Integration tests for FatSecret Recipe Types binary
//!
//! Tests: fatsecret_recipe_types_get

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use serde_json::json;
use std::io::Write;
use std::process::{Command, Stdio};

fn run_binary(binary_name: &str, input: &serde_json::Value) -> Result<serde_json::Value, String> {
    let binary_path = format!("./target/debug/{}", binary_name);
    if !std::path::Path::new(&binary_path).exists() {
        return Err(format!("Binary not found: {}", binary_path));
    }

    let mut child = Command::new(&binary_path)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| format!("Failed to spawn {}: {}", binary_name, e))?;

    if let Some(ref mut stdin) = child.stdin {
        stdin
            .write_all(input.to_string().as_bytes())
            .map_err(|e| format!("Failed to write stdin: {}", e))?;
    }

    let output = child
        .wait_with_output()
        .map_err(|e| format!("Failed to wait for {}: {}", binary_name, e))?;

    let exit_code = output.status.code().unwrap_or(-1);
    let stdout = String::from_utf8_lossy(&output.stdout);

    if !output.status.success() {
        return Err(format!(
            "Binary {} exited with {}: {}",
            binary_name, exit_code, stdout
        ));
    }

    serde_json::from_str(&stdout).map_err(|e| {
        format!(
            "Failed to parse JSON from {}: {} (output: {})",
            binary_name, e, stdout
        )
    })
}

fn get_fatsecret_credentials() -> Option<(String, String)> {
    use std::env;
    fn get_pass_value(path: &str) -> Option<String> {
        let output = Command::new("pass").args(["show", path]).output().ok()?;
        String::from_utf8(output.stdout)
            .ok()?
            .trim()
            .to_string()
            .into()
    }

    let consumer_key = env::var("FATSECRET_CONSUMER_KEY")
        .ok()
        .or_else(|| get_pass_value("meal-planner/fatsecret/consumer_key"))?;

    let consumer_secret = env::var("FATSECRET_CONSUMER_SECRET")
        .ok()
        .or_else(|| get_pass_value("meal-planner/fatsecret/consumer_secret"))?;

    Some((consumer_key, consumer_secret))
}

#[test]
fn test_fatsecret_recipe_types_get_no_params() {
    let result = run_binary("fatsecret_recipe_types_get", &json!({}));
    assert!(result.is_ok(), "Binary should execute without params");
}

#[test]
fn test_fatsecret_recipe_types_get_with_credentials() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1
    });

    let result = run_binary("fatsecret_recipe_types_get", &input);
    assert!(result.is_ok(), "Binary should execute");
}

#[test]
fn test_fatsecret_recipe_types_get_response_format() {
    let result = run_binary("fatsecret_recipe_types_get", &json!({}));
    let value = result.expect("Binary should execute");
    assert!(
        value.get("success").is_some(),
        "Response should have success field"
    );
    assert!(
        value.get("recipe_types").is_some(),
        "Response should have recipe_types field"
    );
}

#[test]
fn test_fatsecret_recipe_types_get_returns_array() {
    let result = run_binary("fatsecret_recipe_types_get", &json!({}));
    let value = result.expect("Binary should execute");
    assert!(
        value["recipe_types"].is_array(),
        "recipe_types should be an array"
    );
}

#[test]
fn test_fatsecret_recipe_types_get_empty_params() {
    let input = json!({});
    let result = run_binary("fatsecret_recipe_types_get", &input);
    assert!(result.is_ok(), "Binary should accept empty params");
}
