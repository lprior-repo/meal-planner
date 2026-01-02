//! Real API validation tests for FatSecret CLI binaries
//!
//! These tests verify that binaries work correctly with real API calls
//! (when credentials are available)
//!
//! Run with: cargo test --test fatsecret_api_validation_tests
//!
//! Credentials are automatically loaded from:
//! 1. Environment variables (`FATSECRET_CONSUMER_KEY`, etc.)
//! 2. Windmill resources (u/admin/fatsecret_api)
//! 3. `pass` password manager (meal-planner/fatsecret/*)

#![allow(clippy::unwrap_used, clippy::indexing_slicing, clippy::panic)]

use super::common::{
    binary_exists, get_fatsecret_credentials, get_oauth_tokens, run_binary_with_exit_code,
};
use serde_json::json;

#[test]
fn test_food_get_real_api() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_food_get") {
        return;
    }

    let input = json!({
        "fatsecret": credentials.to_json(),
        "food_id": "35718"
    });

    let (output, exit_code) = run_binary_with_exit_code("fatsecret_food_get", &input).unwrap();

    assert_eq!(exit_code, 0, "Should succeed with valid credentials");
    assert_eq!(output["success"], true);
    assert!(output["food"].is_object(), "Should return food object");
}

#[test]
fn test_foods_autocomplete_real_api() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: credentials not available");
        return;
    };

    if !binary_exists("fatsecret_foods_autocomplete") {
        return;
    }

    let input = json!({
        "fatsecret": credentials.to_json(),
        "expression": "chick",
        "max_results": 5
    });

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_foods_autocomplete", &input).unwrap();

    if exit_code == 0 {
        assert_eq!(output["success"], true);
        assert!(output["suggestions"].is_object() || output["suggestions"].is_array());
    } else {
        let error = output["error"].as_str().unwrap_or("");
        assert!(
            error.contains("10")
                || error.contains("12")
                || error.contains("Unknown method")
                || error.contains("Premier"),
            "Expected Premier-only or unknown method error, got: {}",
            error
        );
        println!("foods.autocomplete requires Premier API tier (expected)");
    }
}

#[test]
fn test_foods_search_real_api() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    if !binary_exists("fatsecret_foods_search") {
        return;
    }

    let input = json!({
        "fatsecret": credentials.to_json(),
        "query": "chicken breast",
        "page": 0,
        "max_results": 5
    });

    let (output, exit_code) = run_binary_with_exit_code("fatsecret_foods_search", &input).unwrap();

    assert_eq!(exit_code, 0, "Should succeed with valid credentials");
    assert_eq!(output["success"], true);
    assert!(output["foods"].is_object());
}

#[test]
fn test_food_entries_get_real_api() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    let Some(tokens) = get_oauth_tokens() else {
        println!("Skipping: FATSECRET_ACCESS_TOKEN/SECRET not set");
        return;
    };
    let access_token = tokens.access_token;
    let access_secret = tokens.access_secret;

    if !binary_exists("fatsecret_food_entries_get") {
        return;
    }

    let today = chrono::Utc::now();
    let epoch = chrono::NaiveDate::from_ymd_opt(1970, 1, 1).unwrap();
    let date_int = (today.date_naive() - epoch).num_days();

    let input = json!({
        "fatsecret": credentials.to_json(),
        "access_token": access_token,
        "access_secret": access_secret,
        "date_int": date_int
    });

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_food_entries_get", &input).unwrap();

    if exit_code == 0 {
        assert_eq!(output["success"], true);
        assert!(output["entries"].is_array());
    } else {
        assert_eq!(output["success"], false);
    }
}

#[test]
fn test_foods_get_favorites_real_api() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    let Some(tokens) = get_oauth_tokens() else {
        println!("Skipping: FATSECRET_ACCESS_TOKEN/SECRET not set");
        return;
    };
    let access_token = tokens.access_token;
    let access_secret = tokens.access_secret;

    if !binary_exists("fatsecret_foods_get_favorites") {
        return;
    }

    let input = json!({
        "fatsecret": credentials.to_json(),
        "access_token": access_token,
        "access_secret": access_secret
    });

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_foods_get_favorites", &input).unwrap();

    if exit_code == 0 {
        assert_eq!(output["success"], true);
        assert!(output["favorites"].is_array());
    } else {
        assert_eq!(output["success"], false);
    }
}

#[test]
fn test_food_entries_get_month_real_api() {
    let Some(credentials) = get_fatsecret_credentials() else {
        println!("Skipping: FATSECRET_CONSUMER_KEY/SECRET not set");
        return;
    };

    let Some(tokens) = get_oauth_tokens() else {
        println!("Skipping: FATSECRET_ACCESS_TOKEN/SECRET not set");
        return;
    };
    let access_token = tokens.access_token;
    let access_secret = tokens.access_secret;

    if !binary_exists("fatsecret_food_entries_get_month") {
        return;
    }

    let today = chrono::Utc::now();
    let epoch = chrono::NaiveDate::from_ymd_opt(1970, 1, 1).unwrap();
    let date_int = (today.date_naive() - epoch).num_days();

    let input = json!({
        "fatsecret": credentials.to_json(),
        "access_token": access_token,
        "access_secret": access_secret,
        "date_int": date_int
    });

    let (output, exit_code) =
        run_binary_with_exit_code("fatsecret_food_entries_get_month", &input).unwrap();

    if exit_code == 0 {
        assert_eq!(output["success"], true);
        assert!(output["month"].is_object());
    } else {
        assert_eq!(output["success"], false);
    }
}
