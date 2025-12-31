//! Meal type tests for Tandoor API client
//!
//! Tests meal type CRUD operations.

#![allow(clippy::expect_used)]

use meal_planner::tandoor::{
    CreateMealTypeRequest, TandoorClient, TandoorConfig, UpdateMealTypeRequest,
};
use serde_json::json;
use wiremock::{
    matchers::{header, method, path},
    Mock, MockServer, ResponseTemplate,
};

/// Helper to create a test client pointing to the mock server
#[allow(clippy::unwrap_used)]
fn create_test_client(base_url: &str) -> TandoorClient {
    let config = TandoorConfig {
        base_url: base_url.to_string(),
        api_token: "test_token_12345".to_string(),
    };
    TandoorClient::new(&config).unwrap()
}

// ============================================================================
// Meal Type Tests
// ============================================================================

#[tokio::test]
#[allow(
    clippy::expect_used,
    clippy::unwrap_used,
    clippy::indexing_slicing,
    clippy::too_many_lines
)]
async fn test_list_meal_types_success() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/meal-type/"))
        .and(header("Authorization", "Bearer test_token_12345"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "count": 3,
            "next": null,
            "previous": null,
            "results": [
                {
                    "id": 1,
                    "name": "Breakfast",
                    "order": 0,
                    "time": "08:00",
                    "color": null,
                    "default": true,
                    "created_by": 1
                },
                {
                    "id": 2,
                    "name": "Lunch",
                    "order": 1,
                    "time": "12:00",
                    "color": null,
                    "default": false,
                    "created_by": 1
                },
                {
                    "id": 3,
                    "name": "Dinner",
                    "order": 2,
                    "time": "19:00",
                    "color": null,
                    "default": false,
                    "created_by": 1
                }
            ]
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.list_meal_types(None, None)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let response = result.expect("Should succeed");
    assert_eq!(response.count, 3);
    assert_eq!(response.results.len(), 3);
    assert_eq!(response.results[0].name, "Breakfast");
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_get_meal_type_success() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/meal-type/1/"))
        .and(header("Authorization", "Bearer test_token_12345"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 1,
            "name": "Breakfast",
            "order": 0,
            "time": "08:00",
            "color": null,
            "default": true,
            "created_by": 1
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.get_meal_type(1)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let meal_type = result.expect("Should succeed");
    assert_eq!(meal_type.id, 1);
    assert_eq!(meal_type.name, "Breakfast");
    assert!(meal_type.default);
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_create_meal_type_success() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/api/meal-type/"))
        .and(header("Authorization", "Bearer test_token_12345"))
        .respond_with(ResponseTemplate::new(201).set_body_json(json!({
            "id": 4,
            "name": "Snack",
            "order": 3,
            "time": "15:00",
            "color": null,
            "default": false,
            "created_by": 1
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        let request = CreateMealTypeRequest {
            name: "Snack".to_string(),
            order: Some(3),
            time: Some("15:00".to_string()),
            color: None,
            default: Some(false),
        };
        client.create_meal_type(&request)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let meal_type = result.expect("Should succeed");
    assert_eq!(meal_type.id, 4);
    assert_eq!(meal_type.name, "Snack");
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_update_meal_type_success() {
    let mock_server = MockServer::start().await;

    Mock::given(method("PATCH"))
        .and(path("/api/meal-type/1/"))
        .and(header("Authorization", "Bearer test_token_12345"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 1,
            "name": "Breakfast Updated",
            "order": 0,
            "time": "07:30",
            "color": "#FF5733",
            "default": true,
            "created_by": 1
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        let request = UpdateMealTypeRequest {
            name: Some("Breakfast Updated".to_string()),
            order: None,
            time: Some("07:30".to_string()),
            color: Some("#FF5733".to_string()),
            default: None,
        };
        client.update_meal_type(1, &request)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let meal_type = result.expect("Should succeed");
    assert_eq!(meal_type.id, 1);
    assert_eq!(meal_type.name, "Breakfast Updated");
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_delete_meal_type_success() {
    let mock_server = MockServer::start().await;

    Mock::given(method("DELETE"))
        .and(path("/api/meal-type/1/"))
        .and(header("Authorization", "Bearer test_token_12345"))
        .respond_with(ResponseTemplate::new(204).set_body_string(""))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.delete_meal_type(1)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_get_meal_type_not_found() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/meal-type/999/"))
        .respond_with(ResponseTemplate::new(404).set_body_string("Not found"))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.get_meal_type(999)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("API error (404)"));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_create_meal_type_auth_error() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/api/meal-type/"))
        .respond_with(ResponseTemplate::new(401).set_body_string("Unauthorized"))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        let request = CreateMealTypeRequest {
            name: "Snack".to_string(),
            order: None,
            time: None,
            color: None,
            default: None,
        };
        client.create_meal_type(&request)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("Authentication failed"));
}
