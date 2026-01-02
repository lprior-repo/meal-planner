#![allow(clippy::unwrap_used)]

use meal_planner::tandoor::{
    CreateShoppingListEntryRequest, ShoppingListEntry, TandoorClient, TandoorConfig,
    UpdateShoppingListEntryRequest,
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
async fn test_list_shopping_list_entries() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/meal-plan/1/shopping/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "count": 2,
            "next": null,
            "previous": null,
            "results": [
                {
                    "id": 1,
                    "list": 1,
                    "ingredient": null,
                    "unit": null,
                    "amount": 5.0,
                    "food": "apples",
                    "checked": false,
                    "order": 1
                },
                {
                    "id": 2,
                    "list": 1,
                    "ingredient": null,
                    "unit": null,
                    "amount": 2.0,
                    "food": "oranges",
                    "checked": true,
                    "order": 2
                }
            ]
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.list_shopping_list_entries(1)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let entries: Vec<ShoppingListEntry> = result.expect("Should succeed");
    assert_eq!(entries.len(), 2);
    assert_eq!(entries[0].food, Some("apples".to_string()));
    assert!(!entries[0].checked);
    assert!(entries[1].checked);
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_create_shopping_list_entry() {
    let mock_server = MockServer::start().await;

    let entry_req = CreateShoppingListEntryRequest {
        list: 1,
        ingredient: None,
        unit: None,
        amount: Some(3.0),
        food: Some("milk".to_string()),
        checked: Some(false),
        order: None,
    };

    Mock::given(method("POST"))
        .and(path("/api/meal-plan/1/shopping/"))
        .respond_with(ResponseTemplate::new(201).set_body_json(json!({
            "id": 3,
            "list": 1,
            "ingredient": null,
            "unit": null,
            "amount": 3.0,
            "food": "milk",
            "checked": false,
            "order": 3
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.create_shopping_list_entry(1, &entry_req)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let entry: ShoppingListEntry = result.expect("Should succeed");
    assert_eq!(entry.id, 3);
    assert_eq!(entry.food, Some("milk".to_string()));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_update_shopping_list_entry() {
    let mock_server = MockServer::start().await;

    let update_req = UpdateShoppingListEntryRequest {
        list: Some(1),
        ingredient: Some(1),
        unit: None,
        amount: Some(2.5),
        food: None,
        checked: Some(true),
        order: None,
    };

    Mock::given(method("PATCH"))
        .and(path("/api/meal-plan/1/shopping/1/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "id": 1,
            "list": 1,
            "ingredient": null,
            "unit": null,
            "amount": 2.5,
            "food": "apples",
            "checked": true,
            "order": 1
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.update_shopping_list_entry(1, 1, &update_req)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let entry: ShoppingListEntry = result.expect("Should succeed");
    assert_eq!(entry.id, 1);
    assert!(entry.checked);
    assert_eq!(entry.amount, Some(2.5));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_delete_shopping_list_entry() {
    let mock_server = MockServer::start().await;

    Mock::given(method("DELETE"))
        .and(path("/api/meal-plan/1/shopping/1/"))
        .respond_with(ResponseTemplate::new(204))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.delete_shopping_list_entry(1, 1)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_list_shopping_list_entries_empty() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/meal-plan/2/shopping/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "count": 0,
            "next": null,
            "previous": null,
            "results": []
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.list_shopping_list_entries(2)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let entries: Vec<ShoppingListEntry> = result.expect("Should succeed");
    assert_eq!(entries.len(), 0);
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_delete_shopping_list_entry_not_found() {
    let mock_server = MockServer::start().await;

    Mock::given(method("DELETE"))
        .and(path("/api/meal-plan/1/shopping/999/"))
        .respond_with(ResponseTemplate::new(404).set_body_string("Not Found"))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.delete_shopping_list_entry(1, 999)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("API error (404)"));
}
