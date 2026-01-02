#![allow(clippy::unwrap_used)]

use meal_planner::tandoor::{ShoppingListRecipe, TandoorClient, TandoorConfig};
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
async fn test_add_recipe_to_shopping_list() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/api/shopping-list-recipe/"))
        .respond_with(ResponseTemplate::new(201).set_body_json(json!({
            "count": 1,
            "next": null,
            "previous": null,
            "results": [
                {
                    "id": 1,
                    "list": 1,
                    "mealplan": 1,
                    "recipe": 5,
                    "recipe_name": "Test Recipe",
                    "servings": 4.0,
                    "entries": [
                        {
                            "id": 1,
                            "list": 1,
                            "ingredient": null,
                            "unit": null,
                            "amount": 2.0,
                            "food": "flour",
                            "checked": false,
                            "order": 1
                        },
                        {
                            "id": 2,
                            "list": 1,
                            "ingredient": null,
                            "unit": null,
                            "amount": 1.0,
                            "food": "sugar",
                            "checked": false,
                            "order": 2
                        }
                    ]
                }
            ]
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.add_recipe_to_shopping_list(1, 5, 4.0)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let recipes: Vec<ShoppingListRecipe> = result.expect("Should succeed");
    assert_eq!(recipes.len(), 1);
    assert_eq!(recipes[0].recipe, 5);
    assert_eq!(recipes[0].recipe_name, "Test Recipe");
    assert_eq!(recipes[0].mealplan, 1);
    assert_eq!(recipes[0].servings, 4.0);
}
