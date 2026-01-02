//! Acceptance test for tandoor_recipe_update_nutrition binary
//!
//! This test defines the expected behavior of the binary using the ATDD Four-Layer pattern:
//! Test → DSL → Driver → SUT
//!
//! WHAT the binary should do:
//! - Accept recipe_id and nutrition data (calories, protein, carbohydrates, fat)
//! - Call Tandoor API PATCH /api/recipe/{id}/ endpoint with nutrition fields
//! - Return JSON output with success status and updated recipe

use serde_json::{json, Value};
use std::process::Command;
use wiremock::{
    matchers::{body_json, method, path},
    Mock, MockServer, ResponseTemplate,
};

const BINARY_NAME: &str = "tandoor_recipe_update_nutrition";

fn run_binary(input: &Value) -> Result<std::process::Output, std::io::Error> {
    Command::new("cargo")
        .args(["run", "--bin", BINARY_NAME, "--", &input.to_string()])
        .output()
}

#[tokio::test]
async fn acceptance_update_recipe_nutrition_success() {
    let mock_server = MockServer::start().await;

    let nutrition_update = json!({
        "calories": 450.0,
        "protein": 25.0,
        "carbohydrates": 55.0,
        "fat": 12.0
    });

    let expected_request = json!({
        "nutrition": {
            "calories": 450.0,
            "proteins": 25.0,
            "carbohydrates": 55.0,
            "fats": 12.0
        }
    });

    Mock::given(method("PATCH"))
        .and(path("/api/recipe/123/"))
        .and(body_json(expected_request))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 123,
            "name": "Test Recipe",
            "nutrition": {
                "calories": 450.0,
                "proteins": 25.0,
                "carbohydrates": 55.0,
                "fats": 12.0
            }
        })))
        .mount(&mock_server)
        .await;

    let input = json!({
        "tandoor": {
            "base_url": mock_server.uri(),
            "api_token": "test_token"
        },
        "recipe_id": 123,
        "nutrition": nutrition_update
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
    assert_eq!(response["recipe_id"], 123, "Should return recipe ID");
}

#[tokio::test]
async fn acceptance_partial_nutrition_update() {
    let mock_server = MockServer::start().await;

    let expected_request = json!({
        "nutrition": {
            "calories": 300.0
        }
    });

    Mock::given(method("PATCH"))
        .and(path("/api/recipe/456/"))
        .and(body_json(expected_request))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 456,
            "name": "Partial Update Recipe",
            "nutrition": {
                "calories": 300.0,
                "proteins": null,
                "carbohydrates": null,
                "fats": null
            }
        })))
        .mount(&mock_server)
        .await;

    let input = json!({
        "tandoor": {
            "base_url": mock_server.uri(),
            "api_token": "test_token"
        },
        "recipe_id": 456,
        "nutrition": {
            "calories": 300.0
        }
    });

    let output = run_binary(&input).expect("Binary should run");

    assert!(
        output.status.success(),
        "Binary should succeed for partial update"
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
        "nutrition": {
            "calories": 500.0
        }
    });

    let output = run_binary(&input).expect("Binary should run");

    assert!(!output.status.success(), "Binary should fail for 404");
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
