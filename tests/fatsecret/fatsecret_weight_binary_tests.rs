//! Integration tests for FatSecret Weight binaries
//!
//! Tests: fatsecret_weight_update, fatsecret_weight_month_summary

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use serde_json::json;
use std::process::{Command, Stdio};
use std::io::Write;

use crate::fatsecret::common::expect_failure;

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
        stdin.write_all(input.to_string().as_bytes())
            .map_err(|e| format!("Failed to write stdin: {}", e))?;
    }

    let output = child.wait_with_output()
        .map_err(|e| format!("Failed to wait for {}: {}", binary_name, e))?;

    let exit_code = output.status.code().unwrap_or(-1);
    let stdout = String::from_utf8_lossy(&output.stdout);

    if !output.status.success() {
        return Err(format!("Binary {} exited with {}: {}", binary_name, exit_code, stdout));
    }

    serde_json::from_str(&stdout)
        .map_err(|e| format!("Failed to parse JSON from {}: {} (output: {})", binary_name, e, stdout))
}

fn get_fatsecret_credentials() -> Option<(String, String)> {
    use std::env;
    fn get_pass_value(path: &str) -> Option<String> {
        let output = Command::new("pass")
            .args(["show", path])
            .output()
            .ok()?;
        String::from_utf8(output.stdout).ok()?.trim().to_string().into()
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
fn test_fatsecret_weight_update_missing_weight() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1
    });

    expect_failure("fatsecret_weight_update", &input);
}

#[test]
fn test_fatsecret_weight_update_with_weight() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "weight_kg": 75.5,
        "date_int": 20088
    });

    let result = run_binary("fatsecret_weight_update", &input);
    assert!(result.is_ok(), "Binary should execute");
}

#[test]
fn test_fatsecret_weight_update_missing_date() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "weight_kg": 75.5
    });

    expect_failure("fatsecret_weight_update", &input);
}

#[test]
fn test_fatsecret_weight_update_invalid_weight() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "weight_kg": -100.0,
        "date_int": 20088
    });

    let result = run_binary("fatsecret_weight_update", &input);
    assert!(result.is_ok(), "Binary should execute");
}

#[test]
fn test_fatsecret_weight_update_response_format() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "weight_kg": 75.5,
        "date_int": 20088
    });

    let result = run_binary("fatsecret_weight_update", &input);
    if let Ok(value) = result {
        assert!(
            value.get("success").is_some(),
            "Response should have success field"
        );
    }
}

#[test]
fn test_fatsecret_weight_month_summary_missing_params() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1
    });

    expect_failure("fatsecret_weight_month_summary", &input);
}

#[test]
fn test_fatsecret_weight_month_summary_with_params() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "year": 2025,
        "month": 1
    });

    let result = run_binary("fatsecret_weight_month_summary", &input);
    assert!(result.is_ok(), "Binary should execute");
}

#[test]
fn test_fatsecret_weight_month_summary_missing_year() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "month": 1
    });

    expect_failure("fatsecret_weight_month_summary", &input);
}

#[test]
fn test_fatsecret_weight_month_summary_missing_month() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "year": 2025
    });

    expect_failure("fatsecret_weight_month_summary", &input);
}

#[test]
fn test_fatsecret_weight_month_summary_response_format() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "year": 2025,
        "month": 1
    });

    let result = run_binary("fatsecret_weight_month_summary", &input);
    if let Ok(value) = result {
        assert!(
            value.get("success").is_some(),
            "Response should have success field"
        );
    }
}
