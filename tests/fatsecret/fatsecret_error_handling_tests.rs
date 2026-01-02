//! Error handling tests for FatSecret CLI binaries

#![allow(clippy::unwrap_used, clippy::indexing_slicing, clippy::panic)]

use super::common::{binary_exists, run_binary_with_exit_code};
use serde_json::json;

#[test]
fn test_food_get_empty_input() {
    if !binary_exists("fatsecret_food_get") {
        return;
    }

    let (output, exit_code) = run_binary_with_exit_code("fatsecret_food_get", &json!({})).unwrap();

    assert_eq!(exit_code, 1, "Should exit with code 1 on error");
    assert_eq!(output["success"], false, "Should return success: false");
    assert!(output["error"].is_string(), "Should have error message");
}

#[test]
fn test_food_get_missing_food_id() {
    if !binary_exists("fatsecret_food_get") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"}
    });

    let (output, exit_code) = run_binary_with_exit_code("fatsecret_food_get", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("food_id"));
}

#[test]
fn test_foods_autocomplete_empty_input() {
    if !binary_exists("fatsecret_foods_autocomplete") {
        return;
    }

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_foods_autocomplete", &json!({})).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
}

#[test]
fn test_foods_autocomplete_missing_expression() {
    if !binary_exists("fatsecret_foods_autocomplete") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"}
    });

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_foods_autocomplete", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("expression"));
}

#[test]
fn test_food_add_favorite_missing_tokens() {
    if !binary_exists("fatsecret_food_add_favorite") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "food_id": "12345"
    });

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_food_add_favorite", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("access_token"));
}

#[test]
fn test_food_delete_favorite_missing_food_id() {
    if !binary_exists("fatsecret_food_delete_favorite") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "access_token": "test",
        "access_secret": "test"
    });

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_food_delete_favorite", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("food_id"));
}

#[test]
fn test_foods_get_favorites_missing_tokens() {
    if !binary_exists("fatsecret_foods_get_favorites") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"}
    });

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_foods_get_favorites", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("access_token"));
}

#[test]
fn test_food_entries_get_missing_date() {
    if !binary_exists("fatsecret_food_entries_get") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "access_token": "test",
        "access_secret": "test"
    });

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_food_entries_get", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("date_int"));
}

#[test]
fn test_recipes_autocomplete_missing_expression() {
    if !binary_exists("fatsecret_recipes_autocomplete") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"}
    });

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_recipes_autocomplete", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("expression"));
}

#[test]
fn test_food_entries_get_month_missing_date() {
    if !binary_exists("fatsecret_food_entries_get_month") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "access_token": "test",
        "access_secret": "test"
    });

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_food_entries_get_month", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("date_int"));
}

#[test]
fn test_food_entry_create_missing_fields() {
    if !binary_exists("fatsecret_food_entry_create") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "access_token": "test",
        "access_secret": "test"
    });

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_food_entry_create", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
}

#[test]
fn test_food_entry_create_invalid_meal_type() {
    if !binary_exists("fatsecret_food_entry_create") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "access_token": "test",
        "access_secret": "test",
        "food_id": "12345",
        "food_entry_name": "Test Food",
        "serving_id": "54321",
        "number_of_units": 1.0,
        "meal": "invalid_meal_type",
        "date_int": 20088
    });

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_food_entry_create", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    let error = output["error"].as_str().unwrap();
    assert!(
        error.contains("Invalid") || error.contains("credential"),
        "Error should indicate invalid input"
    );
}

#[test]
fn test_food_entry_edit_missing_entry_id() {
    if !binary_exists("fatsecret_food_entry_edit") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "access_token": "test",
        "access_secret": "test"
    });

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_food_entry_edit", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("food_entry_id"));
}

#[test]
fn test_food_entry_delete_missing_entry_id() {
    if !binary_exists("fatsecret_food_entry_delete") {
        return;
    }

    let input = json!({
        "fatsecret": {"consumer_key": "test", "consumer_secret": "test"},
        "access_token": "test",
        "access_secret": "test"
    });

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_food_entry_delete", &input).unwrap();

    assert_eq!(exit_code, 1);
    assert_eq!(output["success"], false);
    assert!(output["error"].as_str().unwrap().contains("food_entry_id"));
}

#[test]
fn test_invalid_json_handling() {
    use serde_json::Value;
    use std::io::Write;
    use std::process::{Command, Stdio};

    let binaries = ["fatsecret_food_get", "fatsecret_foods_autocomplete"];

    for binary in binaries {
        if !binary_exists(binary) {
            continue;
        }

        let binary_path = format!("./bin/{}", binary);
        let mut child = Command::new(&binary_path)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .unwrap();

        if let Some(ref mut stdin) = child.stdin {
            stdin.write_all(b"not valid json").unwrap();
        }

        let output = child.wait_with_output().unwrap();
        let exit_code = output.status.code().unwrap_or(-1);
        let stdout = String::from_utf8_lossy(&output.stdout);

        assert_eq!(exit_code, 1, "{} should exit with code 1", binary);
        let parse_result: Result<Value, _> = serde_json::from_str(&stdout);
        assert!(
            parse_result.is_ok(),
            "{binary} should return valid JSON error, got: {stdout}"
        );
        let json_output = parse_result.unwrap();
        assert_eq!(json_output["success"], false);
    }
}
