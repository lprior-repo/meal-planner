//! Integration tests for Tandoor supermarket binaries
//! Tests run against live APIs with credentials from environment or pass

use chrono::Utc;
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

#[test]
fn tandoor_supermarket_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_supermarket_list", &input);
    assert!(result.is_ok(), "Supermarket list should succeed");
    let value = result.unwrap();
    assert!(value["success"].as_bool().unwrap_or(false));
    assert!(value["count"].as_i64().unwrap_or(0) >= 0);
    assert!(value["supermarkets"].is_array());
}

#[test]
fn tandoor_supermarket_list_with_pagination() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "page": 1,
        "page_size": 10
    });

    let result = run_binary("tandoor_supermarket_list", &input);
    assert!(result.is_ok(), "Supermarket list with pagination should succeed");
    let value = result.unwrap();
    assert!(value["success"].as_bool().unwrap_or(false));
}

#[test]
fn tandoor_supermarket_get_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "id": 1
    });

    let result = run_binary("tandoor_supermarket_get", &input);
    assert!(result.is_ok(), "Supermarket get should complete without error");
}

#[test]
fn tandoor_supermarket_get_missing_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_supermarket_get", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_supermarket_get_invalid_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "id": -999999
    });

    let result = run_binary("tandoor_supermarket_get", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_supermarket_create_success() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("Test Supermarket {}", Utc::now().timestamp());

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name,
        "description": "Created by integration test"
    });

    let result = run_binary("tandoor_supermarket_create", &create_input);
    assert!(result.is_ok(), "Supermarket create should succeed");
    let value = result.unwrap();
    assert!(value["success"].as_bool().unwrap_or(false));
    assert!(value["id"].as_i64().unwrap_or(0) > 0);

    if let Some(id) = value["id"].as_i64() {
        let delete_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id
        });
        let _ = run_binary("tandoor_supermarket_delete", &delete_input);
    }
}

#[test]
fn tandoor_supermarket_create_minimal() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("Minimal Supermarket {}", Utc::now().timestamp());

    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name
    });

    let result = run_binary("tandoor_supermarket_create", &input);
    assert!(result.is_ok(), "Supermarket create with minimal input should succeed");
}

#[test]
fn tandoor_supermarket_update_success() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("Update Test Supermarket {}", Utc::now().timestamp());

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name.clone()
    });

    let create_result = run_binary("tandoor_supermarket_create", &create_input);
    if let Ok(value) = create_result {
        if let Some(id) = value["id"].as_i64() {
            let update_input = json!({
                "tandoor": {"base_url": url, "api_token": token},
                "id": id,
                "name": format!("{} Updated", test_name),
                "description": "Updated description"
            });

            let result = run_binary("tandoor_supermarket_update", &update_input);
            assert!(result.is_ok(), "Supermarket update should succeed");
            let update_value = result.unwrap();
            assert!(update_value["success"].as_bool().unwrap_or(false));

            let delete_input = json!({
                "tandoor": {"base_url": url, "api_token": token},
                "id": id
            });
            let _ = run_binary("tandoor_supermarket_delete", &delete_input);
        }
    }
}

#[test]
fn tandoor_supermarket_update_missing_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": "Updated Name"
    });

    let result = run_binary("tandoor_supermarket_update", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_supermarket_delete_success() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("Delete Test Supermarket {}", Utc::now().timestamp());

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name
    });

    let create_result = run_binary("tandoor_supermarket_create", &create_input);
    if let Ok(value) = create_result {
        if let Some(id) = value["id"].as_i64() {
            let delete_input = json!({
                "tandoor": {"base_url": url, "api_token": token},
                "id": id
            });

            let result = run_binary("tandoor_supermarket_delete", &delete_input);
            assert!(result.is_ok(), "Supermarket delete should succeed");
            let delete_value = result.unwrap();
            assert!(delete_value["success"].as_bool().unwrap_or(false));
        }
    }
}

#[test]
fn tandoor_supermarket_delete_invalid_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "id": -999999
    });

    let result = run_binary("tandoor_supermarket_delete", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_supermarket_list_response_format() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_supermarket_list", &input);
    assert!(result.is_ok(), "List should succeed");
    let value = result.unwrap();
    assert!(value.get("success").is_some());
    assert!(value.get("count").is_some());
    assert!(value.get("supermarkets").is_some());
}
