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
