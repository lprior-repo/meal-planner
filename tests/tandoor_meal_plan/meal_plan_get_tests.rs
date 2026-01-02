//! Meal plan get tests for Tandoor API client
//!
//! Tests: get_meal_plan

#![allow(clippy::unwrap_used)]

use meal_planner::tandoor::{TandoorClient, TandoorConfig};
use serde_json::json;
use wiremock::{
    matchers::{method, path},
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::too_many_lines)]
async fn test_get_meal_plan_success() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/meal-plan/1/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 1,
            "title": "Test Meal",
            "recipe": {
                "id": 1,
                "name": "Test Recipe",
                "description": "Test Description",
                "keywords": null,
                "working_time": 20,
                "waiting_time": null,
                "rating": 4.5,
                "servings": 4
            },
            "servings": 2.0,
            "note": "Notes here",
            "note_markdown": "**Notes** here",
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
            "recipe_name": "Test Recipe",
            "meal_type_name": "Breakfast",
            "shopping": false
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.get_meal_plan(1)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let meal_plan = result.expect("Should succeed");
    assert_eq!(meal_plan.id, 1);
    assert!((meal_plan.servings - 2.0).abs() < f64::EPSILON);
    assert_eq!(meal_plan.recipe_name, "Test Recipe");
}
