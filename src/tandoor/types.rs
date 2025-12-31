//! Tandoor API Request and Response Types
//!
//! Type definitions for all Tandoor API interactions. Types are organized by API endpoint
//! and operation, with serde support for JSON serialization/deserialization.
//!
//! # Type Categories
//!
//! ## Configuration
//! - [`TandoorConfig`] - Client configuration (URL + token)
//!
//! ## Common Response Wrappers
//! - [`PaginatedResponse<T>`](PaginatedResponse) - Paginated list responses
//! - [`ConnectionTestResult`] - Connection test outcome
//! - [`TandoorErrorResponse`] - API error details
//!
//! ## Recipe Listing
//! - [`RecipeSummary`] - Recipe metadata from `/api/recipe/` (GET)
//! - [`Keyword`] - Recipe tags/keywords
//!
//! ## Recipe Import (URL Scraping)
//! - [`RecipeFromSourceRequest`] - Request to `/api/recipe-from-source/` (POST)
//! - [`RecipeFromSourceResponse`] - Scraped recipe data
//! - [`SourceImportRecipe`] - Parsed recipe structure
//! - [`SourceImportStep`] - Recipe step with ingredients
//! - [`SourceImportIngredient`] - Ingredient with amount/unit/food
//! - [`SourceImportFood`], [`SourceImportUnit`], [`SourceImportKeyword`] - Component types
//!
//! ## Recipe Creation
//! - [`CreateRecipeRequest`] - Create recipe via `/api/recipe/` (POST)
//! - [`CreateStepRequest`] - Step in recipe creation
//! - [`CreateIngredientRequest`] - Ingredient in step
//! - [`CreateFoodRequest`], [`CreateUnitRequest`], [`CreateKeywordRequest`] - Component types
//! - [`CreatedRecipe`] - Response after creation
//!
//! ## Import Results
//! - [`RecipeImportResult`] - Combined scrape + create result
//!
//! # Usage Example
//!
//! ```rust
//! use meal_planner::tandoor::{
//!     TandoorConfig,
//!     CreateRecipeRequest,
//!     CreateStepRequest,
//!     CreateIngredientRequest,
//!     CreateFoodRequest,
//!     CreateUnitRequest,
//! };
//!
//! // Configuration
//! let config = TandoorConfig {
//!     base_url: "http://localhost:8090".to_string(),
//!     api_token: "your-token".to_string(),
//! };
//!
//! // Build a recipe creation request
//! let recipe = CreateRecipeRequest {
//!     name: "Scrambled Eggs".to_string(),
//!     description: Some("Quick breakfast".to_string()),
//!     source_url: None,
//!     servings: Some(2),
//!     working_time: Some(5),
//!     waiting_time: None,
//!     keywords: None,
//!     steps: Some(vec![
//!         CreateStepRequest {
//!             instruction: "Whisk eggs and cook in butter".to_string(),
//!             ingredients: Some(vec![
//!                 CreateIngredientRequest {
//!                     amount: Some(4.0),
//!                     food: CreateFoodRequest {
//!                         name: "eggs".to_string(),
//!                     },
//!                     unit: None,
//!                     note: None,
//!                 },
//!                 CreateIngredientRequest {
//!                     amount: Some(1.0),
//!                     food: CreateFoodRequest {
//!                         name: "butter".to_string(),
//!                     },
//!                     unit: Some(CreateUnitRequest {
//!                         name: "tbsp".to_string(),
//!                     }),
//!                     note: None,
//!                 },
//!             ]),
//!         }
//!     ]),
//! };
//!
//! // Serialize to JSON for API request
//! let json = serde_json::to_string(&recipe).unwrap();
//! assert!(json.contains("Scrambled Eggs"));
//! ```
//!
//! # Field Conventions
//!
//! - **Times**: All durations are in minutes (`working_time`, `waiting_time`)
//! - **Amounts**: Ingredient quantities use `f64` for precision
//! - **Optional fields**: Use `#[serde(skip_serializing_if = "Option::is_none")]` to omit nulls
//! - **Defaults**: Import types use `#[serde(default)]` for missing fields
//!
//! # API Endpoint Mapping
//!
//! | Endpoint | Request Type | Response Type |
//! |----------|--------------|---------------|
//! | `GET /api/recipe/` | N/A | `PaginatedResponse<RecipeSummary>` |
//! | `POST /api/recipe/` | `CreateRecipeRequest` | `CreatedRecipe` |
//! | `POST /api/recipe-from-source/` | `RecipeFromSourceRequest` | `RecipeFromSourceResponse` |

use serde::{Deserialize, Serialize};

/// Configuration for Tandoor API client
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct TandoorConfig {
    /// Base URL of the Tandoor instance (e.g., `<http://localhost:8080>`)
    pub base_url: String,
    /// API token for authentication
    pub api_token: String,
}

/// Paginated response wrapper
#[derive(Debug, Deserialize)]
pub struct PaginatedResponse<T> {
    /// Total number of items
    pub count: i64,
    /// URL for next page (if any)
    pub next: Option<String>,
    /// URL for previous page (if any)
    pub previous: Option<String>,
    /// Items on this page
    pub results: Vec<T>,
}

/// Recipe summary (list view)
#[derive(Debug, Deserialize, Serialize)]
pub struct RecipeSummary {
    /// Recipe ID
    pub id: i64,
    /// Recipe name
    pub name: String,
    /// Recipe description
    pub description: Option<String>,
    /// Keywords/tags
    pub keywords: Option<Vec<Keyword>>,
    /// Active cooking time in minutes
    pub working_time: Option<i32>,
    /// Passive time (marinating, resting) in minutes
    pub waiting_time: Option<i32>,
    /// User rating
    pub rating: Option<f64>,
    /// Number of servings
    pub servings: Option<i32>,
}

/// Keyword/tag
#[derive(Debug, Deserialize, Serialize)]
pub struct Keyword {
    /// Keyword ID
    pub id: i64,
    /// Keyword name
    pub name: String,
}

/// Test connection result
#[derive(Debug, Serialize)]
pub struct ConnectionTestResult {
    /// Whether connection succeeded
    pub success: bool,
    /// Status message
    pub message: String,
    /// Number of recipes found
    pub recipe_count: i64,
}

/// Error response from Tandoor
#[derive(Debug, Deserialize)]
pub struct TandoorErrorResponse {
    /// Error detail message
    pub detail: Option<String>,
    /// Error message
    pub error: Option<String>,
}

// ============================================================================
// Recipe Import Types (for /api/recipe-from-source/)
// ============================================================================

/// Request to import a recipe from a URL
#[derive(Debug, Serialize)]
pub struct RecipeFromSourceRequest {
    /// URL to scrape recipe from
    #[serde(skip_serializing_if = "Option::is_none")]
    pub url: Option<String>,
    /// Raw recipe data (alternative to URL)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<String>,
    /// Bookmarklet ID (alternative to URL)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub bookmarklet: Option<i64>,
}

/// Response from recipe import
#[derive(Debug, Deserialize, Serialize)]
pub struct RecipeFromSourceResponse {
    /// Recipe data (API returns "recipe", aliased from legacy "`recipe_json`")
    #[serde(alias = "recipe_json")]
    pub recipe: Option<SourceImportRecipe>,
    /// Recipe tree structure
    pub recipe_tree: Option<serde_json::Value>,
    /// Images from the scraped page
    #[serde(alias = "recipe_images")]
    pub images: Option<Vec<String>>,
    /// Whether an error occurred
    #[serde(default)]
    pub error: bool,
    /// Error or status message
    #[serde(default)]
    pub msg: String,
}

/// Imported recipe structure
#[derive(Debug, Deserialize, Serialize)]
pub struct SourceImportRecipe {
    /// Recipe name
    pub name: String,
    /// Recipe description
    #[serde(default)]
    pub description: String,
    /// Original source URL
    pub source_url: Option<String>,
    /// Image URL
    pub image: Option<String>,
    /// Number of servings
    #[serde(default = "default_servings")]
    pub servings: i32,
    /// Servings text (e.g., "4 people")
    #[serde(default)]
    pub servings_text: String,
    /// Active cooking time in minutes
    #[serde(default)]
    pub working_time: i32,
    /// Passive time in minutes
    #[serde(default)]
    pub waiting_time: i32,
    /// Whether recipe is internal
    #[serde(default)]
    pub internal: bool,
    /// Recipe steps
    #[serde(default)]
    pub steps: Vec<SourceImportStep>,
    /// Keywords/tags
    #[serde(default)]
    pub keywords: Vec<SourceImportKeyword>,
}

/// Default servings value
fn default_servings() -> i32 {
    1
}

/// Import step
#[derive(Debug, Deserialize, Serialize)]
pub struct SourceImportStep {
    /// Step instructions
    pub instruction: String,
    /// Ingredients for this step
    #[serde(default)]
    pub ingredients: Vec<SourceImportIngredient>,
    /// Whether to show ingredients table
    #[serde(default = "default_true")]
    pub show_ingredients_table: bool,
}

/// Default true value
fn default_true() -> bool {
    true
}

/// Import ingredient
#[derive(Debug, Deserialize, Serialize)]
pub struct SourceImportIngredient {
    /// Quantity amount
    pub amount: Option<f64>,
    /// Food item
    pub food: Option<SourceImportFood>,
    /// Unit of measurement
    pub unit: Option<SourceImportUnit>,
    /// Additional notes
    #[serde(default)]
    pub note: String,
    /// Original text from scraping
    #[serde(default)]
    pub original_text: String,
}

/// Food reference for import
#[derive(Debug, Deserialize, Serialize)]
pub struct SourceImportFood {
    /// Food name
    pub name: String,
}

/// Unit reference for import
#[derive(Debug, Deserialize, Serialize)]
pub struct SourceImportUnit {
    /// Unit name
    pub name: String,
}

/// Keyword for import
#[derive(Debug, Deserialize, Serialize)]
pub struct SourceImportKeyword {
    /// Keyword ID (if existing)
    pub id: Option<i64>,
    /// Display label
    pub label: Option<String>,
    /// Keyword name
    pub name: String,
}

/// Duplicate recipe info
#[derive(Debug, Deserialize, Serialize)]
pub struct SourceImportDuplicate {
    /// Recipe ID
    pub id: i64,
    /// Recipe name
    pub name: String,
}

/// Request to create a recipe from imported data
#[derive(Debug, Serialize)]
pub struct CreateRecipeRequest {
    /// Recipe name
    pub name: String,
    /// Recipe description
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    /// Source URL
    #[serde(skip_serializing_if = "Option::is_none")]
    pub source_url: Option<String>,
    /// Number of servings
    #[serde(skip_serializing_if = "Option::is_none")]
    pub servings: Option<i32>,
    /// Active cooking time in minutes
    #[serde(skip_serializing_if = "Option::is_none")]
    pub working_time: Option<i32>,
    /// Passive time in minutes
    #[serde(skip_serializing_if = "Option::is_none")]
    pub waiting_time: Option<i32>,
    /// Keywords/tags to add
    #[serde(skip_serializing_if = "Option::is_none")]
    pub keywords: Option<Vec<CreateKeywordRequest>>,
    /// Recipe steps
    #[serde(skip_serializing_if = "Option::is_none")]
    pub steps: Option<Vec<CreateStepRequest>>,
}

/// Keyword creation request
#[derive(Debug, Serialize)]
pub struct CreateKeywordRequest {
    /// Keyword name
    pub name: String,
}

/// Step creation request
#[derive(Debug, Serialize)]
pub struct CreateStepRequest {
    /// Step instructions
    pub instruction: String,
    /// Ingredients for this step
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ingredients: Option<Vec<CreateIngredientRequest>>,
}

/// Ingredient creation request
#[derive(Debug, Serialize)]
pub struct CreateIngredientRequest {
    /// Quantity amount
    #[serde(skip_serializing_if = "Option::is_none")]
    pub amount: Option<f64>,
    /// Food item
    pub food: CreateFoodRequest,
    /// Unit of measurement
    #[serde(skip_serializing_if = "Option::is_none")]
    pub unit: Option<CreateUnitRequest>,
    /// Additional notes
    #[serde(skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
}

/// Food creation request
#[derive(Debug, Serialize)]
pub struct CreateFoodRequest {
    /// Food name
    pub name: String,
}

/// Unit creation request
#[derive(Debug, Serialize)]
pub struct CreateUnitRequest {
    /// Unit name
    pub name: String,
}

/// Created recipe response
#[derive(Debug, Deserialize)]
pub struct CreatedRecipe {
    /// Recipe ID
    pub id: i64,
    /// Recipe name
    pub name: String,
}

/// Import result combining scrape and creation
#[derive(Debug, Serialize)]
pub struct RecipeImportResult {
    /// Whether the import succeeded
    pub success: bool,
    /// ID of the created recipe (if successful)
    pub recipe_id: Option<i64>,
    /// Name of the created recipe (if successful)
    pub recipe_name: Option<String>,
    /// Original URL that was imported
    pub source_url: String,
    /// Status message or error description
    pub message: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    // ============================================================================
    // TandoorConfig tests
    // ============================================================================

    #[test]
    fn test_tandoor_config() {
        let config = TandoorConfig {
            base_url: "http://localhost:8080".to_string(),
            api_token: "my_token".to_string(),
        };
        assert_eq!(config.base_url, "http://localhost:8080");
        assert_eq!(config.api_token, "my_token");
    }

    #[test]
    fn test_tandoor_config_clone() {
        let config = TandoorConfig {
            base_url: "http://example.com".to_string(),
            api_token: "token123".to_string(),
        };
        let cloned = config.clone();
        assert_eq!(config.base_url, cloned.base_url);
        assert_eq!(config.api_token, cloned.api_token);
    }

    #[test]
    fn test_tandoor_config_serde() {
        let config = TandoorConfig {
            base_url: "http://localhost".to_string(),
            api_token: "secret".to_string(),
        };
        let json = serde_json::to_string(&config).unwrap();
        assert!(json.contains("http://localhost"));
        let parsed: TandoorConfig = serde_json::from_str(&json).unwrap();
        assert_eq!(config.base_url, parsed.base_url);
    }

    // ============================================================================
    // PaginatedResponse tests
    // ============================================================================

    #[test]
    fn test_paginated_response_deserialize() {
        let json = r#"{
            "count": 100,
            "next": "http://example.com/page=2",
            "previous": null,
            "results": [{"id": 1, "name": "Test"}]
        }"#;
        let response: PaginatedResponse<RecipeSummary> = serde_json::from_str(json).unwrap();
        assert_eq!(response.count, 100);
        assert!(response.next.is_some());
        assert!(response.previous.is_none());
        assert_eq!(response.results.len(), 1);
    }

    #[test]
    fn test_paginated_response_empty() {
        let json = r#"{
            "count": 0,
            "next": null,
            "previous": null,
            "results": []
        }"#;
        let response: PaginatedResponse<RecipeSummary> = serde_json::from_str(json).unwrap();
        assert_eq!(response.count, 0);
        assert!(response.results.is_empty());
    }

    // ============================================================================
    // RecipeSummary tests
    // ============================================================================

    #[test]
    fn test_recipe_summary_minimal() {
        let json = r#"{
            "id": 42,
            "name": "Simple Recipe"
        }"#;
        let summary: RecipeSummary = serde_json::from_str(json).unwrap();
        assert_eq!(summary.id, 42);
        assert_eq!(summary.name, "Simple Recipe");
        assert!(summary.description.is_none());
        assert!(summary.keywords.is_none());
    }

    #[test]
    fn test_recipe_summary_full() {
        let json = r#"{
            "id": 1,
            "name": "Full Recipe",
            "description": "A complete recipe",
            "keywords": [{"id": 1, "name": "dinner"}, {"id": 2, "name": "quick"}],
            "working_time": 30,
            "waiting_time": 60,
            "rating": 4.5,
            "servings": 4
        }"#;
        let summary: RecipeSummary = serde_json::from_str(json).unwrap();
        assert_eq!(summary.id, 1);
        assert_eq!(summary.description, Some("A complete recipe".to_string()));
        assert_eq!(summary.keywords.as_ref().unwrap().len(), 2);
        assert_eq!(summary.working_time, Some(30));
        assert_eq!(summary.rating, Some(4.5));
        assert_eq!(summary.servings, Some(4));
    }

    // ============================================================================
    // Keyword tests
    // ============================================================================

    #[test]
    fn test_keyword_deserialize() {
        let json = r#"{"id": 5, "name": "vegetarian"}"#;
        let keyword: Keyword = serde_json::from_str(json).unwrap();
        assert_eq!(keyword.id, 5);
        assert_eq!(keyword.name, "vegetarian");
    }

    // ============================================================================
    // ConnectionTestResult tests
    // ============================================================================

    #[test]
    fn test_connection_test_result_success() {
        let result = ConnectionTestResult {
            success: true,
            message: "Connected successfully".to_string(),
            recipe_count: 42,
        };
        assert!(result.success);
        assert_eq!(result.recipe_count, 42);
    }

    #[test]
    fn test_connection_test_result_serialize() {
        let result = ConnectionTestResult {
            success: true,
            message: "OK".to_string(),
            recipe_count: 10,
        };
        let json = serde_json::to_string(&result).unwrap();
        assert!(json.contains("true"));
        assert!(json.contains("10"));
    }

    // ============================================================================
    // TandoorErrorResponse tests
    // ============================================================================

    #[test]
    fn test_error_response_detail() {
        let json = r#"{"detail": "Not found"}"#;
        let error: TandoorErrorResponse = serde_json::from_str(json).unwrap();
        assert_eq!(error.detail, Some("Not found".to_string()));
        assert!(error.error.is_none());
    }

    #[test]
    fn test_error_response_error() {
        let json = r#"{"error": "Invalid request"}"#;
        let error: TandoorErrorResponse = serde_json::from_str(json).unwrap();
        assert!(error.detail.is_none());
        assert_eq!(error.error, Some("Invalid request".to_string()));
    }

    // ============================================================================
    // RecipeFromSourceRequest tests
    // ============================================================================

    #[test]
    fn test_recipe_from_source_request_url() {
        let request = RecipeFromSourceRequest {
            url: Some("https://example.com/recipe".to_string()),
            data: None,
            bookmarklet: None,
        };
        let json = serde_json::to_string(&request).unwrap();
        assert!(json.contains("https://example.com/recipe"));
        assert!(!json.contains("data"));
        assert!(!json.contains("bookmarklet"));
    }

    #[test]
    fn test_recipe_from_source_request_data() {
        let request = RecipeFromSourceRequest {
            url: None,
            data: Some("raw recipe data".to_string()),
            bookmarklet: None,
        };
        let json = serde_json::to_string(&request).unwrap();
        assert!(json.contains("raw recipe data"));
    }

    // ============================================================================
    // RecipeFromSourceResponse tests
    // ============================================================================

    #[test]
    fn test_recipe_from_source_response_success() {
        let json = r#"{
            "recipe": {
                "name": "Test Recipe",
                "description": "A test",
                "servings": 4,
                "working_time": 30,
                "waiting_time": 0,
                "steps": [],
                "keywords": []
            },
            "error": false,
            "msg": "Success"
        }"#;
        let response: RecipeFromSourceResponse = serde_json::from_str(json).unwrap();
        assert!(!response.error);
        assert!(response.recipe.is_some());
        assert_eq!(response.recipe.as_ref().unwrap().name, "Test Recipe");
    }

    #[test]
    fn test_recipe_from_source_response_error() {
        let json = r#"{
            "recipe": null,
            "error": true,
            "msg": "Failed to parse"
        }"#;
        let response: RecipeFromSourceResponse = serde_json::from_str(json).unwrap();
        assert!(response.error);
        assert!(response.recipe.is_none());
        assert_eq!(response.msg, "Failed to parse");
    }

    #[test]
    fn test_recipe_from_source_response_with_images() {
        let json = r#"{
            "recipe": null,
            "images": ["img1.jpg", "img2.jpg"],
            "error": false,
            "msg": ""
        }"#;
        let response: RecipeFromSourceResponse = serde_json::from_str(json).unwrap();
        assert_eq!(response.images.as_ref().unwrap().len(), 2);
    }

    // ============================================================================
    // SourceImportRecipe tests
    // ============================================================================

    #[test]
    fn test_source_import_recipe_minimal() {
        let json = r#"{
            "name": "Minimal Recipe"
        }"#;
        let recipe: SourceImportRecipe = serde_json::from_str(json).unwrap();
        assert_eq!(recipe.name, "Minimal Recipe");
        assert_eq!(recipe.servings, 1); // default
        assert_eq!(recipe.working_time, 0); // default
        assert!(recipe.steps.is_empty()); // default
    }

    #[test]
    fn test_source_import_recipe_full() {
        let json = r#"{
            "name": "Full Recipe",
            "description": "A complete imported recipe",
            "source_url": "https://example.com",
            "image": "https://example.com/img.jpg",
            "servings": 4,
            "servings_text": "4 servings",
            "working_time": 30,
            "waiting_time": 60,
            "internal": true,
            "steps": [
                {
                    "instruction": "Step 1",
                    "ingredients": [],
                    "show_ingredients_table": true
                }
            ],
            "keywords": [
                {"id": null, "label": null, "name": "dinner"}
            ]
        }"#;
        let recipe: SourceImportRecipe = serde_json::from_str(json).unwrap();
        assert_eq!(recipe.servings, 4);
        assert_eq!(recipe.working_time, 30);
        assert!(recipe.internal);
        assert_eq!(recipe.steps.len(), 1);
        assert_eq!(recipe.keywords.len(), 1);
    }

    // ============================================================================
    // SourceImportStep tests
    // ============================================================================

    #[test]
    fn test_source_import_step() {
        let json = r#"{
            "instruction": "Mix all ingredients",
            "ingredients": [
                {
                    "amount": 2.0,
                    "food": {"name": "eggs"},
                    "unit": null,
                    "note": ""
                }
            ],
            "show_ingredients_table": true
        }"#;
        let step: SourceImportStep = serde_json::from_str(json).unwrap();
        assert_eq!(step.instruction, "Mix all ingredients");
        assert_eq!(step.ingredients.len(), 1);
        assert!(step.show_ingredients_table);
    }

    #[test]
    fn test_source_import_step_defaults() {
        let json = r#"{
            "instruction": "Simple step"
        }"#;
        let step: SourceImportStep = serde_json::from_str(json).unwrap();
        assert!(step.ingredients.is_empty());
        assert!(step.show_ingredients_table); // default true
    }

    // ============================================================================
    // SourceImportIngredient tests
    // ============================================================================

    #[test]
    fn test_source_import_ingredient_full() {
        let json = r#"{
            "amount": 2.5,
            "food": {"name": "flour"},
            "unit": {"name": "cups"},
            "note": "sifted",
            "original_text": "2.5 cups sifted flour"
        }"#;
        let ingredient: SourceImportIngredient = serde_json::from_str(json).unwrap();
        assert_eq!(ingredient.amount, Some(2.5));
        assert_eq!(ingredient.food.as_ref().unwrap().name, "flour");
        assert_eq!(ingredient.unit.as_ref().unwrap().name, "cups");
        assert_eq!(ingredient.note, "sifted");
    }

    #[test]
    fn test_source_import_ingredient_minimal() {
        let json = r#"{
            "food": {"name": "salt"}
        }"#;
        let ingredient: SourceImportIngredient = serde_json::from_str(json).unwrap();
        assert!(ingredient.amount.is_none());
        assert!(ingredient.unit.is_none());
        assert_eq!(ingredient.note, ""); // default
    }

    // ============================================================================
    // SourceImportKeyword tests
    // ============================================================================

    #[test]
    fn test_source_import_keyword_new() {
        let json = r#"{
            "id": null,
            "label": null,
            "name": "quick"
        }"#;
        let keyword: SourceImportKeyword = serde_json::from_str(json).unwrap();
        assert!(keyword.id.is_none());
        assert_eq!(keyword.name, "quick");
    }

    #[test]
    fn test_source_import_keyword_existing() {
        let json = r#"{
            "id": 42,
            "label": "Quick Meals",
            "name": "quick"
        }"#;
        let keyword: SourceImportKeyword = serde_json::from_str(json).unwrap();
        assert_eq!(keyword.id, Some(42));
        assert_eq!(keyword.label, Some("Quick Meals".to_string()));
    }

    // ============================================================================
    // CreateRecipeRequest tests
    // ============================================================================

    #[test]
    fn test_create_recipe_request_minimal() {
        let request = CreateRecipeRequest {
            name: "Simple".to_string(),
            description: None,
            source_url: None,
            servings: None,
            working_time: None,
            waiting_time: None,
            keywords: None,
            steps: None,
        };
        let json = serde_json::to_string(&request).unwrap();
        assert!(json.contains("Simple"));
        assert!(!json.contains("description"));
        assert!(!json.contains("servings"));
    }

    #[test]
    fn test_create_recipe_request_full() {
        let request = CreateRecipeRequest {
            name: "Full Recipe".to_string(),
            description: Some("Description".to_string()),
            source_url: Some("https://example.com".to_string()),
            servings: Some(4),
            working_time: Some(30),
            waiting_time: Some(60),
            keywords: Some(vec![CreateKeywordRequest { name: "dinner".to_string() }]),
            steps: Some(vec![CreateStepRequest {
                instruction: "Cook it".to_string(),
                ingredients: None,
            }]),
        };
        let json = serde_json::to_string(&request).unwrap();
        assert!(json.contains("Full Recipe"));
        assert!(json.contains("dinner"));
        assert!(json.contains("Cook it"));
    }

    // ============================================================================
    // CreateStepRequest tests
    // ============================================================================

    #[test]
    fn test_create_step_request_minimal() {
        let step = CreateStepRequest {
            instruction: "Do something".to_string(),
            ingredients: None,
        };
        let json = serde_json::to_string(&step).unwrap();
        assert!(json.contains("Do something"));
        assert!(!json.contains("ingredients"));
    }

    #[test]
    fn test_create_step_request_with_ingredients() {
        let step = CreateStepRequest {
            instruction: "Mix".to_string(),
            ingredients: Some(vec![CreateIngredientRequest {
                amount: Some(2.0),
                food: CreateFoodRequest { name: "eggs".to_string() },
                unit: None,
                note: None,
            }]),
        };
        let json = serde_json::to_string(&step).unwrap();
        assert!(json.contains("eggs"));
        assert!(json.contains("2.0"));
    }

    // ============================================================================
    // CreateIngredientRequest tests
    // ============================================================================

    #[test]
    fn test_create_ingredient_request_minimal() {
        let ingredient = CreateIngredientRequest {
            amount: None,
            food: CreateFoodRequest { name: "salt".to_string() },
            unit: None,
            note: None,
        };
        let json = serde_json::to_string(&ingredient).unwrap();
        assert!(json.contains("salt"));
        assert!(!json.contains("amount"));
        assert!(!json.contains("unit"));
    }

    #[test]
    fn test_create_ingredient_request_full() {
        let ingredient = CreateIngredientRequest {
            amount: Some(1.5),
            food: CreateFoodRequest { name: "butter".to_string() },
            unit: Some(CreateUnitRequest { name: "tbsp".to_string() }),
            note: Some("softened".to_string()),
        };
        let json = serde_json::to_string(&ingredient).unwrap();
        assert!(json.contains("butter"));
        assert!(json.contains("tbsp"));
        assert!(json.contains("softened"));
    }

    // ============================================================================
    // CreatedRecipe tests
    // ============================================================================

    #[test]
    fn test_created_recipe_deserialize() {
        let json = r#"{"id": 123, "name": "New Recipe"}"#;
        let created: CreatedRecipe = serde_json::from_str(json).unwrap();
        assert_eq!(created.id, 123);
        assert_eq!(created.name, "New Recipe");
    }

    // ============================================================================
    // RecipeImportResult tests
    // ============================================================================

    #[test]
    fn test_recipe_import_result_success() {
        let result = RecipeImportResult {
            success: true,
            recipe_id: Some(42),
            recipe_name: Some("Imported Recipe".to_string()),
            source_url: "https://example.com".to_string(),
            message: "Success".to_string(),
        };
        assert!(result.success);
        assert_eq!(result.recipe_id, Some(42));
    }

    #[test]
    fn test_recipe_import_result_failure() {
        let result = RecipeImportResult {
            success: false,
            recipe_id: None,
            recipe_name: None,
            source_url: "https://bad.com".to_string(),
            message: "Failed to scrape".to_string(),
        };
        assert!(!result.success);
        assert!(result.recipe_id.is_none());
    }

    #[test]
    fn test_recipe_import_result_serialize() {
        let result = RecipeImportResult {
            success: true,
            recipe_id: Some(1),
            recipe_name: Some("Test".to_string()),
            source_url: "https://test.com".to_string(),
            message: "OK".to_string(),
        };
        let json = serde_json::to_string(&result).unwrap();
        assert!(json.contains("true"));
        assert!(json.contains("https://test.com"));
    }

    // ============================================================================
    // Default function tests
    // ============================================================================

    #[test]
    fn test_default_servings() {
        assert_eq!(default_servings(), 1);
    }

    #[test]
    fn test_default_true() {
        assert!(default_true());
    }

    // ============================================================================
    // SourceImportDuplicate tests
    // ============================================================================

    #[test]
    fn test_source_import_duplicate() {
        let json = r#"{"id": 5, "name": "Duplicate Recipe"}"#;
        let dup: SourceImportDuplicate = serde_json::from_str(json).unwrap();
        assert_eq!(dup.id, 5);
        assert_eq!(dup.name, "Duplicate Recipe");
    }

    #[test]
    fn test_source_import_duplicate_serialize() {
        let dup = SourceImportDuplicate {
            id: 10,
            name: "Test".to_string(),
        };
        let json = serde_json::to_string(&dup).unwrap();
        assert!(json.contains("10"));
        assert!(json.contains("Test"));
    }
}
