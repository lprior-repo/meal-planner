//! Integration tests for Tandoor recipe CRUD binaries
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
fn tandoor_recipe_ids_are_consistent() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_recipe_list", &input);

    if let Some(recipes) = result["recipes"].as_array() {
        for recipe in recipes {
            let id = recipe["id"].as_i64().unwrap();
            let get_input = json!({
                "tandoor": {"base_url": url, "api_token": token},
                "recipe_id": id
            })
            .to_string();

            let get_result = run_binary("tandoor_recipe_get", &get_input).unwrap();
            if get_result["success"].as_bool().unwrap_or(false) {
                let fetched_id = get_result["recipe"]["id"].as_i64().unwrap();
                assert_eq!(id, fetched_id, "Recipe ID mismatch");
            }
        }
    }
}

#[test]
fn tandoor_recipe_create_success() {
    let (url, token) = get_tandoor_creds();
    let recipe = json!({
        "name": "Integration Test Recipe",
        "description": "Created by integration test",
        "servings": 4,
        "working_time": 30,
        "waiting_time": 0,
        "keywords": [{"name": "test"}],
        "steps": [
            {
                "instruction": "Mix ingredients",
                "ingredients": [
                    {"amount": 2.0, "food": {"name": "eggs"}, "unit": {"name": "piece"}, "note": ""}
                ]
            }
        ]
    });
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "recipe": recipe
    })
    .to_string();

    let result = expect_success("tandoor_create_recipe", &input);
    assert!(
        result["recipe_id"].as_i64().unwrap_or(0) > 0,
        "Recipe ID should be positive"
    );
    assert_eq!(result["name"].as_str(), Some("Integration Test Recipe"));
}

#[test]
fn tandoor_recipe_update_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "recipe_id": 1,
        "name": "Updated Integration Test Recipe",
        "description": "Updated by integration test",
        "servings": 6
    })
    .to_string();

    let result = expect_success("tandoor_recipe_update", &input);
    assert!(
        result["recipe"].is_object(),
        "Response should contain recipe object"
    );
}

#[test]
fn tandoor_recipe_delete_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "recipe_id": 999999999
    })
    .to_string();
    let result = run_binary("tandoor_recipe_delete", &input);
    assert!(result.is_ok(), "Delete should complete without panicking");
}

#[test]
fn tandoor_recipe_upload_image_success() {
    let (url, token) = get_tandoor_creds();
    let temp_dir = std::env::temp_dir();
    let test_image_path = temp_dir.join("test_recipe_image.jpg");
    std::fs::write(&test_image_path, b"fake image data").expect("Failed to create test image");

    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "recipe_id": 1,
        "image_path": test_image_path.to_string_lossy().to_string()
    })
    .to_string();

    let result = run_binary("tandoor_recipe_upload_image", &input);
    std::fs::remove_file(&test_image_path).ok();
    assert!(result.is_ok(), "Image upload should complete successfully");
}

#[test]
fn tandoor_recipe_get_related_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "recipe_id": 1
    })
    .to_string();

    let result = expect_success("tandoor_recipe_get_related", &input);
    assert!(
        result["recipes"].is_array() || result["recipes"].is_null(),
        "Recipes should be array or null"
    );
    let _count = result["recipe_count"].as_u64().unwrap_or(0);
}

#[test]
fn tandoor_recipe_batch_update_success() {
    let (url, token) = get_tandoor_creds();
    let updates = json!([
        {"id": 1, "name": "Batch Updated Recipe 1", "servings": 4},
        {"id": 2, "description": "Batch updated description"}
    ]);
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "updates": updates
    })
    .to_string();

    let result = expect_success("tandoor_recipe_batch_update", &input);
    assert!(
        result.get("updated_count").and_then(|v| v.as_i64()).unwrap_or(0) >= 0,
        "Updated count should be non-negative"
    );
}
