//! Tests for Tandoor types and error handling
//!
//! Note: The Tandoor client uses blocking HTTP (reqwest::blocking), which
//! conflicts with async test runtimes. The HTTP-level tests are in the
//! client module's inline tests. Here we test types and error handling.

#![allow(clippy::unwrap_used)]
#![allow(clippy::expect_used)]
#![allow(clippy::panic)]
#![allow(clippy::wildcard_enum_match_arm)]
#![allow(dead_code)]
#![allow(unused_imports)]

use meal_planner::tandoor::{
    TandoorClient, TandoorError, CreateRecipeRequest, CreateStepRequest, TandoorConfig,
    CreateKeywordRequest, CreateIngredientRequest, CreateFoodRequest, CreateUnitRequest,
    RecipeSummary, PaginatedResponse, RecipeImportResult, RecipeFromSourceResponse,
    ConnectionTestResult, CreatedRecipe,
};

// ============================================================================
// CONFIG TESTS
// ============================================================================

#[test]
fn test_tandoor_config_creation() {
    let config = TandoorConfig {
        base_url: "http://localhost:8080".to_string(),
        api_token: "my_secret_token".to_string(),
    };

    assert_eq!(config.base_url, "http://localhost:8080");
    assert_eq!(config.api_token, "my_secret_token");
}

#[test]
fn test_client_creation_success() {
    let config = TandoorConfig {
        base_url: "http://localhost:8080".to_string(),
        api_token: "valid_token".to_string(),
    };

    let result = TandoorClient::new(&config);
    assert!(result.is_ok());
}

#[test]
fn test_client_creation_strips_trailing_slash() {
    let config = TandoorConfig {
        base_url: "http://localhost:8080/".to_string(),
        api_token: "valid_token".to_string(),
    };

    let result = TandoorClient::new(&config);
    assert!(result.is_ok());
}

// ============================================================================
// ERROR TYPE TESTS
// ============================================================================

#[test]
fn test_tandoor_error_display() {
    let http_err = TandoorError::ApiError {
        status: 500,
        message: "Internal Server Error".to_string(),
    };
    let display = format!("{}", http_err);
    assert!(display.contains("500"));
    assert!(display.contains("Internal Server Error"));

    let auth_err = TandoorError::AuthError("Token expired".to_string());
    let display = format!("{}", auth_err);
    assert!(display.contains("Token expired"));

    let parse_err = TandoorError::ParseError("Invalid JSON".to_string());
    let display = format!("{}", parse_err);
    assert!(display.contains("Invalid JSON"));
}

#[test]
fn test_tandoor_error_debug() {
    let err = TandoorError::ApiError {
        status: 404,
        message: "Not Found".to_string(),
    };
    let debug = format!("{:?}", err);
    assert!(debug.contains("ApiError"));
    assert!(debug.contains("404"));
}

// ============================================================================
// REQUEST TYPE TESTS
// ============================================================================

#[test]
fn test_create_recipe_request_minimal() {
    let request = CreateRecipeRequest {
        name: "Simple Recipe".to_string(),
        description: None,
        source_url: None,
        servings: None,
        working_time: None,
        waiting_time: None,
        keywords: None,
        steps: None,
    };

    assert_eq!(request.name, "Simple Recipe");
    assert!(request.description.is_none());
}

#[test]
fn test_create_recipe_request_full() {
    let request = CreateRecipeRequest {
        name: "Full Recipe".to_string(),
        description: Some("A complete recipe".to_string()),
        source_url: Some("https://example.com/recipe".to_string()),
        servings: Some(4),
        working_time: Some(30),
        waiting_time: Some(60),
        keywords: Some(vec![
            CreateKeywordRequest { name: "dinner".to_string() },
            CreateKeywordRequest { name: "healthy".to_string() },
        ]),
        steps: Some(vec![
            CreateStepRequest {
                instruction: "Preheat oven".to_string(),
                ingredients: None,
            },
            CreateStepRequest {
                instruction: "Mix ingredients".to_string(),
                ingredients: Some(vec![
                    CreateIngredientRequest {
                        amount: Some(2.0),
                        food: CreateFoodRequest { name: "flour".to_string() },
                        unit: Some(CreateUnitRequest { name: "cups".to_string() }),
                        note: None,
                    },
                ]),
            },
        ]),
    };

    assert_eq!(request.name, "Full Recipe");
    assert_eq!(request.description.as_ref().unwrap(), "A complete recipe");
    assert_eq!(request.servings, Some(4));
    assert_eq!(request.keywords.as_ref().unwrap().len(), 2);
    assert_eq!(request.steps.as_ref().unwrap().len(), 2);
}

#[test]
fn test_create_step_request() {
    let step = CreateStepRequest {
        instruction: "Mix all ingredients".to_string(),
        ingredients: Some(vec![
            CreateIngredientRequest {
                amount: Some(1.0),
                food: CreateFoodRequest { name: "sugar".to_string() },
                unit: Some(CreateUnitRequest { name: "cup".to_string() }),
                note: Some("optional".to_string()),
            },
        ]),
    };

    assert_eq!(step.instruction, "Mix all ingredients");
    assert_eq!(step.ingredients.as_ref().unwrap().len(), 1);
}

#[test]
fn test_create_ingredient_request() {
    let ingredient = CreateIngredientRequest {
        amount: Some(2.5),
        food: CreateFoodRequest { name: "butter".to_string() },
        unit: Some(CreateUnitRequest { name: "tablespoons".to_string() }),
        note: Some("softened".to_string()),
    };

    assert_eq!(ingredient.amount, Some(2.5));
    assert_eq!(ingredient.food.name, "butter");
    assert_eq!(ingredient.unit.as_ref().unwrap().name, "tablespoons");
    assert_eq!(ingredient.note.as_ref().unwrap(), "softened");
}

// ============================================================================
// RESPONSE TYPE TESTS
// ============================================================================

#[test]
fn test_recipe_import_result_success() {
    let result = RecipeImportResult {
        success: true,
        recipe_id: Some(123),
        recipe_name: Some("Imported Recipe".to_string()),
        source_url: "https://example.com".to_string(),
        message: "Successfully imported".to_string(),
    };

    assert!(result.success);
    assert_eq!(result.recipe_id, Some(123));
}

#[test]
fn test_recipe_import_result_failure() {
    let result = RecipeImportResult {
        success: false,
        recipe_id: None,
        recipe_name: None,
        source_url: "https://bad-url.com".to_string(),
        message: "Failed to parse recipe".to_string(),
    };

    assert!(!result.success);
    assert!(result.recipe_id.is_none());
}

#[test]
fn test_connection_test_result() {
    let result = ConnectionTestResult {
        success: true,
        message: "Connected to 5 recipes".to_string(),
        recipe_count: 5,
    };

    assert!(result.success);
    assert_eq!(result.recipe_count, 5);
}

#[test]
fn test_created_recipe() {
    let recipe = CreatedRecipe {
        id: 42,
        name: "New Recipe".to_string(),
    };

    assert_eq!(recipe.id, 42);
    assert_eq!(recipe.name, "New Recipe");
}

// ============================================================================
// SERIALIZATION TESTS
// ============================================================================

#[test]
fn test_create_recipe_request_serialization() {
    let request = CreateRecipeRequest {
        name: "Test".to_string(),
        description: Some("Desc".to_string()),
        source_url: None,
        servings: Some(2),
        working_time: None,
        waiting_time: None,
        keywords: None,
        steps: None,
    };

    let json = serde_json::to_string(&request).unwrap();
    assert!(json.contains("\"name\":\"Test\""));
    assert!(json.contains("\"description\":\"Desc\""));
    assert!(json.contains("\"servings\":2"));
}

#[test]
fn test_keyword_request_serialization() {
    let keyword = CreateKeywordRequest {
        name: "vegetarian".to_string(),
    };

    let json = serde_json::to_string(&keyword).unwrap();
    assert!(json.contains("\"name\":\"vegetarian\""));
}

#[test]
fn test_paginated_response_deserialization() {
    let json = r#"{
        "count": 10,
        "next": "http://example.com/page2",
        "previous": null,
        "results": [
            {
                "id": 1,
                "name": "Recipe One",
                "keywords": []
            }
        ]
    }"#;

    let response: PaginatedResponse<RecipeSummary> = serde_json::from_str(json).unwrap();
    assert_eq!(response.count, 10);
    assert!(response.next.is_some());
    assert!(response.previous.is_none());
    assert_eq!(response.results.len(), 1);
}

#[test]
fn test_recipe_summary_deserialization() {
    let json = r#"{
        "id": 5,
        "name": "Chicken Curry",
        "description": "A spicy dish",
        "keywords": [{"id": 1, "name": "indian"}]
    }"#;

    let summary: RecipeSummary = serde_json::from_str(json).unwrap();
    assert_eq!(summary.id, 5);
    assert_eq!(summary.name, "Chicken Curry");
}

#[test]
fn test_recipe_from_source_response_success() {
    let json = r#"{
        "error": false,
        "msg": "Recipe imported successfully",
        "recipe": {
            "name": "Scraped Recipe",
            "description": "A recipe from the web",
            "working_time": 30,
            "waiting_time": 60,
            "servings": 4,
            "steps": [],
            "keywords": []
        }
    }"#;

    let response: RecipeFromSourceResponse = serde_json::from_str(json).unwrap();
    assert!(!response.error);
    assert!(response.recipe.is_some());
    let recipe = response.recipe.unwrap();
    assert_eq!(recipe.name, "Scraped Recipe");
}

#[test]
fn test_recipe_from_source_response_error() {
    let json = r#"{
        "error": true,
        "msg": "Failed to parse recipe",
        "recipe": null
    }"#;

    let response: RecipeFromSourceResponse = serde_json::from_str(json).unwrap();
    assert!(response.error);
    assert!(response.recipe.is_none());
    assert!(response.msg.contains("Failed"));
}
