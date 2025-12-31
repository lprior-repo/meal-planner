//! Integration tests for Tandoor API client
//!
//! Tests all client methods with mocked HTTP responses:
//! - Connection testing
//! - Recipe listing with pagination
//! - Recipe scraping from URLs
//! - Recipe creation
//! - Error handling (network, auth, API errors)
//!
//! Uses wiremock for HTTP mocking - no real API calls.

#![allow(clippy::expect_used)]

use meal_planner::tandoor::{
    ConnectionTestResult, CreateFoodRequest, CreateFoodRequestData, CreateIngredientRequest,
    CreateKeywordRequest, CreateRecipeRequest, CreateShoppingListEntryRequest, CreateStepRequest,
    CreatedRecipe, PaginatedResponse, RecipeFromSourceResponse, RecipeImportResult, RecipeSummary,
    ShoppingListEntry, TandoorClient, TandoorConfig, UpdateFoodRequest,
    UpdateShoppingListEntryRequest,
};
use serde_json::json;
use wiremock::{
    matchers::{body_json, header, method, path, query_param},
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
// Connection Testing
// ============================================================================

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
async fn test_connection_success() {
    let mock_server = MockServer::start().await;

    // Mock successful recipe list response
    Mock::given(method("GET"))
        .and(path("/api/recipe/"))
        .and(header("Authorization", "Bearer test_token_12345"))
        .respond_with(ResponseTemplate::new(200).set_body_json(json!({
            "count": 42,
            "next": null,
            "previous": null,
            "results": []
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.test_connection()
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let conn_test: ConnectionTestResult = result.expect("Should succeed");
    assert!(conn_test.success);
    assert_eq!(conn_test.recipe_count, 42);
    assert!(conn_test.message.contains("42"));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
async fn test_connection_auth_failure_401() {
    let mock_server = MockServer::start().await;

    // Mock 401 Unauthorized
    Mock::given(method("GET"))
        .and(path("/api/recipe/"))
        .respond_with(ResponseTemplate::new(401).set_body_json(json!({
            "detail": "Invalid token"
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.test_connection()
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("Authentication failed"));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
async fn test_connection_auth_failure_403() {
    let mock_server = MockServer::start().await;

    // Mock 403 Forbidden
    Mock::given(method("GET"))
        .and(path("/api/recipe/"))
        .respond_with(ResponseTemplate::new(403).set_body_json(json!({
            "detail": "Access denied"
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.test_connection()
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("Authentication failed"));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
async fn test_connection_server_error() {
    let mock_server = MockServer::start().await;

    // Mock 500 Internal Server Error
    Mock::given(method("GET"))
        .and(path("/api/recipe/"))
        .respond_with(ResponseTemplate::new(500).set_body_string("Internal Server Error"))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.test_connection()
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("API error (500)"));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
async fn test_connection_parse_error() {
    let mock_server = MockServer::start().await;

    // Mock invalid JSON response
    Mock::given(method("GET"))
        .and(path("/api/recipe/"))
        .respond_with(ResponseTemplate::new(200).set_body_string("not json"))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.test_connection()
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_err());
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("Failed to parse response"));
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(
    clippy::expect_used,
    clippy::unwrap_used,
    clippy::indexing_slicing,
    clippy::too_many_lines
)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
async fn test_import_recipe_scrape_failure() {
    let mock_server = MockServer::start().await;

    // Mock scrape failure
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
async fn test_import_recipe_no_data() {
    let mock_server = MockServer::start().await;

    // Mock scrape with no recipe data
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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

// ============================================================================
// Network Error Handling
// ============================================================================

#[test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
fn test_network_timeout() {
    // Use an invalid/unroutable IP to simulate network error
    // This won't actually take 30 seconds due to connection refused
    let config = TandoorConfig {
        base_url: "http://192.0.2.1:9999".to_string(), // TEST-NET-1, guaranteed unroutable
        api_token: "test_token".to_string(),
    };
    let client = TandoorClient::new(&config).expect("Client creation should succeed");

    let result = client.test_connection();
    assert!(result.is_err());
    // Network errors are wrapped in HttpError
    let err_msg = result.unwrap_err().to_string();
    assert!(err_msg.contains("HTTP request failed"));
}

// ============================================================================
// Client Configuration
// ============================================================================

#[test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
fn test_client_creation_valid_config() {
    let config = TandoorConfig {
        base_url: "http://localhost:8090".to_string(),
        api_token: "valid_token".to_string(),
    };
    let client = TandoorClient::new(&config);
    assert!(client.is_ok());
}

#[test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
fn test_client_creation_trims_trailing_slash() {
    let config = TandoorConfig {
        base_url: "http://localhost:8090/".to_string(),
        api_token: "test_token".to_string(),
    };
    let client = TandoorClient::new(&config);
    assert!(client.is_ok());
}

#[test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
fn test_client_creation_with_https() {
    let config = TandoorConfig {
        base_url: "https://tandoor.example.com".to_string(),
        api_token: "secure_token".to_string(),
    };
    let client = TandoorClient::new(&config);
    assert!(client.is_ok());
}

// ============================================================================
// Shopping List Operations
// ============================================================================

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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
async fn test_create_shopping_list_entry() {
    let mock_server = MockServer::start().await;

    let entry_req = CreateShoppingListEntryRequest {
        list: 1,
        ingredient: None,
        unit: None,
        amount: Some(3.0),
        food: Some("milk".to_string()),
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
async fn test_update_shopping_list_entry() {
    let mock_server = MockServer::start().await;

    let update_req = UpdateShoppingListEntryRequest {
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
async fn test_add_recipe_to_shopping_list() {
    let mock_server = MockServer::start().await;

    Mock::given(method("POST"))
        .and(path("/api/meal-plan/1/shopping/"))
        .respond_with(ResponseTemplate::new(201).set_body_json(json!({
            "count": 5,
            "next": null,
            "previous": null,
            "results": [
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
        })))
        .mount(&mock_server)
        .await;

    let uri = mock_server.uri();
    let handle = tokio::task::spawn_blocking(move || {
        let client = create_test_client(&uri);
        client.add_recipe_to_shopping_list(1, 5)
    });

    let result = handle.await.expect("Task should complete");

    assert!(result.is_ok());
    let entries: Vec<ShoppingListEntry> = result.expect("Should succeed");
    assert_eq!(entries.len(), 2);
    assert_eq!(entries[0].food, Some("flour".to_string()));
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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

// ============================================================================
// Meal Plan CRUD Operations
// ============================================================================

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
    assert_eq!(meal_plan.servings, 2.0);
    assert_eq!(meal_plan.recipe_name, "Test Recipe");
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
async fn test_create_meal_plan_success() {
    use meal_planner::tandoor::CreateMealPlanRequest;

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
    assert_eq!(meal_plan.servings, 2.0);
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
async fn test_update_meal_plan_success() {
    use meal_planner::tandoor::UpdateMealPlanRequest;

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
    assert_eq!(meal_plan.servings, 3.0);
}

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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

// ============================================================================
// Meal Type Tests
// ============================================================================

#[tokio::test]
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
        let request = meal_planner::tandoor::CreateMealTypeRequest {
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
        let request = meal_planner::tandoor::UpdateMealTypeRequest {
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
#[allow(clippy::expect_used, clippy::unwrap_used, clippy::indexing_slicing)]
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
        let request = meal_planner::tandoor::CreateMealTypeRequest {
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
