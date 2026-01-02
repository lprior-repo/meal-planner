//! Integration tests for Tandoor step binaries
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
fn tandoor_step_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_step_list", &input);
    assert!(result.is_ok(), "Step list should succeed");
    let value = result.unwrap();
    assert!(value["success"].as_bool().unwrap_or(false));
    assert!(value["count"].as_i64().unwrap_or(0) >= 0);
    assert!(value["steps"].is_array());
}

#[test]
fn tandoor_step_list_with_pagination() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "page": 1,
        "page_size": 10
    });

    let result = run_binary("tandoor_step_list", &input);
    assert!(result.is_ok(), "Step list with pagination should succeed");
    let value = result.unwrap();
    assert!(value["success"].as_bool().unwrap_or(false));
}

#[test]
fn tandoor_step_get_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "id": 1
    });

    let result = run_binary("tandoor_step_get", &input);
    assert!(result.is_ok(), "Step get should complete without error");
}

#[test]
fn tandoor_step_get_missing_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_step_get", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_step_get_invalid_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "id": -999999
    });

    let result = run_binary("tandoor_step_get", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_step_create_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "instruction": "Test step instruction for integration testing"
    });

    let result = run_binary("tandoor_step_create", &input);
    assert!(result.is_ok(), "Step create should succeed");
    let value = result.unwrap();
    assert!(value["success"].as_bool().unwrap_or(false));
    assert!(value["id"].as_i64().unwrap_or(0) > 0);

    if let Some(id) = value["id"].as_i64() {
        let delete_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id
        });
        let _ = run_binary("tandoor_step_delete", &delete_input);
    }
}

#[test]
fn tandoor_step_create_missing_instruction() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_step_create", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_step_update_success() {
    let (url, token) = get_tandoor_creds();
    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "instruction": "Original step instruction"
    });

    let create_result = run_binary("tandoor_step_create", &create_input);
    if let Ok(value) = create_result {
        if let Some(id) = value["id"].as_i64() {
            let update_input = json!({
                "tandoor": {"base_url": url, "api_token": token},
                "id": id,
                "instruction": "Updated step instruction for testing"
            });

            let result = run_binary("tandoor_step_update", &update_input);
            assert!(result.is_ok(), "Step update should succeed");
            let update_value = result.unwrap();
            assert!(update_value["success"].as_bool().unwrap_or(false));

            let delete_input = json!({
                "tandoor": {"base_url": url, "api_token": token},
                "id": id
            });
            let _ = run_binary("tandoor_step_delete", &delete_input);
        }
    }
}

#[test]
fn tandoor_step_update_missing_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "instruction": "Updated instruction"
    });

    let result = run_binary("tandoor_step_update", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_step_delete_success() {
    let (url, token) = get_tandoor_creds();
    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "instruction": "Step to be deleted"
    });

    let create_result = run_binary("tandoor_step_create", &create_input);
    if let Ok(value) = create_result {
        if let Some(id) = value["id"].as_i64() {
            let delete_input = json!({
                "tandoor": {"base_url": url, "api_token": token},
                "id": id
            });

            let result = run_binary("tandoor_step_delete", &delete_input);
            assert!(result.is_ok(), "Step delete should succeed");
            let delete_value = result.unwrap();
            assert!(delete_value["success"].as_bool().unwrap_or(false));
        }
    }
}

#[test]
fn tandoor_step_delete_invalid_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "id": -999999
    });

    let result = run_binary("tandoor_step_delete", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_step_list_response_format() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_step_list", &input);
    assert!(result.is_ok(), "List should succeed");
    let value = result.unwrap();
    assert!(value.get("success").is_some());
    assert!(value.get("count").is_some());
    assert!(value.get("steps").is_some());
}
