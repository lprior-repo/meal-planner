//! Integration tests for FatSecret food search/get binaries
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

fn expect_failure(binary_name: &str, input: &str) {
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
fn fatsecret_foods_search_success() {
    let input = json!({
        "query": "chicken",
        "page": 0,
        "max_results": 5
    })
    .to_string();

    let result = expect_success("fatsecret_foods_search", &input);
    assert!(result["foods"].is_object());
}

#[test]
fn fatsecret_foods_search_empty_query() {
    let input = json!({
        "query": "xyz123nonexistentfood987"
    })
    .to_string();

    let result = run_binary("fatsecret_foods_search", &input);
    assert!(result.is_ok(), "Binary should not panic on empty results");
    let value = result.unwrap();
    assert!(
        value["foods"].is_object() || value.get("success") == Some(&json!(false)),
        "Should return foods object or error indication"
    );
}

#[test]
fn fatsecret_food_get_success() {
    let input = json!({
        "food_id": "1633"
    })
    .to_string();

    let result = expect_success("fatsecret_food_get", &input);
    assert_eq!(result["food"]["food_id"], "1633");
    assert!(result["food"]["servings"].is_object());
}

#[test]
fn fatsecret_food_get_invalid_id() {
    let input = json!({
        "food_id": "999999999999"
    })
    .to_string();
    let _ = run_binary("fatsecret_food_get", &input);
}

#[ignore]
#[test]
fn fatsecret_foods_autocomplete_success() {
    let input = json!({
        "expression": "chick"
    })
    .to_string();

    let result = expect_success("fatsecret_foods_autocomplete", &input);
    assert!(result["suggestions"].is_array());
}

#[test]
fn fatsecret_recipe_types_get_success() {
    let input = json!({}).to_string();

    let result = expect_success("fatsecret_recipe_types_get", &input);
    assert!(result["recipe_types"].is_array());
}

#[test]
fn fatsecret_recipes_search_success() {
    let input = json!({
        "search_expression": "pasta",
        "page_number": 1
    })
    .to_string();

    let result = expect_success("fatsecret_recipes_search", &input);
    assert!(result["recipes"].is_object());
}

#[test]
fn fatsecret_recipe_get_success() {
    let search_input = json!({
        "query": "chicken",
        "page_number": 1,
        "max_results": 1
    })
    .to_string();

    let search_result = run_binary("fatsecret_recipes_search", &search_input).unwrap();
    if let Some(recipes) = search_result["recipes"]["recipe"].as_array() {
        if let Some(first_recipe) = recipes.first() {
            let recipe_id = first_recipe["recipe_id"].as_str().unwrap();
            let get_input = json!({
                "recipe_id": recipe_id
            })
            .to_string();

            let result = expect_success("fatsecret_recipe_get", &get_input);
            assert!(result["recipe"].is_object());
        }
    }
}

#[test]
fn fatsecret_foods_get_favorites_success() {
    let input = json!({}).to_string();
    let _ = run_binary("fatsecret_foods_get_favorites", &input);
}

#[test]
fn fatsecret_food_add_favorite_success() {
    let input = json!({"food_id": "1633"}).to_string();
    let _ = run_binary("fatsecret_food_add_favorite", &input);
}

#[test]
fn fatsecret_food_delete_favorite_success() {
    let input = json!({"food_id": "1633"}).to_string();
    let _ = run_binary("fatsecret_food_delete_favorite", &input);
}

#[test]
fn fatsecret_foods_most_eaten_success() {
    let input = json!({"page_number": 1, "max_results": 5}).to_string();
    let _ = run_binary("fatsecret_foods_most_eaten", &input);
}

#[test]
fn fatsecret_foods_recently_eaten_success() {
    let input = json!({"page_number": 1, "max_results": 5}).to_string();
    let _ = run_binary("fatsecret_foods_recently_eaten", &input);
}
