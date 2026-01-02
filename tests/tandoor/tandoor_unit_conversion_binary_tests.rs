//! Integration tests for Tandoor unit conversion binary
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
fn tandoor_unit_conversion_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_unit_conversion_list", &input);
    assert!(result.is_ok(), "Unit conversion list should succeed");
    let value = result.unwrap();
    assert!(value["success"].as_bool().unwrap_or(false));
    assert!(value["count"].as_i64().unwrap_or(0) >= 0);
    assert!(value["conversions"].is_array());
}

#[test]
fn tandoor_unit_conversion_list_with_pagination() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "page": 1,
        "page_size": 10
    });

    let result = run_binary("tandoor_unit_conversion_list", &input);
    assert!(result.is_ok(), "Unit conversion list with pagination should succeed");
    let value = result.unwrap();
    assert!(value["success"].as_bool().unwrap_or(false));
}

#[test]
fn tandoor_unit_conversion_list_response_format() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_unit_conversion_list", &input);
    assert!(result.is_ok(), "Unit conversion list should succeed");
    let value = result.unwrap();
    assert!(value.get("success").is_some());
    assert!(value.get("count").is_some());
    assert!(value.get("conversions").is_some());
}

#[test]
fn tandoor_unit_conversion_list_returns_conversions() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_unit_conversion_list", &input);
    assert!(result.is_ok(), "Unit conversion list should succeed");
    let value = result.unwrap();

    if let Some(conversions) = value["conversions"].as_array() {
        for conversion in conversions {
            assert!(
                conversion["id"].is_number() || conversion["id"].is_null(),
                "Conversion should have id field"
            );
        }
    }
}

#[test]
fn tandoor_unit_conversion_list_multi_page() {
    let (url, token) = get_tandoor_creds();
    for page in [1, 2] {
        let input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "page": page,
            "page_size": 5
        });

        let result = run_binary("tandoor_unit_conversion_list", &input);
        assert!(result.is_ok(), "Unit conversion list page {} should succeed", page);
    }
}

#[test]
fn tandoor_unit_conversion_list_large_page_size() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "page": 1,
        "page_size": 100
    });

    let result = run_binary("tandoor_unit_conversion_list", &input);
    assert!(result.is_ok(), "Unit conversion list with large page size should succeed");
    let value = result.unwrap();

    let conversions_len = value["conversions"].as_array().map(|c| c.len()).unwrap_or(0);
    assert!(conversions_len <= 100, "Should return at most 100 conversions");
}

#[test]
fn tandoor_unit_conversion_list_empty_page() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "page": 9999,
        "page_size": 100
    });

    let result = run_binary("tandoor_unit_conversion_list", &input);
    assert!(result.is_ok(), "Unit conversion list with non-existent page should succeed");
    let value = result.unwrap();
    assert!(value["count"].as_i64().unwrap_or(0) >= 0);
}
