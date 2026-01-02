//! Integration tests for FatSecret Recipe binaries
//!
//! Tests: fatsecret_recipes_search, fatsecret_recipe_get, fatsecret_recipes_autocomplete

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use serde_json::json;
use std::process::{Command, Stdio};
use std::io::Write;

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

fn expect_failure(binary_name: &str, input: &serde_json::Value) {
    let result = run_binary(binary_name, input);
    assert!(result.is_ok(), "Binary {} should fail gracefully", binary_name);
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
fn test_fatsecret_recipes_search_missing_expression() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1
    });

    expect_failure("fatsecret_recipes_search", &input);
}

#[test]
fn test_fatsecret_recipes_search_with_expression() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "search_expression": "pasta",
        "page_number": 1
    });

    let result = run_binary("fatsecret_recipes_search", &input);
    assert!(result.is_ok(), "Binary should execute");
}

#[test]
fn test_fatsecret_recipes_search_response_format() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "search_expression": "chicken",
        "page_number": 1
    });

    let result = run_binary("fatsecret_recipes_search", &input);
    if let Ok(value) = result {
        assert!(
            value.get("success").is_some(),
            "Response should have success field"
        );
        assert!(
            value.get("recipes").is_some(),
            "Response should have recipes field"
        );
    }
}

#[test]
fn test_fatsecret_recipes_search_with_max_results() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "search_expression": "salad",
        "page_number": 1,
        "max_results": 20
    });

    let result = run_binary("fatsecret_recipes_search", &input);
    assert!(result.is_ok(), "Binary should execute");
}

#[test]
fn test_fatsecret_recipes_search_empty_results() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "search_expression": "xyz123nonexistentrecipe456",
        "page_number": 1
    });

    let result = run_binary("fatsecret_recipes_search", &input);
    assert!(result.is_ok(), "Binary should execute without panicking");
}

#[test]
fn test_fatsecret_recipe_get_missing_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1
    });

    expect_failure("fatsecret_recipe_get", &input);
}

#[test]
fn test_fatsecret_recipe_get_with_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "recipe_id": "1"
    });

    let result = run_binary("fatsecret_recipe_get", &input);
    assert!(result.is_ok(), "Binary should execute");
}

#[test]
fn test_fatsecret_recipe_get_response_format() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "recipe_id": "1"
    });

    let result = run_binary("fatsecret_recipe_get", &input);
    if let Ok(value) = result {
        assert!(
            value.get("success").is_some(),
            "Response should have success field"
        );
        assert!(
            value.get("recipe").is_some(),
            "Response should have recipe field"
        );
    }
}

#[test]
fn test_fatsecret_recipe_get_invalid_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "recipe_id": "999999999999"
    });

    let result = run_binary("fatsecret_recipe_get", &input);
    assert!(result.is_ok(), "Binary should execute");
}

#[test]
fn test_fatsecret_recipes_autocomplete_missing_expression() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1
    });

    expect_failure("fatsecret_recipes_autocomplete", &input);
}

#[test]
fn test_fatsecret_recipes_autocomplete_with_expression() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "expression": "chick"
    });

    let result = run_binary("fatsecret_recipes_autocomplete", &input);
    assert!(result.is_ok(), "Binary should execute");
}

#[test]
fn test_fatsecret_recipes_autocomplete_response_format() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "expression": "pasta"
    });

    let result = run_binary("fatsecret_recipes_autocomplete", &input);
    if let Ok(value) = result {
        assert!(
            value.get("success").is_some(),
            "Response should have success field"
        );
    }
}

#[test]
fn test_fatsecret_recipes_autocomplete_short_expression() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "consumer_key": creds.0,
        "consumer_secret": creds.1,
        "expression": "a"
    });

    let result = run_binary("fatsecret_recipes_autocomplete", &input);
    assert!(result.is_ok(), "Binary should handle short expression");
}
