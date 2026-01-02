//! Integration tests for FatSecret Recipe binaries
//!
//! Tests: fatsecret_recipes_search, fatsecret_recipe_get, fatsecret_recipes_autocomplete

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

use serde_json::json;

use super::super::support::binary_runner::run_binary;
use crate::fatsecret::common::{expect_failure, get_fatsecret_credentials};

#[test]
fn test_fatsecret_recipes_search_missing_expression() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c.to_json(),
        None => return,
    };

    let input = json!({
        "fatsecret": creds
    });

    expect_failure("fatsecret_recipes_search", &input);
}

#[test]
fn test_fatsecret_recipes_search_with_expression() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c.to_json(),
        None => return,
    };

    let input = json!({
        "fatsecret": creds,
        "search_expression": "pasta",
        "page_number": 1
    });

    let result = run_binary("fatsecret_recipes_search", &input);
    assert!(result.is_ok(), "Binary should execute");
}

#[test]
fn test_fatsecret_recipes_search_response_format() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c.to_json(),
        None => return,
    };

    let input = json!({
        "fatsecret": creds,
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
        Some(c) => c.to_json(),
        None => return,
    };

    let input = json!({
        "fatsecret": creds,
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
        Some(c) => c.to_json(),
        None => return,
    };

    let input = json!({
        "fatsecret": creds,
        "search_expression": "xyz123nonexistentrecipe456",
        "page_number": 1
    });

    let result = run_binary("fatsecret_recipes_search", &input);
    assert!(result.is_ok(), "Binary should execute without panicking");
}

#[test]
fn test_fatsecret_recipe_get_missing_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c.to_json(),
        None => return,
    };

    let input = json!({
        "fatsecret": creds
    });

    expect_failure("fatsecret_recipe_get", &input);
}

#[test]
fn test_fatsecret_recipe_get_with_id() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c.to_json(),
        None => return,
    };

    let input = json!({
        "fatsecret": creds,
        "recipe_id": "1"
    });

    let result = run_binary("fatsecret_recipe_get", &input);
    assert!(result.is_ok(), "Binary should execute");
}

#[test]
fn test_fatsecret_recipe_get_response_format() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c.to_json(),
        None => return,
    };

    let input = json!({
        "fatsecret": creds,
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
        Some(c) => c.to_json(),
        None => return,
    };

    let input = json!({
        "fatsecret": creds,
        "recipe_id": "999999999999"
    });

    let result = run_binary("fatsecret_recipe_get", &input);
    assert!(result.is_ok(), "Binary should execute");
}

#[test]
fn test_fatsecret_recipes_autocomplete_missing_expression() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c.to_json(),
        None => return,
    };

    let input = json!({
        "fatsecret": creds
    });

    expect_failure("fatsecret_recipes_autocomplete", &input);
}

#[test]
fn test_fatsecret_recipes_autocomplete_with_expression() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c.to_json(),
        None => return,
    };

    let input = json!({
        "fatsecret": creds,
        "expression": "chick"
    });

    let result = run_binary("fatsecret_recipes_autocomplete", &input);
    assert!(result.is_ok(), "Binary should execute");
}

#[test]
fn test_fatsecret_recipes_autocomplete_response_format() {
    let creds = match get_fatsecret_credentials() {
        Some(c) => c.to_json(),
        None => return,
    };

    let input = json!({
        "fatsecret": creds,
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
        Some(c) => c.to_json(),
        None => return,
    };

    let input = json!({
        "fatsecret": creds,
        "expression": "a"
    });

    let result = run_binary("fatsecret_recipes_autocomplete", &input);
    assert!(result.is_ok(), "Binary should handle short expression");
}
