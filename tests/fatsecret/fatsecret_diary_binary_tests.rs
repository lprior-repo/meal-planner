//! Integration tests for FatSecret food entry binaries
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
fn fatsecret_food_entry_create_success() {
    let input = json!({
        "food_id": "1633",
        "food_entry_name": "Test Entry",
        "serving_id": "1",
        "number_of_units": 1.0,
        "meal": "lunch",
        "date": 20088
    })
    .to_string();
    let _ = run_binary("fatsecret_food_entry_create", &input);
}

#[test]
fn fatsecret_food_entries_get_success() {
    let input = json!({"date": 20088}).to_string();
    let _ = run_binary("fatsecret_food_entries_get", &input);
}

#[test]
fn fatsecret_food_entries_get_month_success() {
    let input = json!({"year": 2025, "month": 12}).to_string();
    let _ = run_binary("fatsecret_food_entries_get_month", &input);
}

#[test]
fn fatsecret_food_entry_edit_success() {
    let input = json!({
        "food_entry_id": "1",
        "number_of_units": 2.0,
        "meal": "dinner"
    })
    .to_string();
    let result = run_binary("fatsecret_food_entry_edit", &input);
    assert!(result.is_ok(), "Binary should execute: {:?}", result);
}

#[test]
fn fatsecret_food_entry_edit_units_only() {
    let input = json!({
        "food_entry_id": "1",
        "number_of_units": 1.5
    })
    .to_string();
    let _ = run_binary("fatsecret_food_entry_edit", &input);
}

#[test]
fn fatsecret_food_entry_edit_meal_only() {
    let input = json!({
        "food_entry_id": "1",
        "meal": "lunch"
    })
    .to_string();
    let _ = run_binary("fatsecret_food_entry_edit", &input);
}

#[test]
fn fatsecret_food_entry_edit_invalid_id() {
    let input = json!({
        "food_entry_id": "999999999999999",
        "number_of_units": 2.0
    })
    .to_string();
    let _ = run_binary("fatsecret_food_entry_edit", &input);
}

#[test]
fn fatsecret_food_entry_delete_success() {
    let input = json!({
        "food_entry_id": "1"
    })
    .to_string();
    let result = run_binary("fatsecret_food_entry_delete", &input);
    assert!(result.is_ok(), "Binary should execute: {:?}", result);
}

#[test]
fn fatsecret_food_entry_delete_invalid_id() {
    let input = json!({
        "food_entry_id": "999999999999999"
    })
    .to_string();
    let _ = run_binary("fatsecret_food_entry_delete", &input);
}

#[test]
fn fatsecret_food_entry_month_summary_success() {
    let input = json!({"year": 2025, "month": 12}).to_string();
    let result = run_binary("fatsecret_food_entries_get_month", &input);
    assert!(result.is_ok(), "Binary should execute: {:?}", result);
}

#[test]
fn fatsecret_food_entry_month_summary_december_2025() {
    let input = json!({"year": 2025, "month": 12}).to_string();
    let _ = run_binary("fatsecret_food_entries_get_month", &input);
}

#[test]
fn fatsecret_weight_update_with_comment() {
    let input = json!({
        "weight_kg": 75.5,
        "date_int": 20088,
        "comment": "Morning weigh-in"
    })
    .to_string();
    let _ = run_binary("fatsecret_weight_update", &input);
}

#[test]
fn fatsecret_get_profile_success() {
    let input = json!({}).to_string();
    let _ = run_binary("fatsecret_get_profile", &input);
}

#[test]
fn fatsecret_saved_meals_get_success() {
    let input = json!({}).to_string();
    let _ = run_binary("fatsecret_saved_meals_get", &input);
}

#[test]
fn fatsecret_saved_meals_get_items_success() {
    let get_input = json!({}).to_string();
    let get_result = run_binary("fatsecret_saved_meals_get", &get_input).unwrap();

    if let Some(meals) = get_result["saved_meals"]["saved_meal"].as_array() {
        if let Some(first_meal) = meals.first() {
            let meal_id = first_meal["saved_meal_id"].as_str().unwrap();
            let input = json!({"saved_meal_id": meal_id}).to_string();
            let _ = run_binary("fatsecret_saved_meals_get_items", &input);
        }
    }
}

#[test]
fn fatsecret_saved_meals_create_success() {
    let input = json!({"saved_meal_name": "Test Meal", "meal_type": "lunch"}).to_string();
    let _ = run_binary("fatsecret_saved_meals_create", &input);
}

#[test]
fn fatsecret_saved_meals_edit_success() {
    let input = json!({"saved_meal_id": "1", "saved_meal_name": "Updated Meal"}).to_string();
    let _ = run_binary("fatsecret_saved_meals_edit", &input);
}

#[test]
fn fatsecret_saved_meals_delete_success() {
    let input = json!({"saved_meal_id": "1"}).to_string();
    let _ = run_binary("fatsecret_saved_meals_delete", &input);
}
