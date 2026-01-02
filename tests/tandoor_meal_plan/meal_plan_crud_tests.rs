//! Meal plan CRUD tests for Tandoor API client
//!
//! Tests: create_meal_plan, update_meal_plan, delete_meal_plan

#![allow(clippy::unwrap_used)]

use meal_planner::tandoor::{
    CreateMealPlanRequest, TandoorClient, TandoorConfig, UpdateMealPlanRequest,
};
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
async fn test_create_meal_plan_success() {
    let mock_server = MockServer::start().await;

    let create_request = CreateMealPlanRequest {
        recipe: 1,
        meal_type: 1,
        from_date: "2025-12-31".to_string(),
        to_date: None,
        servings: 2.0,
        title: None,
        note: None,
    };

    Mock::given(method("POST"))
        .and(path("/api/meal-plan/"))
        .respond_with(ResponseTemplate::new(201).set_body_json(json!({
            "id": 1,
            "title": "",
            "recipe": {
                "id": 1,
                "name": "Test Recipe",
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
            "recipe_name": "Test Recipe",
            "meal_type_name": "Breakfast",
            "shopping": false
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.create_meal_plan(&create_request)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let meal_plan = result.expect("Should succeed");
    assert_eq!(meal_plan.id, 1);
    assert!((meal_plan.servings - 2.0).abs() < f64::EPSILON);
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::too_many_lines)]
async fn test_update_meal_plan_success() {
    let mock_server = MockServer::start().await;

    let update_request = UpdateMealPlanRequest {
        recipe: Some(2),
        meal_type: None,
        from_date: None,
        to_date: None,
        servings: Some(3.0),
        title: None,
        note: None,
    };

    Mock::given(method("PATCH"))
        .and(path("/api/meal-plan/1/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 1,
            "title": "",
            "recipe": {
                "id": 2,
                "name": "Updated Recipe",
                "description": null,
                "keywords": null,
                "working_time": null,
                "waiting_time": null,
                "rating": null,
                "servings": null
            },
            "servings": 3.0,
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
            "recipe_name": "Updated Recipe",
            "meal_type_name": "Breakfast",
            "shopping": false
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.update_meal_plan(1, &update_request)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let meal_plan = result.expect("Should succeed");
    assert!((meal_plan.servings - 3.0).abs() < f64::EPSILON);
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_delete_meal_plan_success() {
    let mock_server = MockServer::start().await;

    Mock::given(method("DELETE"))
        .and(path("/api/meal-plan/1/"))
        .respond_with(ResponseTemplate::new(204))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.delete_meal_plan(1)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_delete_meal_plan_not_found() {
    let mock_server = MockServer::start().await;

    Mock::given(method("DELETE"))
        .and(path("/api/meal-plan/999/"))
        .respond_with(ResponseTemplate::new(404).set_body_string("Not Found"))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.delete_meal_plan(999)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("API error (404)"));
}
