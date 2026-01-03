//! ATDD: tandoor_food_get binary acceptance tests
//!
//! Feature: Get food from Tandoor by ID
//!
//! These tests define WHAT the binary should do in domain language.
//! NO implementation details - just input/output behavior.

use serde_json::json;
use wiremock::{
    matchers::{method, path},
    Mock, MockServer, ResponseTemplate,
};

mod helpers;
use helpers::{run_binary, BinaryError};

#[tokio::test]
async fn should_return_food_when_id_exists() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/food/42/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 42,
            "name": "Salmon",
            "description": "Fresh Atlantic salmon"
        })))
        .mount(&mock_server)
        .await;

    let input = json!({
        "tandoor": {
            "base_url": mock_server.uri(),
            "api_token": "test_token"
        },
        "food_id": 42
    });

    let result = run_binary("tandoor_food_get", &input).await;

    assert!(result.is_ok(), "Binary should succeed for valid food ID");
    let output = result.unwrap();

    assert!(
        output["success"].as_bool().unwrap_or(false),
        "Should return success"
    );
    assert_eq!(output["food"]["id"].as_i64(), Some(42));
    assert_eq!(output["food"]["name"].as_str(), Some("Salmon"));
    assert_eq!(
        output["food"]["description"].as_str(),
        Some("Fresh Atlantic salmon")
    );
}

#[tokio::test]
async fn should_return_error_when_food_not_found() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/food/999/"))
        .respond_with(ResponseTemplate::new(404).set_body_string("Not Found"))
        .mount(&mock_server)
        .await;

    let input = json!({
        "tandoor": {
            "base_url": mock_server.uri(),
            "api_token": "test_token"
        },
        "food_id": 999
    });

    let result = run_binary("tandoor_food_get", &input).await;

    assert!(result.is_ok(), "Binary should complete without panic");
    let output = result.unwrap();

    assert!(
        !output["success"].as_bool().unwrap_or(true),
        "Should return failure"
    );
    assert!(output["error"].is_string(), "Should have error message");
}

#[tokio::test]
async fn should_return_error_on_auth_failure() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/food/1/"))
        .respond_with(ResponseTemplate::new(401).set_body_string("Unauthorized"))
        .mount(&mock_server)
        .await;

    let input = json!({
        "tandoor": {
            "base_url": mock_server.uri(),
            "api_token": "invalid_token"
        },
        "food_id": 1
    });

    let result = run_binary("tandoor_food_get", &input).await;

    assert!(result.is_ok(), "Binary should complete without panic");
    let output = result.unwrap();

    assert!(
        !output["success"].as_bool().unwrap_or(true),
        "Should return failure"
    );
}

#[tokio::test]
async fn should_handle_minimal_input() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/food/1/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 1,
            "name": "Egg",
            "description": null
        })))
        .mount(&mock_server)
        .await;

    let input = json!({
        "tandoor": {
            "base_url": mock_server.uri(),
            "api_token": "test"
        },
        "food_id": 1
    });

    let result = run_binary("tandoor_food_get", &input).await;

    assert!(result.is_ok(), "Binary should handle minimal input");
    let output = result.unwrap();

    assert!(output["success"].as_bool().unwrap_or(false));
    assert_eq!(output["food"]["name"].as_str(), Some("Egg"));
}
