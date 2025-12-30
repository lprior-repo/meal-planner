//! Tandoor API types

use serde::{Deserialize, Serialize};

/// Configuration for Tandoor API client
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct TandoorConfig {
    pub base_url: String,
    pub api_token: String,
}

/// Paginated response wrapper
#[derive(Debug, Deserialize)]
pub struct PaginatedResponse<T> {
    pub count: i64,
    pub next: Option<String>,
    pub previous: Option<String>,
    pub results: Vec<T>,
}

/// Recipe summary (list view)
#[derive(Debug, Deserialize, Serialize)]
pub struct RecipeSummary {
    pub id: i64,
    pub name: String,
    pub description: Option<String>,
    pub keywords: Option<Vec<Keyword>>,
    pub working_time: Option<i32>,
    pub waiting_time: Option<i32>,
    pub rating: Option<f64>,
    pub servings: Option<i32>,
}

/// Keyword/tag
#[derive(Debug, Deserialize, Serialize)]
pub struct Keyword {
    pub id: i64,
    pub name: String,
}

/// Test connection result
#[derive(Debug, Serialize)]
pub struct ConnectionTestResult {
    pub success: bool,
    pub message: String,
    pub recipe_count: i64,
}

/// Error response from Tandoor
#[derive(Debug, Deserialize)]
pub struct TandoorErrorResponse {
    pub detail: Option<String>,
    pub error: Option<String>,
}

// ============================================================================
// Recipe Import Types (for /api/recipe-from-source/)
// ============================================================================

/// Request to import a recipe from a URL
#[derive(Debug, Serialize)]
pub struct RecipeFromSourceRequest {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub bookmarklet: Option<i64>,
}

/// Response from recipe import
#[derive(Debug, Deserialize, Serialize)]
pub struct RecipeFromSourceResponse {
    pub recipe_json: Option<SourceImportRecipe>,
    pub recipe_tree: Option<serde_json::Value>,
    pub recipe_images: Option<Vec<String>>,
    #[serde(default)]
    pub error: bool,
    #[serde(default)]
    pub msg: String,
}

/// Imported recipe structure
#[derive(Debug, Deserialize, Serialize)]
pub struct SourceImportRecipe {
    pub name: String,
    #[serde(default)]
    pub description: String,
    pub source_url: Option<String>,
    pub image: Option<String>,
    #[serde(default = "default_servings")]
    pub servings: i32,
    #[serde(default)]
    pub servings_text: String,
    #[serde(default)]
    pub working_time: i32,
    #[serde(default)]
    pub waiting_time: i32,
    #[serde(default)]
    pub internal: bool,
    #[serde(default)]
    pub steps: Vec<SourceImportStep>,
    #[serde(default)]
    pub keywords: Vec<SourceImportKeyword>,
}

fn default_servings() -> i32 {
    1
}

/// Import step
#[derive(Debug, Deserialize, Serialize)]
pub struct SourceImportStep {
    pub instruction: String,
    #[serde(default)]
    pub ingredients: Vec<SourceImportIngredient>,
    #[serde(default = "default_true")]
    pub show_ingredients_table: bool,
}

fn default_true() -> bool {
    true
}

/// Import ingredient
#[derive(Debug, Deserialize, Serialize)]
pub struct SourceImportIngredient {
    pub amount: Option<f64>,
    pub food: Option<SourceImportFood>,
    pub unit: Option<SourceImportUnit>,
    #[serde(default)]
    pub note: String,
    #[serde(default)]
    pub original_text: String,
}

/// Food reference for import
#[derive(Debug, Deserialize, Serialize)]
pub struct SourceImportFood {
    pub name: String,
}

/// Unit reference for import
#[derive(Debug, Deserialize, Serialize)]
pub struct SourceImportUnit {
    pub name: String,
}

/// Keyword for import
#[derive(Debug, Deserialize, Serialize)]
pub struct SourceImportKeyword {
    pub id: Option<i64>,
    pub label: Option<String>,
    pub name: String,
}

/// Duplicate recipe info
#[derive(Debug, Deserialize, Serialize)]
pub struct SourceImportDuplicate {
    pub id: i64,
    pub name: String,
}

/// Request to create a recipe from imported data
#[derive(Debug, Serialize)]
pub struct CreateRecipeRequest {
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub source_url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub servings: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub working_time: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub waiting_time: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub keywords: Option<Vec<CreateKeywordRequest>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub steps: Option<Vec<CreateStepRequest>>,
}

/// Keyword creation request
#[derive(Debug, Serialize)]
pub struct CreateKeywordRequest {
    pub name: String,
}

/// Step creation request
#[derive(Debug, Serialize)]
pub struct CreateStepRequest {
    pub instruction: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ingredients: Option<Vec<CreateIngredientRequest>>,
}

/// Ingredient creation request
#[derive(Debug, Serialize)]
pub struct CreateIngredientRequest {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub amount: Option<f64>,
    pub food: CreateFoodRequest,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub unit: Option<CreateUnitRequest>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
}

/// Food creation request
#[derive(Debug, Serialize)]
pub struct CreateFoodRequest {
    pub name: String,
}

/// Unit creation request
#[derive(Debug, Serialize)]
pub struct CreateUnitRequest {
    pub name: String,
}

/// Created recipe response
#[derive(Debug, Deserialize)]
pub struct CreatedRecipe {
    pub id: i64,
    pub name: String,
}

/// Import result combining scrape and creation
#[derive(Debug, Serialize)]
pub struct RecipeImportResult {
    pub success: bool,
    pub recipe_id: Option<i64>,
    pub recipe_name: Option<String>,
    pub source_url: String,
    pub message: String,
}
