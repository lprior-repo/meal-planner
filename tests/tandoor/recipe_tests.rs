//! Integration tests for Tandoor Recipe binaries
//!
//! Tests: tandoor_recipe_list, tandoor_recipe_get, tandoor_recipe_update,
//!        tandoor_recipe_delete, tandoor_create_recipe, tandoor_recipe_get_related,
//!        tandoor_recipe_list_flat, tandoor_recipe_random_select, tandoor_recipe_batch_update,
//!        tandoor_recipe_upload_image, tandoor_scrape_recipe

#![allow(clippy::unwrap_used, clippy::indexing_slicing)]

mod common;
use common::{get_tandoor_credentials, run_binary, expect_failure};
use serde_json::json;

// =============================================================================
// tandoor_recipe_list Tests
// =============================================================================

#[test]
fn test_tandoor_recipe_list_no_auth() {
    let input = json!({
        "tandoor": {"base_url": "http://localhost:8090", "api_token": "invalid"}
    });
    let _ = run_binary("tandoor_recipe_list", &input);
}

#[test]
fn test_tandoor_recipe_list_with_pagination() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "page": 1,
        "page_size": 5
    });

    let result = run_binary("tandoor_recipe_list", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_recipe_get Tests
// =============================================================================

#[test]
fn test_tandoor_recipe_get_missing_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    expect_failure("tandoor_recipe_get", &input);
}

#[test]
fn test_tandoor_recipe_get_with_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "recipe_id": 1
    });

    let result = run_binary("tandoor_recipe_get", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_recipe_list_flat Tests
// =============================================================================

#[test]
fn test_tandoor_recipe_list_flat_no_auth() {
    let input = json!({
        "tandoor": {"base_url": "http://localhost:8090", "api_token": "invalid"}
    });
    let _ = run_binary("tandoor_recipe_list_flat", &input);
}

#[test]
fn test_tandoor_recipe_list_flat_with_params() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "page": 1
    });

    let result = run_binary("tandoor_recipe_list_flat", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_recipe_get_related Tests
// =============================================================================

#[test]
fn test_tandoor_recipe_get_related_missing_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    expect_failure("tandoor_recipe_get_related", &input);
}

#[test]
fn test_tandoor_recipe_get_related_with_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "recipe_id": 1
    });

    let result = run_binary("tandoor_recipe_get_related", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_recipe_random_select Tests
// =============================================================================

#[test]
fn test_tandoor_recipe_random_select_no_auth() {
    let input = json!({
        "tandoor": {"base_url": "http://localhost:8090", "api_token": "invalid"}
    });
    let _ = run_binary("tandoor_recipe_random_select", &input);
}

#[test]
fn test_tandoor_recipe_random_select_with_auth() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    let result = run_binary("tandoor_recipe_random_select", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_recipe_update Tests
// =============================================================================

#[test]
fn test_tandoor_recipe_update_missing_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    expect_failure("tandoor_recipe_update", &input);
}

#[test]
fn test_tandoor_recipe_update_with_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "recipe_id": 1,
        "name": "Updated Recipe"
    });

    let result = run_binary("tandoor_recipe_update", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_recipe_delete Tests
// =============================================================================

#[test]
fn test_tandoor_recipe_delete_missing_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    expect_failure("tandoor_recipe_delete", &input);
}

#[test]
fn test_tandoor_recipe_delete_with_id() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "recipe_id": 999999999
    });

    let result = run_binary("tandoor_recipe_delete", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_create_recipe Tests
// =============================================================================

#[test]
fn test_tandoor_create_recipe_missing_recipe() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    expect_failure("tandoor_create_recipe", &input);
}

#[test]
fn test_tandoor_create_recipe_with_data() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "recipe": {
            "name": "Test Recipe",
            "description": "Created by integration test"
        }
    });

    let result = run_binary("tandoor_create_recipe", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_recipe_batch_update Tests
// =============================================================================

#[test]
fn test_tandoor_recipe_batch_update_missing_updates() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    expect_failure("tandoor_recipe_batch_update", &input);
}

#[test]
fn test_tandoor_recipe_batch_update_with_updates() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "updates": [{"id": 1, "name": "Batch Updated"}]
    });

    let result = run_binary("tandoor_recipe_batch_update", &input);
    assert!(result.is_ok(), "Binary should execute");
}

// =============================================================================
// tandoor_recipe_upload_image Tests
// =============================================================================

#[test]
fn test_tandoor_recipe_upload_image_missing_params() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token}
    });

    expect_failure("tandoor_recipe_upload_image", &input);
}

// =============================================================================
// tandoor_scrape_recipe Tests
// =============================================================================

#[test]
fn test_tandoor_scrape_recipe_missing_url() {
    let input = json!({});
    expect_failure("tandoor_scrape_recipe", &input);
}

#[test]
fn test_tandoor_scrape_recipe_with_url() {
    let creds = match get_tandoor_credentials() {
        Some(c) => c,
        None => return,
    };

    let input = json!({
        "tandoor": {"base_url": creds.base_url, "api_token": creds.api_token},
        "url": "https://example.com/recipe"
    });

    let result = run_binary("tandoor_scrape_recipe", &input);
    assert!(result.is_ok(), "Binary should execute");
}
