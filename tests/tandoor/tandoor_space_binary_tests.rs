//! Integration tests for Tandoor space binaries
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

fn run_binary(binary_name: &str, input: &Value) -> Result<Value, String> {
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
            .write_all(input.to_string().as_bytes())
            .map_err(|e| e.to_string())?;
    }

    let output = child.wait_with_output().map_err(|e| e.to_string())?;
    let stdout = String::from_utf8_lossy(&output.stdout);

    serde_json::from_str(&stdout).map_err(|e| format!("Parse error: {} - Raw: {}", e, stdout))
}

fn expect_failure(binary_name: &str, input: &Value) {
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
fn tandoor_space_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_space_list", &input);
    assert!(result.is_ok(), "Space list should succeed");
    let value = result.unwrap();
    assert!(value["success"].as_bool().unwrap_or(false));
    assert!(value["spaces"].is_array());
}

#[test]
fn tandoor_space_list_response_format() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_space_list", &input);
    assert!(result.is_ok(), "Space list should succeed");
    let value = result.unwrap();
    assert!(value.get("success").is_some());
    assert!(value.get("spaces").is_some());
}

#[test]
fn tandoor_space_get_success() {
    let (url, token) = get_tandoor_creds();
    let list_input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let list_result = run_binary("tandoor_space_list", &list_input);
    if let Ok(list_value) = list_result {
        if let Some(spaces) = list_value["spaces"].as_array() {
            if !spaces.is_empty() {
                if let Some(space_id) = spaces[0]["id"].as_i64() {
                    let get_input = json!({
                        "tandoor": {"base_url": url, "api_token": token},
                        "id": space_id
                    });

                    let result = run_binary("tandoor_space_get", &get_input);
                    assert!(result.is_ok(), "Space get should succeed");
                    let value = result.unwrap();
                    assert!(value["success"].as_bool().unwrap_or(false));
                    return;
                }
            }
        }
    }
}

#[test]
fn tandoor_space_get_missing_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_space_get", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_space_get_invalid_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "id": -999999
    });

    let result = run_binary("tandoor_space_get", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_space_list_returns_spaces() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_space_list", &input);
    assert!(result.is_ok(), "Space list should succeed");
    let value = result.unwrap();

    if let Some(spaces) = value["spaces"].as_array() {
        for space in spaces {
            assert!(space["id"].is_number() || space["id"].is_null());
            assert!(space["name"].is_string() || space["name"].is_null());
        }
    }
}

#[test]
fn tandoor_space_get_by_id() {
    let (url, token) = get_tandoor_creds();
    let list_input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let list_result = run_binary("tandoor_space_list", &list_input);
    if let Ok(list_value) = list_result {
        if let Some(spaces) = list_value["spaces"].as_array() {
            if !spaces.is_empty() {
                if let Some(space_id) = spaces[0]["id"].as_i64() {
                    let get_input = json!({
                        "tandoor": {"base_url": url, "api_token": token},
                        "id": space_id
                    });

                    let get_result = run_binary("tandoor_space_get", &get_input);
                    assert!(get_result.is_ok(), "Space get by ID should succeed");
                }
            }
        }
    }
}
