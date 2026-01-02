//! Integration tests for Tandoor meal type binaries
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
fn tandoor_meal_type_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_meal_type_list", &input);
    assert!(result["count"].as_i64().unwrap_or(0) >= 0);
    assert!(result["meal_types"].is_array());
}

#[test]
fn tandoor_meal_type_response_format() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_meal_type_list", &input);
    assert!(result.get("success").is_some());
    assert!(result.get("count").is_some());
    assert!(result.get("meal_types").is_some());
}

#[test]
fn tandoor_meal_plan_crud_cycle() {
    let (url, token) = get_tandoor_creds();

    let list_input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();
    let list_result = run_binary("tandoor_meal_type_list", &list_input).unwrap();

    let meal_type_id = list_result["meal_types"]
        .as_array()
        .and_then(|arr| arr.first())
        .and_then(|mt| mt.get("id").and_then(|id| id.as_i64()))
        .unwrap_or(1);

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "meal_plan": {
            "title": "CRUD Cycle Test",
            "recipe": 1,
            "servings": 4.0,
            "from_date": "2025-01-02T00:00:00",
            "to_date": "2025-01-03T00:00:00",
            "meal_type": meal_type_id
        }
    })
    .to_string();

    let create_result = run_binary("tandoor_meal_plan_create", &create_input).unwrap();
    let meal_plan_id = create_result["meal_plan"]["id"].as_i64();

    if let Some(id) = meal_plan_id {
        let update_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id,
            "meal_plan": {"title": "Updated Meal Plan", "recipe": 1, "servings": 2.0}
        })
        .to_string();
        let _ = run_binary("tandoor_meal_plan_update", &update_input);

        let delete_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id
        })
        .to_string();
        let _ = run_binary("tandoor_meal_plan_delete", &delete_input);
    }
}

#[test]
fn tandoor_meal_type_create_success() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("Test Meal Type {}", Utc::now().timestamp());

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name,
        "order": 99,
        "time": "12:00",
        "color": "#FF5733",
        "default": false
    })
    .to_string();

    let create_result = expect_success("tandoor_meal_type_create", &create_input);
    let meal_type_id = create_result["meal_type"]["id"].as_i64();

    if let Some(id) = meal_type_id {
        let delete_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id
        })
        .to_string();
        let _ = run_binary("tandoor_meal_type_delete", &delete_input);
    }
}

#[test]
fn tandoor_meal_type_update_success() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("Test Meal Type {}", Utc::now().timestamp());

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name,
        "order": 50
    })
    .to_string();

    let create_result = run_binary("tandoor_meal_type_create", &create_input).unwrap();
    let meal_type_id = create_result["meal_type"]["id"].as_i64();

    if let Some(id) = meal_type_id {
        let update_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id,
            "name": format!("{} Updated", test_name),
            "order": 51,
            "color": "#33FF57"
        })
        .to_string();

        let update_result = expect_success("tandoor_meal_type_update", &update_input);
        assert!(
            update_result["meal_type"].is_object(),
            "Update should return meal_type object"
        );

        let delete_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id
        })
        .to_string();
        let _ = run_binary("tandoor_meal_type_delete", &delete_input);
    }
}

#[test]
fn tandoor_meal_type_delete_success() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("Test Meal Type {}", Utc::now().timestamp());

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name
    })
    .to_string();

    let create_result = run_binary("tandoor_meal_type_create", &create_input).unwrap();
    let meal_type_id = create_result["meal_type"]["id"].as_i64();

    if let Some(id) = meal_type_id {
        let delete_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id
        })
        .to_string();

        let delete_result = run_binary("tandoor_meal_type_delete", &delete_input).unwrap();
        assert!(
            delete_result["success"].as_bool().unwrap_or(false),
            "Delete should succeed"
        );
    }
}
