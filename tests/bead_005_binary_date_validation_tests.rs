//! BEAD-005: Binary Date Validation Integration Tests
//!
//! Tests that the three binaries (sync_meal_plan, analyze_nutrition,
//! track_exercise_balance) properly validate date formats and reject
//! invalid dates with clear error messages.

use serde_json::json;
use std::process::Command;

fn run_binary(binary_name: &str, input: &str) -> (String, String, i32) {
    let output = Command::new(format!("target/debug/{}", binary_name))
        .arg(input)
        .output()
        .expect("Failed to execute binary");

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).to_string();
    let exit_code = output.status.code().unwrap_or(-1);

    (stdout, stderr, exit_code)
}

// ============================================================================
// sync_meal_plan Tests
// ============================================================================

#[test]
#[ignore = "requires OAuth credentials"]
fn test_sync_meal_plan_valid_date() {
    let input = json!({
        "access_token": "dummy_token",
        "access_secret": "dummy_secret",
        "entries": [{
            "date": "2025-01-15",
            "meal_type": "breakfast",
            "recipe_name": "Oatmeal",
            "servings": 1.0,
            "calories": 300.0,
            "protein": 10.0,
            "carbohydrate": 50.0,
            "fat": 5.0
        }]
    });

    let (stdout, _stderr, _exit_code) = run_binary("sync_meal_plan", &input.to_string());

    // Should not contain date format error (may fail on auth, which is OK)
    assert!(!stdout.contains("must be exactly YYYY-MM-DD format"));
}

#[test]
fn test_sync_meal_plan_invalid_date_no_zero_padding() {
    let input = json!({
        "access_token": "dummy_token",
        "access_secret": "dummy_secret",
        "entries": [{
            "date": "2025-1-9",  // Invalid: no zero padding
            "meal_type": "breakfast",
            "recipe_name": "Oatmeal",
            "servings": 1.0,
            "calories": 300.0,
            "protein": 10.0,
            "carbohydrate": 50.0,
            "fat": 5.0
        }]
    });

    let (stdout, _stderr, _exit_code) = run_binary("sync_meal_plan", &input.to_string());

    // Parse JSON response
    let response: serde_json::Value = serde_json::from_str(&stdout)
        .expect("Should return valid JSON");

    // sync_meal_plan uses success:false for batch errors (doesn't exit non-zero)
    assert_eq!(
        response["success"].as_bool(),
        Some(false),
        "Should have success:false"
    );

    // Check that error mentions YYYY-MM-DD format
    let error_text = if let Some(errors_array) = response["errors"].as_array() {
        errors_array.iter()
            .map(|e| e.as_str().unwrap_or(""))
            .collect::<Vec<_>>()
            .join(" ")
    } else if let Some(error_str) = response["error"].as_str() {
        error_str.to_string()
    } else {
        String::new()
    };

    assert!(
        error_text.contains("YYYY-MM-DD") || error_text.contains("Invalid date"),
        "Error should mention date format issue. Got: {}",
        error_text
    );
}

#[test]
fn test_sync_meal_plan_invalid_date_slash_separators() {
    let input = json!({
        "access_token": "dummy_token",
        "access_secret": "dummy_secret",
        "entries": [{
            "date": "2025/01/09",  // Invalid: slash separators
            "meal_type": "breakfast",
            "recipe_name": "Oatmeal",
            "servings": 1.0,
            "calories": 300.0,
            "protein": 10.0,
            "carbohydrate": 50.0,
            "fat": 5.0
        }]
    });

    let (stdout, _stderr, _exit_code) = run_binary("sync_meal_plan", &input.to_string());

    // Should contain error about date format
    let response: serde_json::Value = serde_json::from_str(&stdout).unwrap_or(json!({}));
    let error_str = format!("{}", response);
    assert!(error_str.contains("YYYY-MM-DD") || error_str.contains("Invalid date"));
}

#[test]
fn test_sync_meal_plan_invalid_month() {
    let input = json!({
        "access_token": "dummy_token",
        "access_secret": "dummy_secret",
        "entries": [{
            "date": "2025-13-01",  // Invalid: month 13
            "meal_type": "breakfast",
            "recipe_name": "Oatmeal",
            "servings": 1.0,
            "calories": 300.0,
            "protein": 10.0,
            "carbohydrate": 50.0,
            "fat": 5.0
        }]
    });

    let (stdout, _stderr, _exit_code) = run_binary("sync_meal_plan", &input.to_string());

    let response: serde_json::Value = serde_json::from_str(&stdout).unwrap_or(json!({}));
    let error_str = format!("{}", response);
    assert!(error_str.contains("01-12") || error_str.contains("month"));
}

#[test]
fn test_sync_meal_plan_invalid_day_for_month() {
    let input = json!({
        "access_token": "dummy_token",
        "access_secret": "dummy_secret",
        "entries": [{
            "date": "2025-04-31",  // Invalid: April has 30 days
            "meal_type": "breakfast",
            "recipe_name": "Oatmeal",
            "servings": 1.0,
            "calories": 300.0,
            "protein": 10.0,
            "carbohydrate": 50.0,
            "fat": 5.0
        }]
    });

    let (stdout, _stderr, _exit_code) = run_binary("sync_meal_plan", &input.to_string());

    let response: serde_json::Value = serde_json::from_str(&stdout).unwrap_or(json!({}));
    let error_str = format!("{}", response);
    assert!(error_str.contains("April") || error_str.contains("30 days") || error_str.contains("Invalid date"));
}

#[test]
fn test_sync_meal_plan_invalid_leap_year() {
    let input = json!({
        "access_token": "dummy_token",
        "access_secret": "dummy_secret",
        "entries": [{
            "date": "2025-02-29",  // Invalid: 2025 is not a leap year
            "meal_type": "breakfast",
            "recipe_name": "Oatmeal",
            "servings": 1.0,
            "calories": 300.0,
            "protein": 10.0,
            "carbohydrate": 50.0,
            "fat": 5.0
        }]
    });

    let (stdout, _stderr, _exit_code) = run_binary("sync_meal_plan", &input.to_string());

    let response: serde_json::Value = serde_json::from_str(&stdout).unwrap_or(json!({}));
    let error_str = format!("{}", response);
    assert!(error_str.contains("February") || error_str.contains("28 days") || error_str.contains("non-leap"));
}

// ============================================================================
// analyze_nutrition Tests
// ============================================================================

#[test]
fn test_analyze_nutrition_invalid_start_date() {
    let input = json!({
        "access_token": "dummy_token",
        "access_secret": "dummy_secret",
        "date_range": {
            "start": "2025-1-1",  // Invalid: no zero padding
            "end": "2025-01-31"
        }
    });

    let (stdout, _stderr, exit_code) = run_binary("analyze_nutrition", &input.to_string());

    assert_ne!(exit_code, 0);

    let response: serde_json::Value = serde_json::from_str(&stdout).unwrap_or(json!({}));
    let error_str = response["error"].as_str().unwrap_or("");
    assert!(
        error_str.contains("Invalid start date") || error_str.contains("YYYY-MM-DD"),
        "Error should mention invalid start date. Got: {}",
        error_str
    );
}

#[test]
fn test_analyze_nutrition_invalid_end_date() {
    let input = json!({
        "access_token": "dummy_token",
        "access_secret": "dummy_secret",
        "date_range": {
            "start": "2025-01-01",
            "end": "2025/01/31"  // Invalid: slash separators
        }
    });

    let (stdout, _stderr, exit_code) = run_binary("analyze_nutrition", &input.to_string());

    assert_ne!(exit_code, 0);

    let response: serde_json::Value = serde_json::from_str(&stdout).unwrap_or(json!({}));
    let error_str = response["error"].as_str().unwrap_or("");
    assert!(
        error_str.contains("Invalid end date") || error_str.contains("YYYY-MM-DD"),
        "Error should mention invalid end date. Got: {}",
        error_str
    );
}

// ============================================================================
// track_exercise_balance Tests
// ============================================================================

#[test]
fn test_track_exercise_balance_invalid_date() {
    let input = json!({
        "access_token": "dummy_token",
        "access_secret": "dummy_secret",
        "date": "2025-1-15",  // Invalid: no zero padding
        "bmr": 1800.0
    });

    let (stdout, _stderr, exit_code) = run_binary("track_exercise_balance", &input.to_string());

    assert_ne!(exit_code, 0);

    let response: serde_json::Value = serde_json::from_str(&stdout).unwrap_or(json!({}));
    let error_str = response["error"].as_str().unwrap_or("");
    assert!(
        error_str.contains("Invalid date") || error_str.contains("YYYY-MM-DD"),
        "Error should mention invalid date. Got: {}",
        error_str
    );
}

#[test]
fn test_track_exercise_balance_year_out_of_range() {
    let input = json!({
        "access_token": "dummy_token",
        "access_secret": "dummy_secret",
        "date": "2100-01-15",  // Invalid: year > 2099
        "bmr": 1800.0
    });

    let (stdout, _stderr, exit_code) = run_binary("track_exercise_balance", &input.to_string());

    assert_ne!(exit_code, 0);

    let response: serde_json::Value = serde_json::from_str(&stdout).unwrap_or(json!({}));
    let error_str = response["error"].as_str().unwrap_or("");
    assert!(
        error_str.contains("1900") && error_str.contains("2099"),
        "Error should mention year range. Got: {}",
        error_str
    );
}
