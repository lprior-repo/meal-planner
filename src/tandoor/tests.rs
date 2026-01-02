//! Unit tests for Tandoor API types
//!
//! Test coverage:
//! - TandoorConfig creation and serialization
//! - Request/response type serialization
//! - TandoorError classification
//! - Type validation
//!
//! # TDD Principles Applied (Kent Beck Style)
//!
//! - **Parameterized tests**: Using rstest for table-driven tests
//! - **Pretty assertions**: Better diff output for failures
//! - **Focused tests**: One concept per test

#![allow(clippy::unwrap_used)]
#![allow(clippy::expect_used)]
#![allow(clippy::panic)]

use super::client::TandoorError;
use super::types::*;
use pretty_assertions::assert_eq;
use rstest::rstest;

// =============================================================================
// TandoorConfig Tests
// =============================================================================

#[test]
fn test_config_creation() {
    let config = TandoorConfig {
        base_url: "http://localhost:8090".to_string(),
        api_token: "test-token".to_string(),
    };

    assert_eq!(config.base_url, "http://localhost:8090");
    assert_eq!(config.api_token, "test-token");
}

#[test]
fn test_config_serialization_roundtrip() {
    let config = TandoorConfig {
        base_url: "http://localhost:8090".to_string(),
        api_token: "secret-token".to_string(),
    };

    let json = serde_json::to_string(&config).expect("should serialize");
    let deserialized: TandoorConfig = serde_json::from_str(&json).expect("should deserialize");

    assert_eq!(config.base_url, deserialized.base_url);
    assert_eq!(config.api_token, deserialized.api_token);
}

#[test]
fn test_config_from_env_missing() {
    // Clear environment variables to test missing case
    std::env::remove_var("TANDOOR_BASE_URL");
    std::env::remove_var("TANDOOR_API_TOKEN");

    let config = TandoorConfig::from_env();
    assert!(config.is_none());
}

// =============================================================================
// PaginatedResponse Tests
// =============================================================================

#[test]
fn test_paginated_response_deserialize() {
    let json = r#"{
        "count": 100,
        "next": "http://example.com/api/recipe/?page=2",
        "previous": null,
        "results": [
            {"id": 1, "name": "Recipe 1"},
            {"id": 2, "name": "Recipe 2"}
        ]
    }"#;

    let response: PaginatedResponse<RecipeSummary> =
        serde_json::from_str(json).expect("should deserialize");

    assert_eq!(response.count, 100);
    assert_eq!(
        response.next,
        Some("http://example.com/api/recipe/?page=2".to_string())
    );
    assert_eq!(response.previous, None);
    assert_eq!(response.results.len(), 2);
}

#[test]
fn test_paginated_response_empty() {
    let json = r#"{
        "count": 0,
        "next": null,
        "previous": null,
        "results": []
    }"#;

    let response: PaginatedResponse<RecipeSummary> =
        serde_json::from_str(json).expect("should deserialize");

    assert_eq!(response.count, 0);
    assert!(response.results.is_empty());
}

// =============================================================================
// RecipeSummary Tests
// =============================================================================

#[test]
fn test_recipe_summary_minimal() {
    let json = r#"{
        "id": 42,
        "name": "Scrambled Eggs"
    }"#;

    let recipe: RecipeSummary = serde_json::from_str(json).expect("should deserialize");

    assert_eq!(recipe.id, 42);
    assert_eq!(recipe.name, "Scrambled Eggs");
    assert_eq!(recipe.description, None);
    assert_eq!(recipe.working_time, None);
    assert_eq!(recipe.servings, None);
}

#[test]
fn test_recipe_summary_full() {
    let json = r#"{
        "id": 42,
        "name": "Scrambled Eggs",
        "description": "Quick breakfast",
        "working_time": 10,
        "waiting_time": 0,
        "servings": 2,
        "rating": 4.5,
        "keywords": [
            {"id": 1, "label": "breakfast"},
            {"id": 2, "label": "quick"}
        ]
    }"#;

    let recipe: RecipeSummary = serde_json::from_str(json).expect("should deserialize");

    assert_eq!(recipe.id, 42);
    assert_eq!(recipe.name, "Scrambled Eggs");
    assert_eq!(recipe.description, Some("Quick breakfast".to_string()));
    assert_eq!(recipe.working_time, Some(10));
    assert_eq!(recipe.servings, Some(2));
    assert_eq!(recipe.rating, Some(4.5));

    let keywords = recipe.keywords.expect("should have keywords");
    assert_eq!(keywords.len(), 2);
    assert_eq!(
        keywords.first().and_then(|k| k.label.clone()),
        Some("breakfast".to_string())
    );
}

// =============================================================================
// Keyword Tests
// =============================================================================

#[rstest]
#[case::with_name_and_label(
    r#"{"id": 1, "name": "dinner", "label": "Dinner"}"#,
    1,
    Some("dinner"),
    Some("Dinner")
)]
#[case::with_only_label(r#"{"id": 2, "label": "Lunch"}"#, 2, None, Some("Lunch"))]
#[case::with_only_name(r#"{"id": 3, "name": "breakfast"}"#, 3, Some("breakfast"), None)]
fn test_keyword_deserialization(
    #[case] json: &str,
    #[case] expected_id: i64,
    #[case] expected_name: Option<&str>,
    #[case] expected_label: Option<&str>,
) {
    let keyword: Keyword = serde_json::from_str(json).expect("should deserialize");

    assert_eq!(keyword.id, expected_id);
    assert_eq!(keyword.name.as_deref(), expected_name);
    assert_eq!(keyword.label.as_deref(), expected_label);
}

// =============================================================================
// CreateRecipeRequest Tests
// =============================================================================

#[test]
fn test_create_recipe_request_minimal() {
    let request = CreateRecipeRequest {
        name: "Test Recipe".to_string(),
        description: None,
        source_url: None,
        servings: None,
        working_time: None,
        waiting_time: None,
        keywords: None,
        steps: None,
    };

    let json = serde_json::to_string(&request).expect("should serialize");

    // Minimal request should only have name
    assert!(json.contains(r#""name":"Test Recipe""#));
    // Optional fields should be omitted
    assert!(!json.contains("description"));
    assert!(!json.contains("servings"));
    assert!(!json.contains("steps"));
}

#[test]
fn test_create_recipe_request_with_steps() {
    let request = CreateRecipeRequest {
        name: "Pasta".to_string(),
        description: Some("Delicious pasta".to_string()),
        source_url: None,
        servings: Some(4),
        working_time: Some(30),
        waiting_time: Some(10),
        keywords: Some(vec![CreateKeywordRequest {
            name: "italian".to_string(),
        }]),
        steps: Some(vec![CreateStepRequest {
            instruction: "Boil water".to_string(),
            ingredients: Some(vec![CreateIngredientRequest {
                amount: Some(500.0),
                food: CreateFoodRequest {
                    name: "pasta".to_string(),
                },
                unit: Some(CreateUnitRequest {
                    name: "g".to_string(),
                }),
                note: None,
            }]),
        }]),
    };

    let json = serde_json::to_string(&request).expect("should serialize");

    assert!(json.contains(r#""name":"Pasta""#));
    assert!(json.contains(r#""servings":4"#));
    assert!(json.contains(r#""instruction":"Boil water""#));
    assert!(json.contains(r#""amount":500.0"#));
    assert!(json.contains(r#""food":{"name":"pasta"}"#));
}

// =============================================================================
// RecipeFromSourceRequest Tests
// =============================================================================

#[test]
fn test_recipe_from_source_request_url() {
    let request = RecipeFromSourceRequest {
        url: Some("https://example.com/recipe".to_string()),
        data: None,
        bookmarklet: None,
    };

    let json = serde_json::to_string(&request).expect("should serialize");

    assert!(json.contains("https://example.com/recipe"));
    assert!(!json.contains("data"));
    assert!(!json.contains("bookmarklet"));
}

// =============================================================================
// SourceImportRecipe Tests
// =============================================================================

#[test]
fn test_source_import_recipe_defaults() {
    let json = r#"{
        "name": "Test Recipe"
    }"#;

    let recipe: SourceImportRecipe = serde_json::from_str(json).expect("should deserialize");

    assert_eq!(recipe.name, "Test Recipe");
    // Default values should be applied
    assert_eq!(recipe.description, "");
    assert_eq!(recipe.servings, 1); // default_servings()
    assert_eq!(recipe.working_time, 0);
    assert_eq!(recipe.waiting_time, 0);
    assert!(recipe.steps.is_empty());
    assert!(recipe.keywords.is_empty());
}

#[test]
fn test_source_import_recipe_full() {
    let json = r#"{
        "name": "Complex Recipe",
        "description": "A detailed description",
        "source_url": "https://example.com/recipe",
        "image": "https://example.com/image.jpg",
        "servings": 6,
        "servings_text": "6 people",
        "working_time": 45,
        "waiting_time": 30,
        "internal": false,
        "steps": [
            {
                "instruction": "Mix ingredients",
                "ingredients": [
                    {
                        "amount": 2.5,
                        "food": {"name": "flour"},
                        "unit": {"name": "cups"},
                        "note": "sifted",
                        "original_text": "2 1/2 cups flour, sifted"
                    }
                ],
                "show_ingredients_table": true
            }
        ],
        "keywords": [
            {"id": 1, "label": "Baking", "name": "baking"}
        ]
    }"#;

    let recipe: SourceImportRecipe = serde_json::from_str(json).expect("should deserialize");

    assert_eq!(recipe.name, "Complex Recipe");
    assert_eq!(recipe.servings, 6);
    assert_eq!(recipe.working_time, 45);
    assert_eq!(recipe.steps.len(), 1);
    let first_step = recipe.steps.first().expect("should have first step");
    assert_eq!(first_step.instruction, "Mix ingredients");
    assert_eq!(first_step.ingredients.len(), 1);
    let first_ingredient = first_step
        .ingredients
        .first()
        .expect("should have first ingredient");
    assert_eq!(first_ingredient.amount, Some(2.5));
    assert_eq!(first_ingredient.food.as_ref().unwrap().name, "flour");
}

// =============================================================================
// RecipeImportResult Tests
// =============================================================================

#[test]
fn test_recipe_import_result_success() {
    let result = RecipeImportResult {
        success: true,
        recipe_id: Some(123),
        recipe_name: Some("Imported Recipe".to_string()),
        source_url: "https://example.com".to_string(),
        message: "Successfully imported".to_string(),
    };

    let json = serde_json::to_string(&result).expect("should serialize");

    assert!(json.contains(r#""success":true"#));
    assert!(json.contains(r#""recipe_id":123"#));
    assert!(json.contains(r#""recipe_name":"Imported Recipe""#));
}

#[test]
fn test_recipe_import_result_failure() {
    let result = RecipeImportResult {
        success: false,
        recipe_id: None,
        recipe_name: None,
        source_url: "https://example.com".to_string(),
        message: "Failed to scrape".to_string(),
    };

    let json = serde_json::to_string(&result).expect("should serialize");

    assert!(json.contains(r#""success":false"#));
    assert!(json.contains(r#""recipe_id":null"#));
    assert!(json.contains(r#""message":"Failed to scrape""#));
}

// =============================================================================
// TandoorError Tests
// =============================================================================

#[test]
fn test_tandoor_error_display() {
    let auth_error = TandoorError::AuthError("Invalid token".to_string());
    assert_eq!(
        auth_error.to_string(),
        "Authentication failed: Invalid token"
    );

    let api_error = TandoorError::ApiError {
        status: 404,
        message: "Not found".to_string(),
    };
    assert_eq!(api_error.to_string(), "API error (404): Not found");

    let parse_error = TandoorError::ParseError("Invalid JSON".to_string());
    assert_eq!(
        parse_error.to_string(),
        "Failed to parse response: Invalid JSON"
    );

    let size_error = TandoorError::RequestTooLarge {
        size: 15_000_000,
        limit: 10_000_000,
    };
    assert!(size_error.to_string().contains("15000000 bytes"));
}

// =============================================================================
// ConnectionTestResult Tests
// =============================================================================

#[test]
fn test_connection_test_result_serialize() {
    let result = ConnectionTestResult {
        success: true,
        message: "Connected successfully".to_string(),
        recipe_count: 42,
    };

    let json = serde_json::to_string(&result).expect("should serialize");

    assert!(json.contains(r#""success":true"#));
    assert!(json.contains(r#""recipe_count":42"#));
}

// =============================================================================
// MealPlanSummary Tests
// =============================================================================

#[test]
fn test_meal_plan_summary_deserialize() {
    let json = r#"{
        "id": 1,
        "recipe_name": "Breakfast",
        "meal_type_name": "Breakfast",
        "from_date": "2024-01-01",
        "to_date": "2024-01-01",
        "servings": 2.0,
        "shopping": true
    }"#;

    let summary: MealPlanSummary = serde_json::from_str(json).expect("should deserialize");

    assert_eq!(summary.id, 1);
    assert_eq!(summary.recipe_name, "Breakfast");
    assert_eq!(summary.from_date, "2024-01-01");
    assert!((summary.servings - 2.0).abs() < f64::EPSILON);
    assert!(summary.shopping);
}

#[test]
fn test_meal_plan_summary_default_shopping() {
    let json = r#"{
        "id": 1,
        "recipe_name": "Dinner",
        "meal_type_name": "Dinner",
        "from_date": "2024-01-01",
        "to_date": "2024-01-01",
        "servings": 4.0
    }"#;

    let summary: MealPlanSummary = serde_json::from_str(json).expect("should deserialize");

    // shopping should default to false
    assert!(!summary.shopping);
}

// =============================================================================
// Parameterized Tests for API Response Parsing
// =============================================================================

/// Test various HTTP status codes and their error mappings
#[rstest]
#[case::unauthorized(401, "Unauthorized")]
#[case::forbidden(403, "Forbidden")]
#[case::not_found(404, "Not Found")]
#[case::server_error(500, "Internal Server Error")]
fn test_api_error_status_codes(#[case] status: u16, #[case] message: &str) {
    let error = TandoorError::ApiError {
        status,
        message: message.to_string(),
    };

    let display = error.to_string();
    assert!(
        display.contains(&status.to_string()),
        "Error display should contain status code"
    );
    assert!(
        display.contains(message),
        "Error display should contain message"
    );
}

/// Test ingredient amount parsing with various numeric formats
#[rstest]
#[case::integer_amount(r#"{"amount": 2, "food": {"name": "eggs"}}"#, Some(2.0))]
#[case::float_amount(r#"{"amount": 1.5, "food": {"name": "cups"}}"#, Some(1.5))]
#[case::null_amount(r#"{"amount": null, "food": {"name": "salt"}}"#, None)]
#[case::missing_amount(r#"{"food": {"name": "pepper"}}"#, None)]
fn test_ingredient_amount_parsing(#[case] json: &str, #[case] expected_amount: Option<f64>) {
    let ingredient: SourceImportIngredient =
        serde_json::from_str(json).expect("should deserialize");

    match (ingredient.amount, expected_amount) {
        (Some(actual), Some(expected)) => {
            assert!(
                (actual - expected).abs() < f64::EPSILON,
                "Amount mismatch: got {}, expected {}",
                actual,
                expected
            );
        }
        (None, None) => {} // Both None, test passes
        (actual, expected) => {
            panic!("Amount mismatch: got {:?}, expected {:?}", actual, expected);
        }
    }
}
