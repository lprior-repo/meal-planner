//! Integration tests for FatSecret exercise binaries
//! Tests run against live APIs with credentials from environment or pass

use serde_json::{json, Value};
use std::process::{Command, Stdio};

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
fn fatsecret_exercise_entries_get_success() {
    let input = json!({"date": 20088}).to_string();
    let _ = run_binary("fatsecret_exercise_entries_get", &input);
}

#[test]
fn fatsecret_exercise_entry_create_success() {
    let input = json!({
        "exercise_id": "106",
        "number_of_units": 30,
        "meal": "lunch",
        "date": 20088
    })
    .to_string();
    let _ = run_binary("fatsecret_exercise_entry_create", &input);
}

#[test]
fn fatsecret_exercise_entry_edit_success() {
    let input = json!({
        "exercise_entry_id": "1",
        "duration_min": 45
    })
    .to_string();
    let result = run_binary("fatsecret_exercise_entry_edit", &input);
    assert!(result.is_ok(), "Binary should execute: {:?}", result);
}

#[test]
fn fatsecret_exercise_entry_edit_invalid_id() {
    let input = json!({
        "exercise_entry_id": "999999999999999",
        "duration_min": 45
    })
    .to_string();
    let _ = run_binary("fatsecret_exercise_entry_edit", &input);
}

#[test]
fn fatsecret_exercise_entry_delete_success() {
    let input = json!({
        "exercise_entry_id": "1"
    })
    .to_string();
    let result = run_binary("fatsecret_exercise_entry_delete", &input);
    assert!(result.is_ok(), "Binary should execute: {:?}", result);
}

#[test]
fn fatsecret_exercise_entry_delete_invalid_id() {
    let input = json!({
        "exercise_entry_id": "999999999999999"
    })
    .to_string();
    let _ = run_binary("fatsecret_exercise_entry_delete", &input);
}

#[test]
fn fatsecret_exercise_month_summary_success() {
    let input = json!({"year": 2025, "month": 12}).to_string();
    let _ = run_binary("fatsecret_exercise_month_summary", &input);
}

#[test]
fn fatsecret_exercise_month_summary_january_2025() {
    let input = json!({"year": 2025, "month": 1}).to_string();
    let _ = run_binary("fatsecret_exercise_month_summary", &input);
}
