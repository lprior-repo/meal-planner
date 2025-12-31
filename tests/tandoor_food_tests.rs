//! Food tests for Tandoor API client
//!
//! Tests food CRUD operations.

#![allow(clippy::expect_used)]

use meal_planner::tandoor::{
    CreateFoodRequestData, TandoorClient, TandoorConfig, UpdateFoodRequest,
};
use serde_json::json;
use wiremock::{
    matchers::{method, path, query_param},
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
// Food CRUD Operations
// ============================================================================

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
async fn test_list_foods_success() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/food/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "count": 3,
            "next": null,
            "previous": null,
            "results": [
                {
                    "id": 1,
                    "name": "Chicken",
                    "description": "Poultry meat"
                },
                {
                    "id": 2,
                    "name": "Rice",
                    "description": null
                },
                {
                    "id": 3,
                    "name": "Broccoli",
                    "description": "Green vegetable"
                }
            ]
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.list_foods(None, None)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let foods = result.expect("Should succeed");
    assert_eq!(foods.count, 3);
    assert_eq!(foods.results.len(), 3);
    assert_eq!(foods.results[0].name, "Chicken");
    assert_eq!(foods.results[1].id, 2);
    assert_eq!(
        foods.results[2].description,
        Some("Green vegetable".to_string())
    );
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_list_foods_with_pagination() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/food/"))
        .and(query_param("page", "1"))
        .and(query_param("page_size", "10"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "count": 50,
            "next": "http://localhost/api/food/?page=2&page_size=10",
            "previous": null,
            "results": [
                {
                    "id": 1,
                    "name": "Chicken",
                    "description": null
                }
            ]
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.list_foods(Some(1), Some(10))
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let foods = result.expect("Should succeed");
    assert_eq!(foods.count, 50);
    assert!(foods.next.is_some());
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_get_food_success() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/food/42/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 42,
            "name": "Salmon",
            "description": "Fatty fish"
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.get_food(42)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let food = result.expect("Should succeed");
    assert_eq!(food.id, 42);
    assert_eq!(food.name, "Salmon");
    assert_eq!(food.description, Some("Fatty fish".to_string()));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_get_food_not_found() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/food/999/"))
        .respond_with(ResponseTemplate::new(404).set_body_string("Not Found"))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.get_food(999)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("API error (404)"));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_create_food_success() {
    let mock_server = MockServer::start().await;

    let create_request = CreateFoodRequestData {
        name: "Pasta".to_string(),
        description: Some("Wheat pasta".to_string()),
    };

    Mock::given(method("POST"))
        .and(path("/api/food/"))
        .respond_with(ResponseTemplate::new(201).set_body_json(json!({
            "id": 100,
            "name": "Pasta",
            "description": "Wheat pasta"
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.create_food(&create_request)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let created = result.expect("Should succeed");
    assert_eq!(created.id, 100);
    assert_eq!(created.name, "Pasta");
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_create_food_minimal() {
    let mock_server = MockServer::start().await;

    let create_request = CreateFoodRequestData {
        name: "Tofu".to_string(),
        description: None,
    };

    Mock::given(method("POST"))
        .and(path("/api/food/"))
        .respond_with(ResponseTemplate::new(201).set_body_json(json!({
            "id": 101,
            "name": "Tofu",
            "description": null
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.create_food(&create_request)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let created = result.expect("Should succeed");
    assert_eq!(created.id, 101);
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_create_food_auth_error() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/api/food/"))
        .respond_with(ResponseTemplate::new(403).set_body_string("Forbidden"))
        .mount(&mock_server)
        .await;

    let create_request = CreateFoodRequestData {
        name: "Eggs".to_string(),
        description: None,
    };

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.create_food(&create_request)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("Authentication failed"));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_update_food_success() {
    let mock_server = MockServer::start().await;

    let update_request = UpdateFoodRequest {
        name: Some("Quinoa".to_string()),
        description: Some("Ancient grain".to_string()),
    };

    Mock::given(method("PATCH"))
        .and(path("/api/food/50/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 50,
            "name": "Quinoa",
            "description": "Ancient grain"
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.update_food(50, &update_request)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let updated = result.expect("Should succeed");
    assert_eq!(updated.id, 50);
    assert_eq!(updated.name, "Quinoa");
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_update_food_partial() {
    let mock_server = MockServer::start().await;

    let update_request = UpdateFoodRequest {
        name: Some("Lentils".to_string()),
        description: None,
    };

    Mock::given(method("PATCH"))
        .and(path("/api/food/60/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 60,
            "name": "Lentils",
            "description": "Legume"
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.update_food(60, &update_request)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_update_food_not_found() {
    let mock_server = MockServer::start().await;

    Mock::given(method("PATCH"))
        .and(path("/api/food/999/"))
        .respond_with(ResponseTemplate::new(404).set_body_string("Not Found"))
        .mount(&mock_server)
        .await;

    let update_request = UpdateFoodRequest {
        name: Some("NonExistent".to_string()),
        description: None,
    };

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.update_food(999, &update_request)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("API error (404)"));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_delete_food_success() {
    let mock_server = MockServer::start().await;

    Mock::given(method("DELETE"))
        .and(path("/api/food/30/"))
        .respond_with(ResponseTemplate::new(204))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.delete_food(30)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_delete_food_not_found() {
    let mock_server = MockServer::start().await;

    Mock::given(method("DELETE"))
        .and(path("/api/food/999/"))
        .respond_with(ResponseTemplate::new(404).set_body_string("Not Found"))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.delete_food(999)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("API error (404)"));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_delete_food_auth_error() {
    let mock_server = MockServer::start().await;

    Mock::given(method("DELETE"))
        .and(path("/api/food/40/"))
        .respond_with(ResponseTemplate::new(401).set_body_string("Unauthorized"))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.delete_food(40)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("Authentication failed"));
}
