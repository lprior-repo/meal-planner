//! Integration tests for Tandoor recipe list/get binaries
//! Tests run against live APIs with credentials from environment or pass

use serde_json::{json, Value};
use std::env;
use std::process::{Command, Stdio};

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

fn expect_failure(binary_name: &str, input: &str) {
    let result = run_binary(binary_name, input);
    assert!(
        result.is_ok(),
        "Binary {} should fail but got: {:?}",
        binary_name,
        result
    );
    let value = result.unwrap();
    assert!(
        !value
            .get("success")
            .and_then(|v| v.as_bool())
            .unwrap_or(true),
        "Binary {} should fail but succeeded: {}",
        binary_name,
        value
    );
}

#[test]
fn tandoor_recipe_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_recipe_list", &input);
    assert!(result["count"].as_i64().unwrap_or(0) >= 0);
    assert!(result["recipes"].is_array());
}

#[test]
fn tandoor_recipe_list_with_pagination() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "page": 1,
        "page_size": 2
    })
    .to_string();

    let result = expect_success("tandoor_recipe_list", &input);
    let recipes = result["recipes"].as_array().unwrap();
    assert!(recipes.len() <= 2);
}

#[test]
fn tandoor_recipe_get_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "recipe_id": 1
    })
    .to_string();

    let result = expect_success("tandoor_recipe_get", &input);
    assert!(result["recipe"].is_object());
}

#[test]
fn tandoor_recipe_list_response_format() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_recipe_list", &input);
    assert!(result.get("success").is_some());
    assert!(result.get("count").is_some());
    assert!(result.get("recipes").is_some());
}

#[test]
fn tandoor_recipe_get_missing_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();
    expect_failure("tandoor_recipe_get", &input);
}

#[test]
fn tandoor_recipe_list_multiple_pages() {
    let (url, token) = get_tandoor_creds();
    for page in [1, 2, 3] {
        let input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "page": page,
            "page_size": 2
        })
        .to_string();
        let _ = run_binary("tandoor_recipe_list", &input);
    }
}

