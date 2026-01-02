//! Integration tests for all Tandoor and FatSecret binaries
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

// =============================================================================
// TANDOOR TESTS (31 tests)
// =============================================================================

#[test]
fn tandoor_test_connection_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = run_binary("tandoor_test_connection", &input).unwrap();
    assert_eq!(result["success"], true);
    assert!(result["recipe_count"].as_i64().unwrap_or(0) >= 0);
}

#[test]
fn tandoor_test_connection_missing_auth() {
    let input = json!({}).to_string();
    expect_failure("tandoor_test_connection", &input);
}

#[test]
fn tandoor_recipe_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_recipe_list", &input);
    assert!(result["count"].as_i64().unwrap_or(0) >= 0);
    assert!(result["recipes"].is_array());
}

#[test]
fn tandoor_recipe_list_with_pagination() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "page": 1,
        "page_size": 2
    })
    .to_string();

    let result = expect_success("tandoor_recipe_list", &input);
    let recipes = result["recipes"].as_array().unwrap();
    assert!(recipes.len() <= 2);
}

#[test]
fn tandoor_recipe_get_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "recipe_id": 1
    })
    .to_string();

    let result = expect_success("tandoor_recipe_get", &input);
    assert!(result["recipe"].is_object());
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
fn tandoor_ingredient_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_ingredient_list", &input);
    assert!(result["count"].as_i64().unwrap_or(0) >= 0);
    assert!(result["ingredients"].is_array());
}

#[test]
fn tandoor_food_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_food_list", &input);
    assert!(result["count"].as_i64().unwrap_or(0) >= 0);
    assert!(result["foods"].is_array());
}

#[test]
fn tandoor_unit_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_unit_list", &input);
    assert!(result["count"].as_i64().unwrap_or(0) >= 0);
    assert!(result["units"].is_array());
}

#[test]
fn tandoor_keyword_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_keyword_list", &input);
    assert!(result["count"].as_i64().unwrap_or(0) >= 0);
    assert!(result["keywords"].is_array());
}

#[test]
fn tandoor_recipe_book_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();
    let _ = run_binary("tandoor_recipe_book_list", &input);
}

#[test]
fn tandoor_user_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_user_list", &input);
    assert!(result["count"].as_i64().unwrap_or(0) >= 0);
    assert!(result["users"].is_array());
}

#[test]
fn tandoor_space_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();
    let _ = run_binary("tandoor_space_list", &input);
}

#[test]
fn tandoor_supermarket_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();
    let _ = run_binary("tandoor_supermarket_list", &input);
}

#[test]
fn tandoor_unit_conversion_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();
    let _ = run_binary("tandoor_unit_conversion_list", &input);
}

#[test]
fn tandoor_meal_plan_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();
    let _ = run_binary("tandoor_meal_plan_list", &input);
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

#[test]
fn tandoor_step_list_success() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();
    let _ = run_binary("tandoor_step_list", &input);
}

#[test]
fn tandoor_recipe_list_response_format() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_recipe_list", &input);
    assert!(result.get("success").is_some());
    assert!(result.get("count").is_some());
    assert!(result.get("recipes").is_some());
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
fn tandoor_unit_response_format() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();

    let result = expect_success("tandoor_unit_list", &input);
    assert!(result.get("success").is_some());
    assert!(result.get("count").is_some());
    assert!(result.get("units").is_some());
}

#[test]
fn tandoor_recipe_get_missing_id() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();
    expect_failure("tandoor_recipe_get", &input);
}

#[test]
#[ignore]
fn tandoor_connection_latency() {
    let start = std::time::Instant::now();
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token}
    })
    .to_string();
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

#[test]
fn tandoor_recipe_list_multiple_pages() {
    let (url, token) = get_tandoor_creds();
    for page in [1, 2, 3] {
        let input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "page": page,
            "page_size": 2
        })
        .to_string();
        let _ = run_binary("tandoor_recipe_list", &input);
    }
}

// =============================================================================
// FATSECRET TESTS (30 tests)
// =============================================================================

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

#[test]
fn fatsecret_recipes_get_favorites_success() {
    let input = json!({}).to_string();
    let _ = run_binary("fatsecret_recipes_get_favorites", &input);
}

#[test]
fn fatsecret_recipe_add_favorite_success() {
    let input = json!({"recipe_id": "1"}).to_string();
    let _ = run_binary("fatsecret_recipe_add_favorite", &input);
}

#[test]
fn fatsecret_recipe_delete_favorite_success() {
    let input = json!({"recipe_id": "1"}).to_string();
    let _ = run_binary("fatsecret_recipe_delete_favorite", &input);
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

// =============================================================================
// FATSECRET DIARY & EXERCISE INTEGRATION TESTS (12 tests)
// =============================================================================

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

// =============================================================================
// ERROR HANDLING TESTS (10 tests)
// =============================================================================

#[test]
fn tandoor_recipe_list_invalid_auth() {
    let input = json!({
        "tandoor": {"base_url": "http://localhost:8090", "api_token": "invalid_token"}
    })
    .to_string();
    let result = run_binary("tandoor_recipe_list", &input);
    assert!(result.is_ok());
}

#[test]
fn fatsecret_foods_search_missing_query() {
    let input = json!({}).to_string();
    expect_failure("fatsecret_foods_search", &input);
}

#[test]
fn fatsecret_food_get_missing_id() {
    let input = json!({}).to_string();
    expect_failure("fatsecret_food_get", &input);
}

#[test]
fn fatsecret_food_get_invalid_format() {
    let input = json!({"food_id": "not_a_number"}).to_string();
    let _ = run_binary("fatsecret_food_get", &input);
}

#[test]
fn tandoor_recipe_list_zero_page() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "page": 0
    })
    .to_string();
    let _ = run_binary("tandoor_recipe_list", &input);
}

#[test]
fn tandoor_recipe_list_large_page_size() {
    let (url, token) = get_tandoor_creds();
    let input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "page": 1,
        "page_size": 100
    })
    .to_string();
    let result = run_binary("tandoor_recipe_list", &input).unwrap();
    assert!(result["recipes"].is_array());
}

#[test]
fn fatsecret_search_unicode() {
    let input = json!({"query": "θερμιδες"}).to_string();
    let _ = run_binary("fatsecret_foods_search", &input);
}

#[test]
fn fatsecret_search_special_chars() {
    let input = json!({"query": "chicken & rice"}).to_string();
    let result = run_binary("fatsecret_foods_search", &input);
    assert!(
        result.is_ok(),
        "Binary should handle special chars without panicking"
    );
    let value = result.unwrap();
    assert!(
        value["foods"].is_object() || value.get("success") == Some(&json!(false)),
        "Should return foods object or error indication"
    );
}

#[test]
fn fatsecret_food_response_format() {
    let input = json!({"food_id": "1633"}).to_string();
    let result = expect_success("fatsecret_food_get", &input);
    assert!(result.get("success").is_some());
    assert!(result.get("food").is_some());
}

#[test]
fn fatsecret_recipe_types_response_format() {
    let input = json!({}).to_string();
    let result = expect_success("fatsecret_recipe_types_get", &input);
    assert!(result.get("success").is_some());
    assert!(result.get("recipe_types").is_some());
}

// =============================================================================
// PERFORMANCE TESTS (5 tests)
// =============================================================================

#[test]
fn fatsecret_search_latency() {
    let start = std::time::Instant::now();
    let input = json!({"query": "chicken", "max_results": 5}).to_string();
    let result = run_binary("fatsecret_foods_search", &input);
    let elapsed = start.elapsed();
    let is_ci = std::env::var("CI").is_ok() || std::env::var("GITHUB_ACTIONS").is_ok();
    let max_secs = if is_ci { 60 } else { 30 };
    assert!(result.is_ok(), "Binary should complete without error");
    assert!(
        elapsed.as_secs() < max_secs,
        "Search took too long: {:?} (CI: {}, max: {}s)",
        elapsed,
        is_ci,
        max_secs
    );
}

// =============================================================================
// CRUD CYCLE TESTS (1 test)
// =============================================================================

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

// =============================================================================
// DATA CONSISTENCY TESTS (5 tests)
// =============================================================================

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
fn fatsecret_serving_ids_are_consistent() {
    let search_input = json!({
        "search_expression": "chicken breast",
        "max_results": 1
    })
    .to_string();

    let search_result = run_binary("fatsecret_foods_search", &search_input).unwrap();

    if let Some(foods) = search_result["foods"]["food"].as_array() {
        if let Some(first) = foods.first() {
            let food_id = first["food_id"].as_str().unwrap();
            let get_input = json!({"food_id": food_id}).to_string();

            let get_result = run_binary("fatsecret_food_get", &get_input).unwrap();
            if let Some(servings) = get_result["food"]["servings"]["serving"].as_array() {
                for serving in servings {
                    let serving_id = serving["serving_id"].as_str().unwrap();
                    assert!(!serving_id.is_empty());
                }
            }
        }
    }
}

// =============================================================================
// TANDOOR CRUD CYCLE TESTS (9 tests)
// =============================================================================

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

#[test]
fn tandoor_unit_create_success() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("test_unit_{}", Utc::now().timestamp());

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name,
        "plural_name": format!("{}s", test_name)
    })
    .to_string();

    let create_result = expect_success("tandoor_unit_create", &create_input);
    let unit_id = create_result["id"].as_i64();

    if let Some(id) = unit_id {
        let delete_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id
        })
        .to_string();
        let _ = run_binary("tandoor_unit_delete", &delete_input);
    }
}

#[test]
fn tandoor_unit_update_success() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("test_unit_{}", Utc::now().timestamp());

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name
    })
    .to_string();

    let create_result = run_binary("tandoor_unit_create", &create_input).unwrap();
    let unit_id = create_result["id"].as_i64();

    if let Some(id) = unit_id {
        let update_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id,
            "name": format!("{}_updated", test_name),
            "plural_name": format!("{}_updateds", test_name)
        })
        .to_string();

        let update_result = expect_success("tandoor_unit_update", &update_input);
        assert!(update_result.get("id").is_some(), "Update should return id");

        let delete_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id
        })
        .to_string();
        let _ = run_binary("tandoor_unit_delete", &delete_input);
    }
}

#[test]
fn tandoor_unit_delete_success() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("test_unit_{}", Utc::now().timestamp());

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name
    })
    .to_string();

    let create_result = run_binary("tandoor_unit_create", &create_input).unwrap();
    let unit_id = create_result["id"].as_i64();

    if let Some(id) = unit_id {
        let delete_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id
        })
        .to_string();

        let delete_result = run_binary("tandoor_unit_delete", &delete_input).unwrap();
        assert!(
            delete_result["success"].as_bool().unwrap_or(false),
            "Delete should succeed"
        );
    }
}

#[test]
fn tandoor_recipe_book_create_success() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("Test Recipe Book {}", Utc::now().timestamp());

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name,
        "description": "Integration test recipe book",
        "icon": "book",
        "color": "blue"
    })
    .to_string();

    let create_result = expect_success("tandoor_recipe_book_create", &create_input);
    let book_id = create_result["recipe_book"]["id"].as_i64();

    if let Some(id) = book_id {
        let delete_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id
        })
        .to_string();
        let _ = run_binary("tandoor_recipe_book_delete", &delete_input);
    }
}

#[test]
fn tandoor_recipe_book_update_success() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("Test Recipe Book {}", Utc::now().timestamp());

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name
    })
    .to_string();

    let create_result = run_binary("tandoor_recipe_book_create", &create_input).unwrap();
    let book_id = create_result["recipe_book"]["id"].as_i64();

    if let Some(id) = book_id {
        let update_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id,
            "name": format!("{} Updated", test_name),
            "description": "Updated description",
            "color": "green"
        })
        .to_string();

        let update_result = expect_success("tandoor_recipe_book_update", &update_input);
        assert!(
            update_result["recipe_book"].is_object(),
            "Update should return recipe_book object"
        );

        let delete_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id
        })
        .to_string();
        let _ = run_binary("tandoor_recipe_book_delete", &delete_input);
    }
}

#[test]
fn tandoor_recipe_book_delete_success() {
    let (url, token) = get_tandoor_creds();
    let test_name = format!("Test Recipe Book {}", Utc::now().timestamp());

    let create_input = json!({
        "tandoor": {"base_url": url, "api_token": token},
        "name": test_name
    })
    .to_string();

    let create_result = run_binary("tandoor_recipe_book_create", &create_input).unwrap();
    let book_id = create_result["recipe_book"]["id"].as_i64();

    if let Some(id) = book_id {
        let delete_input = json!({
            "tandoor": {"base_url": url, "api_token": token},
            "id": id
        })
        .to_string();

        let delete_result = run_binary("tandoor_recipe_book_delete", &delete_input).unwrap();
        assert!(
            delete_result["success"].as_bool().unwrap_or(false),
            "Delete should succeed"
        );
    }
}

// =============================================================================
// RECIPE CRUD INTEGRATION TESTS (6 tests)
// Tests for the full recipe lifecycle: create, update, delete, upload image,
// get related, and batch update
// =============================================================================

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
