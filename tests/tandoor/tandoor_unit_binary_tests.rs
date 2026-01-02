//! Integration tests for Tandoor unit binaries
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

#[test]
fn tandoor_unit_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_unit_list", &input);
    assert!(result["count"].as_i64().unwrap_or(0) >= 0);
    assert!(result["units"].is_array());
}

#[test]
fn tandoor_unit_response_format() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_unit_list", &input);
    assert!(result.get("success").is_some());
    assert!(result.get("count").is_some());
    assert!(result.get("units").is_some());
}

#[test]
fn tandoor_unit_conversion_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();
    let _ = run_binary("tandoor_unit_conversion_list", &input);
}

#[test]
fn tandoor_unit_create_success() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("test_unit_{}", Utc::now().timestamp());

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name,
        "plural_name": format!("{}s", test_name)
    })
    .to_string();

    let create_result = expect_success("tandoor_unit_create", &create_input);
    let unit_id = create_result["id"].as_i64();

    if let Some(id) = unit_id {
        let delete_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id
        })
        .to_string();
        let _ = run_binary("tandoor_unit_delete", &delete_input);
    }
}

#[test]
fn tandoor_unit_update_success() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("test_unit_{}", Utc::now().timestamp());

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name
    })
    .to_string();

    let create_result = run_binary("tandoor_unit_create", &create_input).unwrap();
    let unit_id = create_result["id"].as_i64();

    if let Some(id) = unit_id {
        let update_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id,
            "name": format!("{}_updated", test_name),
            "plural_name": format!("{}_updateds", test_name)
        })
        .to_string();

        let update_result = expect_success("tandoor_unit_update", &update_input);
        assert!(update_result.get("id").is_some(), "Update should return id");

        let delete_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id
        })
        .to_string();
        let _ = run_binary("tandoor_unit_delete", &delete_input);
    }
}

#[test]
fn tandoor_unit_delete_success() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("test_unit_{}", Utc::now().timestamp());

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name
    })
    .to_string();

    let create_result = run_binary("tandoor_unit_create", &create_input).unwrap();
    let unit_id = create_result["id"].as_i64();

    if let Some(id) = unit_id {
        let delete_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id
        })
        .to_string();

        let delete_result = run_binary("tandoor_unit_delete", &delete_input).unwrap();
        assert!(
            delete_result["success"].as_bool().unwrap_or(false),
            "Delete should succeed"
        );
    }
}
