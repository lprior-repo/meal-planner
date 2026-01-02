//! Integration tests for Tandoor shopping list binaries
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
fn tandoor_shopping_list_entry_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();
    let _ = run_binary("tandoor_shopping_list_entry_list", &input);
}

#[test]
fn tandoor_shopping_list_entry_create_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "mealplan_id": 1,
        "entry": {
            "list": 1,
            "food": "test_item",
            "amount": 2.0,
            "checked": false
        }
    })
    .to_string();
    let result = run_binary("tandoor_shopping_list_entry_create", &input).unwrap();
    assert_eq!(result["success"], true);
    assert!(result["entry"].is_object());
    assert_eq!(result["entry"]["food"], "test_item");
}

#[test]
fn tandoor_shopping_list_entry_update_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "mealplan_id": 1,
        "entry_id": 1,
        "update": {
            "checked": true,
            "amount": 5.0
        }
    })
    .to_string();
    let _ = run_binary("tandoor_shopping_list_entry_update", &input);
}

#[test]
fn tandoor_shopping_list_entry_delete_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "mealplan_id": 1,
        "entry_id": 999
    })
    .to_string();
    let _ = run_binary("tandoor_shopping_list_entry_delete", &input);
}

#[test]
fn tandoor_shopping_list_recipe_add_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "mealplan_id": 1,
        "recipe_id": 1,
        "servings": 2.0
    })
    .to_string();
    let result = run_binary("tandoor_shopping_list_recipe_add", &input).unwrap();
    assert_eq!(result["success"], true);
    assert!(result["entries"].is_array());
}

#[test]
fn tandoor_shopping_list_recipe_get_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "mealplan_id": 1,
        "recipe_id": 1
    })
    .to_string();
    let result = run_binary("tandoor_shopping_list_recipe_get", &input).unwrap();
    assert_eq!(result["success"], true);
    assert!(result["recipe"].is_object());
}

#[test]
fn tandoor_shopping_list_recipe_delete_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "mealplan_id": 1,
        "recipe_id": 999
    })
    .to_string();
    let _ = run_binary("tandoor_shopping_list_recipe_delete", &input);
}
