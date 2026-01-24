//! Unit tests for Tandoor unit conversion binary
//! Tests the tandoor_unit_convert binary logic without requiring a live Tandoor server

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

#[test]
fn tandoor_unit_convert_cup_to_ml_success() {
    let input = json!({
        "from_unit": "cup",
        "to_unit": "ml",
        "amount": 2.5
    })
    .to_string();

    let result = run_binary("tandoor_unit_convert", &input);
    assert!(result.is_ok(), "Unit conversion should succeed");
    let value = result.unwrap();

    assert!(value["success"].as_bool().unwrap_or(false));
    assert_eq!(value["from_unit"].as_str(), Some("cup"));
    assert_eq!(value["to_unit"].as_str(), Some("ml"));
    assert_eq!(value["converted_amount"].as_f64().unwrap(), 600.0);
}

#[test]
fn tandoor_unit_convert_ml_to_cup_success() {
    let input = json!({
        "from_unit": "ml",
        "to_unit": "cup",
        "amount": 600.0
    })
    .to_string();

    let result = run_binary("tandoor_unit_convert", &input);
    assert!(result.is_ok(), "Unit conversion should succeed");
    let value = result.unwrap();

    assert!(value["success"].as_bool().unwrap_or(false));
    assert_eq!(value["from_unit"].as_str(), Some("ml"));
    assert_eq!(value["to_unit"].as_str(), Some("cup"));
    assert_eq!(value["converted_amount"].as_f64().unwrap(), 2.5);
}

#[test]
fn tandoor_unit_convert_oz_to_g_success() {
    let input = json!({
        "from_unit": "oz",
        "to_unit": "g",
        "amount": 8.0
    })
    .to_string();

    let result = run_binary("tandoor_unit_convert", &input);
    assert!(result.is_ok(), "Unit conversion should succeed");
    let value = result.unwrap();

    assert!(value["success"].as_bool().unwrap_or(false));
    assert_eq!(value["from_unit"].as_str(), Some("oz"));
    assert_eq!(value["to_unit"].as_str(), Some("g"));
    // 8 oz * 28.35 g/oz = 226.8 g
    assert_eq!(value["converted_amount"].as_f64().unwrap(), 226.8);
}

#[test]
fn tandoor_unit_convert_g_to_oz_success() {
    let input = json!({
        "from_unit": "g",
        "to_unit": "oz",
        "amount": 226.8
    })
    .to_string();

    let result = run_binary("tandoor_unit_convert", &input);
    assert!(result.is_ok(), "Unit conversion should succeed");
    let value = result.unwrap();

    assert!(value["success"].as_bool().unwrap_or(false));
    assert_eq!(value["from_unit"].as_str(), Some("g"));
    assert_eq!(value["to_unit"].as_str(), Some("oz"));
    // 226.8 g / 28.35 g/oz = 8 oz
    assert_eq!(value["converted_amount"].as_f64().unwrap(), 8.0);
}

#[test]
fn tandoor_unit_convert_negative_amount_fails() {
    let input = json!({
        "from_unit": "cup",
        "to_unit": "ml",
        "amount": -1.0
    })
    .to_string();

    let result = run_binary("tandoor_unit_convert", &input);
    assert!(result.is_ok(), "Unit conversion should handle error case");
    let value = result.unwrap();

    assert!(!value["success"].as_bool().unwrap_or(true));
    assert!(value["error"].as_str().is_some());
}

#[test]
fn tandoor_unit_convert_unsupported_conversion_fails() {
    let input = json!({
        "from_unit": "meter",
        "to_unit": "kilogram",
        "amount": 1.0
    })
    .to_string();

    let result = run_binary("tandoor_unit_convert", &input);
    assert!(result.is_ok(), "Unit conversion should handle error case");
    let value = result.unwrap();

    assert!(!value["success"].as_bool().unwrap_or(true));
    assert!(value["error"].as_str().is_some());
}
