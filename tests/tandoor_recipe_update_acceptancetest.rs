//! Acceptance test for tandoor_recipe_update Windmill flow
//!
//! Dave Farley says: "Validate structure, then test manually in production."
//!
//! This test defines the expected behavior of the Windmill flow using ATDD:
//! Test → DSL → Driver → SUT
//!
//! WHAT the flow should do:
//! - Accept recipe_id and optional update fields (name, description, servings, timing)
//! - Call Tandoor API PATCH /api/recipe/{id}/ endpoint
//! - Return JSON output with success status and updated recipe

#![allow(clippy::unwrap_used, clippy::expect_used)]

use serde_json::{json, Value};
use std::process::Command;
use wiremock::{
    matchers::{body_json, method, path},
    Mock, MockServer, ResponseTemplate,
};

const BINARY_NAME: &str = "tandoor_recipe_update";

fn run_binary(input: &Value) -> Result<std::process::Output, std::io::Error> {
    Command::new("cargo")
        .args(["run", "--bin", BINARY_NAME, "--", &input.to_string()])
        .output()
}

#[tokio::test]
async fn acceptance_update_recipe_success() {
    let mock_server = MockServer::start().await;

    let expected_request = json!({
        "name": "Updated Recipe Name",
        "description": "A delicious updated recipe"
    });

    Mock::given(method("PATCH"))
        .and(path("/api/recipe/123/"))
        .and(body_json(expected_request))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 123,
            "name": "Updated Recipe Name",
            "description": "A delicious updated recipe",
            "servings": 4,
            "working_time": 30,
            "waiting_time": 60
        })))
        .mount(&mock_server)
        .await;

    let input = json!({
        "tandoor": {
            "base_url": mock_server.uri(),
            "api_token": "test_token"
        },
        "recipe_id": 123,
        "name": "Updated Recipe Name",
        "description": "A delicious updated recipe"
    });

    let output = run_binary(&input).expect("Binary should run");

    assert!(
        output.status.success(),
        "Binary should succeed: {}",
        String::from_utf8_lossy(&output.stderr)
    );

    let response: Value = serde_json::from_slice(&output.stdout).expect("Should return valid JSON");

    assert!(
        response["success"].as_bool().unwrap_or(false),
        "Should be successful"
    );
    assert_eq!(response["recipe"]["id"], 123, "Should return recipe ID");
    assert_eq!(
        response["recipe"]["name"], "Updated Recipe Name",
        "Should return updated name"
    );
}

#[tokio::test]
async fn acceptance_partial_update_name_only() {
    let mock_server = MockServer::start().await;

    let expected_request = json!({
        "name": "New Name Only"
    });

    Mock::given(method("PATCH"))
        .and(path("/api/recipe/456/"))
        .and(body_json(expected_request))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 456,
            "name": "New Name Only",
            "description": null,
            "servings": 2,
            "working_time": null,
            "waiting_time": null
        })))
        .mount(&mock_server)
        .await;

    let input = json!({
        "tandoor": {
            "base_url": mock_server.uri(),
            "api_token": "test_token"
        },
        "recipe_id": 456,
        "name": "New Name Only"
    });

    let output = run_binary(&input).expect("Binary should run");

    assert!(
        output.status.success(),
        "Binary should succeed for partial update"
    );

    let response: Value = serde_json::from_slice(&output.stdout).expect("Should return valid JSON");

    assert!(response["success"].as_bool().unwrap_or(false));
    assert_eq!(response["recipe"]["id"], 456);
}

#[tokio::test]
async fn acceptance_update_servings_and_timing() {
    let mock_server = MockServer::start().await;

    let expected_request = json!({
        "servings": 8,
        "working_time": 45,
        "waiting_time": 120
    });

    Mock::given(method("PATCH"))
        .and(path("/api/recipe/789/"))
        .and(body_json(expected_request))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 789,
            "name": "Large Batch Recipe",
            "servings": 8,
            "working_time": 45,
            "waiting_time": 120
        })))
        .mount(&mock_server)
        .await;

    let input = json!({
        "tandoor": {
            "base_url": mock_server.uri(),
            "api_token": "test_token"
        },
        "recipe_id": 789,
        "servings": 8,
        "working_time": 45,
        "waiting_time": 120
    });

    let output = run_binary(&input).expect("Binary should run");

    assert!(
        output.status.success(),
        "Binary should succeed for timing update"
    );

    let response: Value = serde_json::from_slice(&output.stdout).expect("Should return valid JSON");

    assert!(response["success"].as_bool().unwrap_or(false));
    assert_eq!(response["recipe"]["servings"], 8);
}

#[tokio::test]
async fn acceptance_update_minimal_fields() {
    let mock_server = MockServer::start().await;

    let expected_request = json!({});

    Mock::given(method("PATCH"))
        .and(path("/api/recipe/100/"))
        .and(body_json(expected_request))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 100,
            "name": "No Change Recipe",
            "description": null,
            "servings": null,
            "working_time": null,
            "waiting_time": null
        })))
        .mount(&mock_server)
        .await;

    let input = json!({
        "tandoor": {
            "base_url": mock_server.uri(),
            "api_token": "test_token"
        },
        "recipe_id": 100
    });

    let output = run_binary(&input).expect("Binary should run");

    assert!(
        output.status.success(),
        "Binary should succeed with minimal fields"
    );

    let response: Value = serde_json::from_slice(&output.stdout).expect("Should return valid JSON");

    assert!(response["success"].as_bool().unwrap_or(false));
}

#[tokio::test]
async fn acceptance_recipe_not_found() {
    let mock_server = MockServer::start().await;

    Mock::given(method("PATCH"))
        .and(path("/api/recipe/999/"))
        .respond_with(ResponseTemplate::new(404).set_body_string("Not Found"))
        .mount(&mock_server)
        .await;

    let input = json!({
        "tandoor": {
            "base_url": mock_server.uri(),
            "api_token": "test_token"
        },
        "recipe_id": 999,
        "name": "Ghost Recipe"
    });

    let output = run_binary(&input).expect("Binary should run");

    assert!(!output.status.success(), "Binary should fail for 404");

    let response: Value = serde_json::from_slice(&output.stdout).expect("Should return valid JSON");

    assert!(!response["success"].as_bool().unwrap_or(true));
    assert!(response["error"].as_str().unwrap_or("").contains("404"));
}

#[tokio::test]
async fn acceptance_invalid_auth() {
    let mock_server = MockServer::start().await;

    Mock::given(method("PATCH"))
        .and(path("/api/recipe/123/"))
        .respond_with(ResponseTemplate::new(401).set_body_string("Unauthorized"))
        .mount(&mock_server)
        .await;

    let input = json!({
        "tandoor": {
            "base_url": mock_server.uri(),
            "api_token": "invalid_token"
        },
        "recipe_id": 123,
        "name": "Protected Recipe"
    });

    let output = run_binary(&input).expect("Binary should run");

    assert!(!output.status.success(), "Binary should fail for 401");

    let response: Value = serde_json::from_slice(&output.stdout).expect("Should return valid JSON");

    assert!(!response["success"].as_bool().unwrap_or(true));
}

#[tokio::test]
async fn acceptance_invalid_input() {
    let input = json!({
        "tandoor": {
            "base_url": "not-a-url",
            "api_token": "test"
        },
        "recipe_id": "invalid"
    });

    let output = run_binary(&input).expect("Binary should run");

    assert!(
        !output.status.success(),
        "Binary should fail for invalid input"
    );
}
