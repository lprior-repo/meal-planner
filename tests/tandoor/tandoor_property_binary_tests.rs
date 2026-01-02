//! Integration tests for Tandoor property binaries
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

#[test]
fn tandoor_property_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_property_list", &input);
    assert!(result.is_ok(), "Property list should succeed");
    let value = result.unwrap();
    assert!(value["success"].as_bool().unwrap_or(false));
    assert!(value["count"].as_i64().unwrap_or(0) >= 0);
    assert!(value["properties"].is_array());
}

#[test]
fn tandoor_property_list_with_pagination() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "page": 1,
        "page_size": 10
    });

    let result = run_binary("tandoor_property_list", &input);
    assert!(result.is_ok(), "Property list with pagination should succeed");
    let value = result.unwrap();
    assert!(value["success"].as_bool().unwrap_or(false));
}

#[test]
fn tandoor_property_get_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "property_id": 1
    });

    let result = run_binary("tandoor_property_get", &input);
    assert!(result.is_ok(), "Property get should complete without error");
}

#[test]
fn tandoor_property_get_missing_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_property_get", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_property_get_invalid_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "property_id": -999999
    });

    let result = run_binary("tandoor_property_get", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_property_create_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "property_amount": 100.0,
        "property_type": 1
    });

    let result = run_binary("tandoor_property_create", &input);
    assert!(result.is_ok(), "Property create should succeed");
    let value = result.unwrap();
    assert!(value["success"].as_bool().unwrap_or(false));
    assert!(value["property"].is_object());
}

#[test]
fn tandoor_property_create_missing_required() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "property_amount": 100.0
    });

    let result = run_binary("tandoor_property_create", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_property_update_success() {
    let (url, token) = get_tandoor_creds();
    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "property_amount": 50.0,
        "property_type": 1
    });

    let create_result = run_binary("tandoor_property_create", &create_input);
    if let Ok(value) = create_result {
        if let Some(id) = value["property"]["id"].as_i64() {
            let update_input = json!({
                "tandoor": {"base_url": url, "api_token": token},
                "property_id": id,
                "property_amount": 150.0
            });

            let result = run_binary("tandoor_property_update", &update_input);
            assert!(result.is_ok(), "Property update should succeed");
            let update_value = result.unwrap();
            assert!(update_value["success"].as_bool().unwrap_or(false));

            let delete_input = json!({
                "tandoor": {"base_url": url, "api_token": token},
                "property_id": id
            });
            let _ = run_binary("tandoor_property_delete", &delete_input);
        }
    }
}

#[test]
fn tandoor_property_update_missing_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "property_amount": 200.0
    });

    let result = run_binary("tandoor_property_update", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_property_delete_success() {
    let (url, token) = get_tandoor_creds();
    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "property_amount": 75.0,
        "property_type": 1
    });

    let create_result = run_binary("tandoor_property_create", &create_input);
    if let Ok(value) = create_result {
        if let Some(id) = value["property"]["id"].as_i64() {
            let delete_input = json!({
                "tandoor": {"base_url": url, "api_token": token},
                "property_id": id
            });

            let result = run_binary("tandoor_property_delete", &delete_input);
            assert!(result.is_ok(), "Property delete should succeed");
            let delete_value = result.unwrap();
            assert!(delete_value["success"].as_bool().unwrap_or(false));
        }
    }
}

#[test]
fn tandoor_property_delete_invalid_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "property_id": -999999
    });

    let result = run_binary("tandoor_property_delete", &input);
    assert!(result.is_ok(), "Binary should complete without panic");
}

#[test]
fn tandoor_property_list_response_format() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_property_list", &input);
    assert!(result.is_ok(), "List should succeed");
    let value = result.unwrap();
    assert!(value.get("success").is_some());
    assert!(value.get("count").is_some());
    assert!(value.get("properties").is_some());
}
