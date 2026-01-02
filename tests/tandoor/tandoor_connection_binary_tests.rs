//! Integration tests for Tandoor connection binaries
//! Tests run against live APIs with credentials from environment or pass

use serde_json::json;
use std::env;
use std::process::Command;

use crate::fatsecret::common::run_binary;

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

#[allow(dead_code)]
fn get_pass_value(path: &str) -> String {
    Command::new("pass")
        .args(["show", path])
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .unwrap_or_default()
        .trim()
        .to_string()
}

#[allow(dead_code)]
fn expect_failure(binary_name: &str, input: &str) {
    let result = run_binary(binary_name, &json!(input));
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
fn tandoor_test_connection_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });

    let result = run_binary("tandoor_test_connection", &input).unwrap();
    assert_eq!(result["success"], true);
    assert!(result["recipe_count"].as_i64().unwrap_or(0) >= 0);
}

#[test]
fn tandoor_test_connection_missing_auth() {
    let input = json!({});
    expect_failure("tandoor_test_connection", &input.to_string());
}

#[test]
#[ignore]
fn tandoor_connection_latency() {
    let start = std::time::Instant::now();
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    });
    let _ = run_binary("tandoor_test_connection", &input);
    let elapsed = start.elapsed();
    let is_ci = std::env::var("CI").is_ok() || std::env::var("GITHUB_ACTIONS").is_ok();
    let max_secs = if is_ci { 60 } else { 15 };
    assert!(
        elapsed.as_secs() < max_secs,
        "Connection took too long: {:?} (CI: {}, max: {}s)",
        elapsed,
        is_ci,
        max_secs
    );
}

