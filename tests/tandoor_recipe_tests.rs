//! Recipe tests for Tandoor API client
//!
//! Tests recipe listing, scraping, creation, and import operations.

#![allow(clippy::expect_used)]

use meal_planner::tandoor::{
    CreateFoodRequest, CreateIngredientRequest, CreateKeywordRequest, CreateRecipeRequest,
    CreateStepRequest, CreatedRecipe, PaginatedResponse, RecipeFromSourceResponse,
    RecipeImportResult, RecipeSummary, TandoorClient, TandoorConfig,
};
use serde_json::json;
use wiremock::{
    matchers::{body_json, method, path, query_param},
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
// Recipe Listing
// ============================================================================

#[tokio::test]
#[allow(
    clippy::expect_used,
    clippy::unwrap_used,
    clippy::indexing_slicing,
    clippy::too_many_lines
)]
async fn test_list_recipes_no_pagination() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/recipe/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "count": 3,
            "next": null,
            "previous": null,
            "results": [
                {
                    "id": 1,
                    "name": "Scrambled Eggs",
                    "description": "Quick breakfast",
                    "keywords": [{"id": 1, "name": "breakfast"}],
                    "working_time": 5,
                    "waiting_time": 0,
                    "rating": 4.5,
                    "servings": 2
                },
                {
                    "id": 2,
                    "name": "Pasta Carbonara",
                    "description": null,
                    "keywords": null,
                    "working_time": 20,
                    "waiting_time": null,
                    "rating": null,
                    "servings": 4
                },
                {
                    "id": 3,
                    "name": "Chicken Soup",
                    "description": "Comfort food",
                    "keywords": [],
                    "working_time": null,
                    "waiting_time": 30,
                    "rating": 5.0,
                    "servings": 6
                }
            ]
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.list_recipes(None, None)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let paginated: PaginatedResponse<RecipeSummary> = result.expect("Should succeed");
    assert_eq!(paginated.count, 3);
    assert_eq!(paginated.results.len(), 3);
    assert_eq!(paginated.results[0].name, "Scrambled Eggs");
    assert_eq!(paginated.results[1].id, 2);
    assert_eq!(paginated.results[2].servings, Some(6));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
async fn test_list_recipes_with_pagination() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/recipe/"))
        .and(query_param("page", "2"))
        .and(query_param("page_size", "10"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "count": 25,
            "next": "http://localhost/api/recipe/?page=3&page_size=10",
            "previous": "http://localhost/api/recipe/?page=1&page_size=10",
            "results": [
                {
                    "id": 11,
                    "name": "Recipe 11",
                    "description": null,
                    "keywords": null,
                    "working_time": null,
                    "waiting_time": null,
                    "rating": null,
                    "servings": null
                }
            ]
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.list_recipes(Some(2), Some(10))
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let paginated: PaginatedResponse<RecipeSummary> = result.expect("Should succeed");
    assert_eq!(paginated.count, 25);
    assert!(paginated.next.is_some());
    assert!(paginated.previous.is_some());
    assert_eq!(paginated.results[0].id, 11);
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_list_recipes_empty() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/recipe/"))
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
        client.list_recipes(None, None)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let paginated: PaginatedResponse<RecipeSummary> = result.expect("Should succeed");
    assert_eq!(paginated.count, 0);
    assert_eq!(paginated.results.len(), 0);
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_list_recipes_api_error() {
    let mock_server = MockServer::start().await;

    Mock::given(method("GET"))
        .and(path("/api/recipe/"))
        .respond_with(ResponseTemplate::new(404).set_body_string("Not Found"))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.list_recipes(None, None)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("API error (404)"));
}

// ============================================================================
// Recipe Scraping (from URL)
// ============================================================================

#[tokio::test]
#[allow(
    clippy::expect_used,
    clippy::unwrap_used,
    clippy::indexing_slicing,
    clippy::too_many_lines
)]
async fn test_scrape_recipe_success() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/api/recipe-from-source/"))
        .and(body_json(json!({
            "url": "https://example.com/recipe"
        })))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "error": false,
            "msg": "Recipe scraped successfully",
            "recipe": {
                "name": "Chocolate Cake",
                "description": "Delicious chocolate cake",
                "source_url": "https://example.com/recipe",
                "image": "https://example.com/image.jpg",
                "servings": 8,
                "servings_text": "8 servings",
                "working_time": 30,
                "waiting_time": 45,
                "internal": false,
                "steps": [
                    {
                        "instruction": "Mix ingredients",
                        "show_ingredients_table": true,
                        "ingredients": [
                            {
                                "amount": 2.0,
                                "food": {"name": "eggs"},
                                "unit": null,
                                "note": "",
                                "original_text": "2 eggs"
                            },
                            {
                                "amount": 1.0,
                                "food": {"name": "flour"},
                                "unit": {"name": "cup"},
                                "note": "all-purpose",
                                "original_text": "1 cup all-purpose flour"
                            }
                        ]
                    },
                    {
                        "instruction": "Bake at 350°F",
                        "show_ingredients_table": true,
                        "ingredients": []
                    }
                ],
                "keywords": [
                    {"id": null, "label": null, "name": "dessert"},
                    {"id": 5, "label": "Sweet", "name": "sweet"}
                ]
            },
            "recipe_tree": null,
            "images": ["https://example.com/image1.jpg", "https://example.com/image2.jpg"]
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.scrape_recipe_from_url("https://example.com/recipe")
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let scraped: RecipeFromSourceResponse = result.expect("Should succeed");
    assert!(!scraped.error);
    assert_eq!(scraped.msg, "Recipe scraped successfully");

    let recipe = scraped.recipe.expect("Should have recipe data");
    assert_eq!(recipe.name, "Chocolate Cake");
    assert_eq!(recipe.servings, 8);
    assert_eq!(recipe.working_time, 30);
    assert_eq!(recipe.steps.len(), 2);
    assert_eq!(recipe.steps[0].ingredients.len(), 2);
    assert_eq!(recipe.keywords.len(), 2);

    assert!(scraped.images.is_some());
    assert_eq!(scraped.images.as_ref().unwrap().len(), 2);
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_scrape_recipe_failure() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/api/recipe-from-source/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "error": true,
            "msg": "Failed to scrape recipe: unsupported domain",
            "recipe": null,
            "recipe_tree": null,
            "images": null
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.scrape_recipe_from_url("https://unsupported.com/recipe")
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let scraped: RecipeFromSourceResponse = result.expect("Should succeed");
    assert!(scraped.error);
    assert!(scraped.msg.contains("Failed to scrape"));
    assert!(scraped.recipe.is_none());
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_scrape_recipe_auth_error() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/api/recipe-from-source/"))
        .respond_with(ResponseTemplate::new(401).set_body_json(json!({
            "detail": "Invalid token"
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.scrape_recipe_from_url("https://example.com/recipe")
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("Authentication failed"));
}

// ============================================================================
// Recipe Creation
// ============================================================================

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_create_recipe_success() {
    let mock_server = MockServer::start().await;

    let create_request = CreateRecipeRequest {
        name: "Test Recipe".to_string(),
        description: Some("A test recipe".to_string()),
        source_url: Some("https://example.com/recipe".to_string()),
        servings: Some(4),
        working_time: Some(15),
        waiting_time: Some(10),
        keywords: Some(vec![CreateKeywordRequest {
            name: "quick".to_string(),
        }]),
        steps: Some(vec![CreateStepRequest {
            instruction: "Do something".to_string(),
            ingredients: Some(vec![CreateIngredientRequest {
                amount: Some(2.0),
                food: CreateFoodRequest {
                    name: "eggs".to_string(),
                },
                unit: None,
                note: None,
            }]),
        }]),
    };

    Mock::given(method("POST"))
        .and(path("/api/recipe/"))
        .and(body_json(
            serde_json::to_value(&create_request).expect("Serialize request"),
        ))
        .respond_with(ResponseTemplate::new(201).set_body_json(json!({
            "id": 123,
            "name": "Test Recipe"
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.create_recipe(&create_request)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let created: CreatedRecipe = result.expect("Should succeed");
    assert_eq!(created.id, 123);
    assert_eq!(created.name, "Test Recipe");
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_create_recipe_minimal() {
    let mock_server = MockServer::start().await;

    let create_request = CreateRecipeRequest {
        name: "Minimal Recipe".to_string(),
        description: None,
        source_url: None,
        servings: None,
        working_time: None,
        waiting_time: None,
        keywords: None,
        steps: None,
    };

    Mock::given(method("POST"))
        .and(path("/api/recipe/"))
        .respond_with(ResponseTemplate::new(201).set_body_json(json!({
            "id": 456,
            "name": "Minimal Recipe"
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.create_recipe(&create_request)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let created: CreatedRecipe = result.expect("Should succeed");
    assert_eq!(created.id, 456);
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_create_recipe_auth_error() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/api/recipe/"))
        .respond_with(ResponseTemplate::new(403).set_body_string("Forbidden"))
        .mount(&mock_server)
        .await;

    let create_request = CreateRecipeRequest {
        name: "Forbidden".to_string(),
        description: None,
        source_url: None,
        servings: None,
        working_time: None,
        waiting_time: None,
        keywords: None,
        steps: None,
    };

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.create_recipe(&create_request)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("Authentication failed"));
}

// ============================================================================
// Recipe Import (Scrape + Create)
// ============================================================================

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::too_many_lines)]
async fn test_import_recipe_success() {
    let mock_server = MockServer::start().await;

    // Mock scrape response
    Mock::given(method("POST"))
        .and(path("/api/recipe-from-source/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "error": false,
            "msg": "Success",
            "recipe": {
                "name": "Imported Recipe",
                "description": "Imported from web",
                "source_url": "https://example.com/recipe",
                "image": null,
                "servings": 4,
                "servings_text": "",
                "working_time": 20,
                "waiting_time": 0,
                "internal": false,
                "steps": [
                    {
                        "instruction": "Step 1",
                        "show_ingredients_table": true,
                        "ingredients": [
                            {
                                "amount": 1.0,
                                "food": {"name": "onion"},
                                "unit": null,
                                "note": "",
                                "original_text": "1 onion"
                            }
                        ]
                    }
                ],
                "keywords": [
                    {"id": null, "label": null, "name": "dinner"}
                ]
            },
            "recipe_tree": null,
            "images": null
        })))
        .expect(1)
        .mount(&mock_server)
        .await;

    // Mock create response
    Mock::given(method("POST"))
        .and(path("/api/recipe/"))
        .respond_with(ResponseTemplate::new(201).set_body_json(json!({
            "id": 789,
            "name": "Imported Recipe"
        })))
        .expect(1)
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.import_recipe_from_url(
            "https://example.com/recipe",
            Some(vec!["imported".to_string()]),
        )
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let import_result: RecipeImportResult = result.expect("Should succeed");
    assert!(import_result.success);
    assert_eq!(import_result.recipe_id, Some(789));
    assert_eq!(
        import_result.recipe_name,
        Some("Imported Recipe".to_string())
    );
    assert_eq!(import_result.source_url, "https://example.com/recipe");
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_import_recipe_scrape_failure() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/api/recipe-from-source/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "error": true,
            "msg": "Scraping failed",
            "recipe": null,
            "recipe_tree": null,
            "images": null
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.import_recipe_from_url("https://example.com/bad-recipe", None)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let import_result: RecipeImportResult = result.expect("Should succeed");
    assert!(!import_result.success);
    assert!(import_result.recipe_id.is_none());
    assert_eq!(import_result.message, "Scraping failed");
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_import_recipe_no_data() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/api/recipe-from-source/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "error": false,
            "msg": "Success but no data",
            "recipe": null,
            "recipe_tree": null,
            "images": null
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.import_recipe_from_url("https://example.com/empty", None)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let import_result: RecipeImportResult = result.expect("Should succeed");
    assert!(!import_result.success);
    assert!(import_result.message.contains("No recipe data"));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used)]
async fn test_import_recipe_create_failure() {
    let mock_server = MockServer::start().await;

    // Mock successful scrape
    Mock::given(method("POST"))
        .and(path("/api/recipe-from-source/"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "error": false,
            "msg": "Success",
            "recipe": {
                "name": "Test Recipe",
                "description": "",
                "source_url": null,
                "image": null,
                "servings": 1,
                "servings_text": "",
                "working_time": 0,
                "waiting_time": 0,
                "internal": false,
                "steps": [],
                "keywords": []
            },
            "recipe_tree": null,
            "images": null
        })))
        .mount(&mock_server)
        .await;

    // Mock failed create
    Mock::given(method("POST"))
        .and(path("/api/recipe/"))
        .respond_with(ResponseTemplate::new(400).set_body_string("Bad request"))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.import_recipe_from_url("https://example.com/recipe", None)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("API error (400)"));
}
