//! Meal plan list tests for Tandoor API client
//!
//! Tests: list_meal_plans

#![allow(clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde_json::json;
use wiremock::{
    matchers::{method, path, query_param},
    Mock, MockServer, ResponseTemplate,
};

#[allow(clippy::unwrap_used)]
fn create_test_client(base_url: &str) -> TandoorClient {
    let config = TandoorConfig {
        base_url: base_url.to_string(),
        api_token: "test_token_12345".to_string(),
    };
    TandoorClient::new(&config).unwrap()
}

#[tokio::test]
#[allow(
    clippy::expect_used,
    clippy::unwrap_used,
    clippy::indexing_slicing,
    clippy::too_many_lines
)]
async fn test_list_meal_plans_success() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/meal-plan/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "count": 2,
            "next": null,
            "previous": null,
            "timestamp": "2025-12-31T08:16:22.962719+00:00",
            "results": [
                {
                    "id": 1,
                    "title": "",
                    "recipe": {
                        "id": 1,
                        "name": "Recipe 1",
                        "description": null,
                        "keywords": null,
                        "working_time": null,
                        "waiting_time": null,
                        "rating": null,
                        "servings": null
                    },
                    "servings": 2.0,
                    "note": "",
                    "note_markdown": "",
                    "from_date": "2025-12-31T00:00:00+01:00",
                    "to_date": "2025-12-31T00:00:00+01:00",
                    "meal_type": {
                        "id": 1,
                        "name": "Breakfast",
                        "order": 0,
                        "time": null,
                        "color": null,
                        "default": false,
                        "created_by": 1
                    },
                    "created_by": 1,
                    "shared": [],
                    "recipe_name": "Recipe 1",
                    "meal_type_name": "Breakfast",
                    "shopping": false
                }
            ]
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.list_meal_plans(None, None)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let response = result.expect("Should succeed");
    assert_eq!(response.count, 2);
    assert_eq!(response.results.len(), 1);
    assert_eq!(response.results[0].recipe_name, "Recipe 1");
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_list_meal_plans_with_pagination() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/meal-plan/"))
        .and(query_param("page", "2"))
        .and(query_param("page_size", "10"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "count": 25,
            "next": null,
            "previous": "http://localhost/api/meal-plan/?page=1&page_size=10",
            "timestamp": "2025-12-31T08:16:22.962719+00:00",
            "results": []
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.list_meal_plans(Some(2), Some(10))
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let response = result.expect("Should succeed");
    assert_eq!(response.count, 25);
}
