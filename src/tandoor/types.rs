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

impl TandoorConfig {
    /// Create TandoorConfig from environment variables
    /// Looks for `TANDOOR_BASE_URL` and `TANDOOR_API_TOKEN`
    pub fn from_env() -> Option<Self> {
        let base_url = std::env::var("TANDOOR_BASE_URL").ok()?;
        let api_token = std::env::var("TANDOOR_API_TOKEN").ok()?;
        Some(TandoorConfig {
            base_url,
            api_token,
        })
    }
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
/// Note: In recipe list responses, keywords only have `id` and `label`.
/// In keyword list responses, they have full details including `name`.
#[derive(Debug, Deserialize, Serialize)]
pub struct Keyword {
    /// Keyword ID
    pub id: i64,
    /// Keyword name (full keyword list responses)
    #[serde(default)]
    pub name: Option<String>,
    /// Keyword label (always present in recipe list responses)
    #[serde(default)]
    pub label: Option<String>,
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
#[derive(Debug, Deserialize, Serialize, Clone)]
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
#[derive(Debug, Deserialize, Serialize, Clone)]
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
#[derive(Debug, Deserialize, Serialize, Clone)]
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
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct SourceImportFood {
    /// Food name
    pub name: String,
}

/// Unit reference for import
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct SourceImportUnit {
    /// Unit name
    pub name: String,
}

/// Keyword for import
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct SourceImportKeyword {
    /// Keyword ID (if existing)
    pub id: Option<i64>,
    /// Display label
    pub label: Option<String>,
    /// Keyword name
    pub name: String,
}

/// Duplicate recipe info
#[derive(Debug, Deserialize, Serialize, Clone)]
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

/// Keyword update request
#[derive(Debug, Serialize)]
pub struct UpdateKeywordRequest {
    /// Keyword name (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
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

// ============================================================================
// Meal Plan Types (for /api/meal-plan/)
// ============================================================================

/// Meal plan summary (list view)
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct MealPlanSummary {
    /// Meal plan ID
    pub id: i64,
    /// Recipe name
    pub recipe_name: String,
    /// Meal type name
    pub meal_type_name: String,
    /// Date from
    pub from_date: String,
    /// Date to
    pub to_date: String,
    /// Number of servings
    pub servings: f64,
    /// Whether added to shopping
    #[serde(default)]
    pub shopping: bool,
}

/// Full meal plan response
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct MealPlan {
    /// Meal plan ID
    pub id: i64,
    /// Title
    #[serde(default)]
    pub title: String,
    /// Recipe details
    pub recipe: serde_json::Value,
    /// Number of servings
    pub servings: f64,
    /// Note
    #[serde(default)]
    pub note: String,
    /// Note in markdown format
    #[serde(default)]
    pub note_markdown: String,
    /// Date from (ISO datetime)
    pub from_date: String,
    /// Date to (ISO datetime)
    pub to_date: String,
    /// Meal type details
    pub meal_type: serde_json::Value,
    /// User ID who created this
    pub created_by: i64,
    /// Shared with users
    #[serde(default)]
    pub shared: Vec<i64>,
    /// Recipe name
    pub recipe_name: String,
    /// Meal type name
    pub meal_type_name: String,
    /// Whether added to shopping
    #[serde(default)]
    pub shopping: bool,
}

/// Paginated meal plan response with timestamp
#[derive(Debug, Deserialize)]
pub struct PaginatedMealPlanResponse {
    /// Total number of items
    pub count: i64,
    /// URL for next page (if any)
    pub next: Option<String>,
    /// URL for previous page (if any)
    pub previous: Option<String>,
    /// Server timestamp
    #[serde(default)]
    pub timestamp: Option<String>,
    /// Items on this page
    pub results: Vec<MealPlan>,
}

/// Request to create a meal plan
#[derive(Debug, Serialize)]
pub struct CreateMealPlanRequest {
    /// Recipe ID
    pub recipe: i64,
    /// Meal type ID
    pub meal_type: i64,
    /// Start date (ISO date string)
    pub from_date: String,
    /// End date (ISO date string, optional - defaults to from_date)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub to_date: Option<String>,
    /// Number of servings
    pub servings: f64,
    /// Title (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,
    /// Note (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
}

/// Request to update a meal plan
#[derive(Debug, Serialize)]
pub struct UpdateMealPlanRequest {
    /// Recipe ID (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub recipe: Option<i64>,
    /// Meal type ID (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub meal_type: Option<i64>,
    /// Start date (ISO date string, optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub from_date: Option<String>,
    /// End date (ISO date string, optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub to_date: Option<String>,
    /// Number of servings (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub servings: Option<f64>,
    /// Title (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,
    /// Note (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub note: Option<String>,
}

// ============================================================================
// Meal Type Types (for /api/meal-type/)
// ============================================================================

/// Meal type (breakfast, lunch, dinner, etc.)
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct MealType {
    pub id: i64,
    pub name: String,
    #[serde(default)]
    pub order: i32,
    #[serde(default)]
    pub time: Option<String>,
    #[serde(default)]
    pub color: Option<String>,
    #[serde(default)]
    pub default: bool,
    #[serde(default)]
    pub created_by: Option<i64>,
}

/// Request to create a meal type
#[derive(Debug, Serialize)]
pub struct CreateMealTypeRequest {
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub order: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub time: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub color: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub default: Option<bool>,
}

/// Request to update a meal type
#[derive(Debug, Serialize)]
pub struct UpdateMealTypeRequest {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub order: Option<i32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub time: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub color: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub default: Option<bool>,
}

// ============================================================================
// Recipe Book Types (for /api/recipe-book/)
// ============================================================================

/// Recipe book (collection of recipes)
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct RecipeBook {
    pub id: i64,
    pub name: String,
    #[serde(default)]
    pub description: String,
    #[serde(default)]
    pub icon: String,
    #[serde(default)]
    pub color: String,
    #[serde(default)]
    pub filter: Option<serde_json::Value>,
}

/// Request to create a recipe book
#[derive(Debug, Serialize)]
pub struct CreateRecipeBookRequest {
    pub name: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub icon: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub color: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub filter: Option<serde_json::Value>,
}

/// Request to update a recipe book
#[derive(Debug, Serialize)]
pub struct UpdateRecipeBookRequest {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub icon: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub color: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub filter: Option<serde_json::Value>,
}

// ============================================================================
// Recipe Book Entry Types (for /api/recipe-book-entry/)
// ============================================================================

/// Recipe book entry (recipe in a book)
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct RecipeBookEntry {
    pub id: i64,
    pub recipe_book: i64,
    pub recipe: i64,
    #[serde(default)]
    pub recipe_name: String,
    #[serde(default)]
    pub position: i32,
}

/// Request to create a recipe book entry
#[derive(Debug, Serialize)]
pub struct CreateRecipeBookEntryRequest {
    pub recipe_book: i64,
    pub recipe: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub position: Option<i32>,
}

/// Request to update a recipe book entry
#[derive(Debug, Serialize)]
pub struct UpdateRecipeBookEntryRequest {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub recipe_book: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub recipe: Option<i64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub position: Option<i32>,
}

// ============================================================================
// Batch Recipe Update Types
// ============================================================================

/// Request to batch update recipes
#[derive(Debug, Serialize, Deserialize)]
pub struct BatchUpdateRecipeRequest {
    /// Recipe ID
    pub id: i64,
    /// Updated name (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    /// Updated description (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    /// Updated servings (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub servings: Option<i32>,
    /// Updated working time in minutes (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub working_time: Option<i32>,
    /// Updated waiting time in minutes (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub waiting_time: Option<i32>,
}

/// Response from batch updating recipes
#[derive(Debug, Serialize, Deserialize)]
pub struct BatchUpdateRecipeResponse {
    /// Number of recipes updated
    pub updated_count: i64,
    /// IDs of updated recipes
    pub updated_ids: Vec<i64>,
}

// ============================================================================
// Related Recipes Types
// ============================================================================

/// Response for related recipes
#[derive(Debug, Serialize, Deserialize)]
pub struct RelatedRecipesResponse {
    /// List of related recipes
    pub results: Vec<RecipeSummary>,
}

// ============================================================================
// Shopping List Types (for /api/meal-plan/{id}/shopping/)
// ============================================================================

/// Shopping list entry (ingredient on shopping list)
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct ShoppingListEntry {
    /// Entry ID
    pub id: i64,
    /// Shopping list ID
    pub list: i64,
    /// Ingredient ID (if linked to recipe ingredient)
    pub ingredient: Option<i64>,
    /// Unit of measurement
    pub unit: Option<String>,
    /// Quantity amount
    pub amount: Option<f64>,
    /// Food name
    pub food: Option<String>,
    /// Whether item is checked off
    pub checked: bool,
    /// Display order
    pub order: Option<i32>,
}

/// Request to create a shopping list entry
#[derive(Debug, Serialize, Deserialize)]
pub struct CreateShoppingListEntryRequest {
    /// Shopping list ID
    pub list: i64,
    /// Ingredient ID (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ingredient: Option<i64>,
    /// Unit (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub unit: Option<String>,
    /// Quantity (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub amount: Option<f64>,
    /// Food name (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub food: Option<String>,
    /// Whether checked (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub checked: Option<bool>,
    /// Display order (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub order: Option<i32>,
}

/// Request to update a shopping list entry
#[derive(Debug, Serialize, Deserialize)]
pub struct UpdateShoppingListEntryRequest {
    /// Shopping list ID (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub list: Option<i64>,
    /// Ingredient ID (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ingredient: Option<i64>,
    /// Unit (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub unit: Option<String>,
    /// Quantity (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub amount: Option<f64>,
    /// Food name (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub food: Option<String>,
    /// Whether checked (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub checked: Option<bool>,
    /// Display order (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub order: Option<i32>,
}

/// Shopping list recipe (recipe entry in shopping list)
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct ShoppingListRecipe {
    /// ID
    pub id: i64,
    /// Meal plan ID
    pub mealplan: i64,
    /// Recipe ID
    pub recipe: i64,
    /// Recipe name
    pub recipe_name: String,
    /// Shopping list ID
    pub list: i64,
    /// Number of servings
    pub servings: f64,
    /// Entries in this recipe's shopping list
    #[serde(default)]
    pub entries: Vec<ShoppingListEntry>,
}

/// Bulk request for shopping list entries
#[derive(Debug, Serialize, Deserialize)]
pub struct BulkShoppingListEntryRequest {
    /// Array of entries to create/update
    pub entries: Vec<CreateShoppingListEntryRequest>,
}

/// Response for bulk shopping list operation
#[derive(Debug, Serialize, Deserialize)]
pub struct BulkShoppingListEntryResponse {
    /// Number of entries created/updated
    pub created_count: i64,
    /// IDs of created entries
    pub created_ids: Vec<i64>,
}

// ============================================================================
// Unit Types (for /api/unit/)
// ============================================================================

/// Unit of measurement
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Unit {
    /// Unit ID
    pub id: i64,
    /// Unit name (e.g., "kg", "cup", "tbsp")
    pub name: String,
    /// Plural form (optional)
    #[serde(default)]
    pub plural_name: Option<String>,
}

/// Request to create a unit
#[derive(Debug, Serialize)]
pub struct CreateUnitRequestData {
    /// Unit name
    pub name: String,
    /// Plural form (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub plural_name: Option<String>,
}

/// Request to update a unit
#[derive(Debug, Serialize)]
pub struct UpdateUnitRequest {
    /// Unit name (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    /// Plural form (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub plural_name: Option<String>,
}

/// Unit conversion - full response from API
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct UnitConversion {
    /// Conversion ID
    pub id: i64,
    /// Conversion name/description
    #[serde(default)]
    pub name: Option<String>,
    /// Base amount
    #[serde(default)]
    pub base_amount: Option<f64>,
    /// Base unit (full object)
    #[serde(default)]
    pub base_unit: Option<serde_json::Value>,
    /// Converted amount
    #[serde(default)]
    pub converted_amount: Option<f64>,
    /// Converted unit (full object)
    #[serde(default)]
    pub converted_unit: Option<serde_json::Value>,
    /// Food (full object, optional)
    #[serde(default)]
    pub food: Option<serde_json::Value>,
    /// Created by user ID
    #[serde(default)]
    pub created_by: Option<i64>,
    /// Open data slug
    #[serde(default)]
    pub open_data_slug: Option<String>,
}

// ============================================================================
// Ingredient Types (for /api/ingredient/)
// ============================================================================

/// Food ingredient (foods in recipes)
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Food {
    /// Food ID
    pub id: i64,
    /// Food name
    pub name: String,
    /// Food description
    #[serde(default)]
    pub description: Option<String>,
}

/// Request to create a food
#[derive(Debug, Serialize)]
pub struct CreateFoodRequestData {
    /// Food name
    pub name: String,
    /// Food description (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
}

/// Request to update a food
#[derive(Debug, Serialize)]
pub struct UpdateFoodRequest {
    /// Food name (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    /// Food description (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
}

/// Ingredient (food + unit in a recipe) - full response from API
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Ingredient {
    /// Ingredient ID
    pub id: i64,
    /// Food object (full data from API)
    pub food: serde_json::Value,
    /// Unit object (optional, full data from API)
    #[serde(default)]
    pub unit: Option<serde_json::Value>,
    /// Amount (optional)
    #[serde(default)]
    pub amount: Option<f64>,
    /// Note (optional)
    #[serde(default)]
    pub note: Option<String>,
    /// Order in step
    #[serde(default)]
    pub order: Option<i32>,
    /// Is this a section header
    #[serde(default)]
    pub is_header: Option<bool>,
    /// No amount flag
    #[serde(default)]
    pub no_amount: Option<bool>,
    /// Original text from import
    #[serde(default)]
    pub original_text: Option<String>,
    /// Always use plural food name
    #[serde(default)]
    pub always_use_plural_food: Option<bool>,
    /// Always use plural unit name
    #[serde(default)]
    pub always_use_plural_unit: Option<bool>,
    /// Unit conversions
    #[serde(default)]
    pub conversions: Option<Vec<serde_json::Value>>,
    /// Recipes using this ingredient
    #[serde(default)]
    pub used_in_recipes: Option<Vec<serde_json::Value>>,
}

/// Request to create an ingredient
#[derive(Debug, Serialize)]
pub struct CreateIngredientRequestData {
    /// Food ID
    pub food: i64,
    /// Unit ID (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub unit: Option<i64>,
    /// Amount (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub amount: Option<f64>,
}

/// Request to update an ingredient
#[derive(Debug, Serialize)]
pub struct UpdateIngredientRequest {
    /// Food ID (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub food: Option<i64>,
    /// Unit ID (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub unit: Option<i64>,
    /// Amount (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub amount: Option<f64>,
}

/// Request to parse ingredient from text
#[derive(Debug, Serialize)]
pub struct IngredientFromStringRequest {
    /// Ingredient text to parse (e.g., "2 cups flour")
    pub text: String,
}

/// Parsed ingredient from text - API response
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct ParsedIngredient {
    /// Parsed amount
    #[serde(default)]
    pub amount: Option<f64>,
    /// Parsed unit (object with name and id)
    #[serde(default)]
    pub unit: Option<serde_json::Value>,
    /// Parsed food (object with name and id)
    #[serde(default)]
    pub food: Option<serde_json::Value>,
    /// Note text
    #[serde(default)]
    pub note: Option<String>,
    /// Original text that was parsed
    #[serde(default)]
    pub original_text: Option<String>,
}

// ============================================================================
// Step Types (for /api/step/)
// ============================================================================

/// Recipe step
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Step {
    /// Step ID
    pub id: i64,
    /// Step instructions
    pub instruction: String,
    /// Recipe ID this step belongs to
    #[serde(default)]
    pub recipe: Option<i64>,
    /// Step order
    #[serde(default)]
    pub order: Option<i32>,
}

/// Request to create a step
#[derive(Debug, Serialize)]
pub struct CreateStepRequestData {
    /// Step instructions
    pub instruction: String,
    /// Recipe ID
    #[serde(skip_serializing_if = "Option::is_none")]
    pub recipe: Option<i64>,
    /// Step order
    #[serde(skip_serializing_if = "Option::is_none")]
    pub order: Option<i32>,
}

/// Request to update a step
#[derive(Debug, Serialize)]
pub struct UpdateStepRequest {
    /// Step instructions
    #[serde(skip_serializing_if = "Option::is_none")]
    pub instruction: Option<String>,
    /// Recipe ID
    #[serde(skip_serializing_if = "Option::is_none")]
    pub recipe: Option<i64>,
    /// Step order
    #[serde(skip_serializing_if = "Option::is_none")]
    pub order: Option<i32>,
}

// ============================================================================
// Space Types (for /api/space/)
// ============================================================================

/// User workspace/space
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Space {
    /// Space ID
    pub id: i64,
    /// Space name
    pub name: String,
    /// Space description
    #[serde(default)]
    pub description: Option<String>,
    /// Space creation date
    #[serde(default)]
    pub created_at: Option<String>,
}

/// Request to create a space
#[derive(Debug, Serialize)]
pub struct CreateSpaceRequest {
    /// Space name
    pub name: String,
    /// Space description
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
}

/// Request to update a space
#[derive(Debug, Serialize)]
pub struct UpdateSpaceRequest {
    /// Space name
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    /// Space description
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
}

// ============================================================================
// User Types (for /api/user/)
// ============================================================================

/// User profile
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct User {
    /// User ID
    pub id: i64,
    /// Username
    pub username: String,
    /// User's email
    #[serde(default)]
    pub email: Option<String>,
    /// User's first name
    #[serde(default)]
    pub first_name: Option<String>,
    /// User's last name
    #[serde(default)]
    pub last_name: Option<String>,
    /// User creation date
    #[serde(default)]
    pub date_joined: Option<String>,
    /// Last login date
    #[serde(default)]
    pub last_login: Option<String>,
    /// User's profile image URL
    #[serde(default)]
    pub profile_picture: Option<String>,
}

// ============================================================================
// Food Batch Update Types (for /api/food/batch_update/)
// ============================================================================

/// Request to batch update foods
#[derive(Debug, Serialize, Deserialize)]
pub struct BatchUpdateFoodRequest {
    /// Food ID
    pub id: i64,
    /// Updated name (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    /// Updated description (optional)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
}

/// Response from batch updating foods
#[derive(Debug, Serialize, Deserialize)]
pub struct BatchUpdateFoodResponse {
    /// Number of foods updated
    pub updated_count: i64,
    /// IDs of updated foods
    pub updated_ids: Vec<i64>,
}

// ============================================================================
// Supermarket Types (for /api/supermarket/)
// ============================================================================

/// Supermarket/store
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Supermarket {
    /// Supermarket ID
    pub id: i64,
    /// Supermarket name
    pub name: String,
    /// Supermarket description
    #[serde(default)]
    pub description: Option<String>,
}

/// Request to create a supermarket
#[derive(Debug, Serialize)]
pub struct CreateSupermarketRequest {
    /// Supermarket name
    pub name: String,
    /// Supermarket description
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
}

/// Request to update a supermarket
#[derive(Debug, Serialize)]
pub struct UpdateSupermarketRequest {
    /// Supermarket name
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    /// Supermarket description
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
}

// ============================================================================
// Recipe Image Types (for /api/recipe/{id}/image/)
// ============================================================================

/// Response from uploading a recipe image
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct RecipeImage {
    /// Image URL (returned after upload)
    pub image: Option<String>,
    /// External image URL
    pub image_url: Option<String>,
}

// ============================================================================
// AI Import Types (for /api/ai-import/)
// ============================================================================

/// Response from AI import (same as recipe from source)
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct AiImportResponse {
    /// Recipe data
    #[serde(alias = "recipe_json")]
    pub recipe: Option<SourceImportRecipe>,
    /// Recipe ID if an existing recipe was updated
    pub recipe_id: Option<i64>,
    /// Images from the imported file
    #[serde(default)]
    pub images: Vec<String>,
    /// Whether an error occurred
    #[serde(default)]
    pub error: bool,
    /// Error or status message
    #[serde(default)]
    pub msg: String,
    /// Duplicate recipes found
    #[serde(default)]
    pub duplicates: Vec<SourceImportDuplicate>,
}

// ============================================================================
// Property Types (for /api/property-type/ and /api/property/)
// ============================================================================

/// Property type category
#[derive(Debug, Deserialize, Serialize, Clone, PartialEq, Eq)]
#[serde(rename_all = "UPPERCASE")]
pub enum PropertyCategory {
    Nutrition,
    Allergen,
    Goal,
    Price,
    Other,
}

/// Property type definition (e.g., "Calories", "Protein", "Fat")
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct PropertyType {
    /// Property type ID
    pub id: Option<i64>,
    /// Property name (required)
    pub name: String,
    /// Unit of measurement (e.g., "kcal", "g")
    #[serde(default)]
    pub unit: Option<String>,
    /// Description
    #[serde(default)]
    pub description: Option<String>,
    /// Display order
    #[serde(default)]
    pub order: i32,
    /// Open data slug for external data sources
    #[serde(default)]
    pub open_data_slug: Option<String>,
    /// FDA FoodData Central ID
    #[serde(default)]
    pub fdc_id: Option<i64>,
    /// Category (nutrition, allergen, etc.)
    #[serde(default)]
    pub category: Option<PropertyCategory>,
}

/// Request to create a property type
#[derive(Debug, Serialize)]
pub struct CreatePropertyTypeRequest {
    /// Property name (required)
    pub name: String,
    /// Unit of measurement
    #[serde(skip_serializing_if = "Option::is_none")]
    pub unit: Option<String>,
    /// Description
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    /// Display order
    #[serde(skip_serializing_if = "Option::is_none")]
    pub order: Option<i32>,
    /// Category
    #[serde(skip_serializing_if = "Option::is_none")]
    pub category: Option<PropertyCategory>,
}

/// Request to update a property type
#[derive(Debug, Serialize)]
pub struct UpdatePropertyTypeRequest {
    /// Property name
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    /// Unit of measurement
    #[serde(skip_serializing_if = "Option::is_none")]
    pub unit: Option<String>,
    /// Description
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    /// Display order
    #[serde(skip_serializing_if = "Option::is_none")]
    pub order: Option<i32>,
    /// Category
    #[serde(skip_serializing_if = "Option::is_none")]
    pub category: Option<PropertyCategory>,
}

/// Property value (links a property type to a food/recipe with an amount)
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Property {
    /// Property ID
    pub id: Option<i64>,
    /// Amount value
    pub property_amount: Option<f64>,
    /// Property type definition
    pub property_type: PropertyType,
}

/// Request to create a property
#[derive(Debug, Serialize)]
pub struct CreatePropertyRequest {
    /// Amount value
    pub property_amount: f64,
    /// Property type ID or full type
    pub property_type: i64,
}

/// Request to update a property
#[derive(Debug, Serialize)]
pub struct UpdatePropertyRequest {
    /// Amount value
    #[serde(skip_serializing_if = "Option::is_none")]
    pub property_amount: Option<f64>,
    /// Property type ID
    #[serde(skip_serializing_if = "Option::is_none")]
    pub property_type: Option<i64>,
}

#[cfg(test)]
mod tests {
    use super::*;

    // ============================================================================
    // RecipeImage Tests
    // ============================================================================

    #[test]
    fn test_recipe_image_deserialize_full() {
        let json = r#"{
            "image": "/media/recipes/123.jpg",
            "image_url": "https://example.com/recipe.jpg"
        }"#;
        let result: RecipeImage = serde_json::from_str(json).expect("Failed to deserialize");
        assert_eq!(result.image, Some("/media/recipes/123.jpg".to_string()));
        assert_eq!(
            result.image_url,
            Some("https://example.com/recipe.jpg".to_string())
        );
    }

    #[test]
    fn test_recipe_image_deserialize_partial() {
        let json = r#"{"image": "/media/recipes/456.png"}"#;
        let result: RecipeImage = serde_json::from_str(json).expect("Failed to deserialize");
        assert_eq!(result.image, Some("/media/recipes/456.png".to_string()));
        assert!(result.image_url.is_none());
    }

    #[test]
    fn test_recipe_image_deserialize_empty() {
        let json = r#"{}"#;
        let result: RecipeImage = serde_json::from_str(json).expect("Failed to deserialize");
        assert!(result.image.is_none());
        assert!(result.image_url.is_none());
    }

    #[test]
    fn test_recipe_image_deserialize_null_fields() {
        let json = r#"{"image": null, "image_url": null}"#;
        let result: RecipeImage = serde_json::from_str(json).expect("Failed to deserialize");
        assert!(result.image.is_none());
        assert!(result.image_url.is_none());
    }

    #[test]
    fn test_recipe_image_serialize() {
        let image = RecipeImage {
            image: Some("/media/recipes/789.jpg".to_string()),
            image_url: None,
        };
        let json = serde_json::to_string(&image).expect("Failed to serialize");
        assert!(json.contains("/media/recipes/789.jpg"));
    }

    #[test]
    fn test_recipe_image_clone() {
        let original = RecipeImage {
            image: Some("/media/test.jpg".to_string()),
            image_url: Some("https://example.com/test.jpg".to_string()),
        };
        let cloned = original.clone();
        assert_eq!(original.image, cloned.image);
        assert_eq!(original.image_url, cloned.image_url);
    }

    // ============================================================================
    // AiImportResponse Tests
    // ============================================================================

    #[test]
    fn test_ai_import_response_deserialize_success() {
        let json = r#"{
            "recipe": {
                "name": "Test Recipe",
                "description": "A test recipe",
                "servings": 4,
                "steps": [],
                "keywords": []
            },
            "recipe_id": 123,
            "images": ["https://example.com/img1.jpg", "https://example.com/img2.jpg"],
            "error": false,
            "msg": "Import successful",
            "duplicates": []
        }"#;
        let result: AiImportResponse =
            serde_json::from_str(json).expect("Failed to deserialize");
        assert!(result.recipe.is_some());
        assert_eq!(result.recipe.as_ref().map(|r| r.name.as_str()), Some("Test Recipe"));
        assert_eq!(result.recipe_id, Some(123));
        assert_eq!(result.images.len(), 2);
        assert!(!result.error);
        assert_eq!(result.msg, "Import successful");
        assert!(result.duplicates.is_empty());
    }

    #[test]
    fn test_ai_import_response_deserialize_error() {
        let json = r#"{
            "recipe": null,
            "error": true,
            "msg": "Failed to parse image"
        }"#;
        let result: AiImportResponse =
            serde_json::from_str(json).expect("Failed to deserialize");
        assert!(result.recipe.is_none());
        assert!(result.recipe_id.is_none());
        assert!(result.error);
        assert_eq!(result.msg, "Failed to parse image");
    }

    #[test]
    fn test_ai_import_response_deserialize_minimal() {
        let json = r#"{}"#;
        let result: AiImportResponse =
            serde_json::from_str(json).expect("Failed to deserialize");
        assert!(result.recipe.is_none());
        assert!(result.recipe_id.is_none());
        assert!(result.images.is_empty());
        assert!(!result.error);
        assert!(result.msg.is_empty());
        assert!(result.duplicates.is_empty());
    }

    #[test]
    fn test_ai_import_response_deserialize_with_alias() {
        // Test that recipe_json alias works
        let json = r#"{
            "recipe_json": {
                "name": "Aliased Recipe",
                "description": "",
                "servings": 2,
                "steps": [],
                "keywords": []
            },
            "error": false,
            "msg": ""
        }"#;
        let result: AiImportResponse =
            serde_json::from_str(json).expect("Failed to deserialize");
        assert!(result.recipe.is_some());
        assert_eq!(
            result.recipe.as_ref().map(|r| r.name.as_str()),
            Some("Aliased Recipe")
        );
    }

    #[test]
    fn test_ai_import_response_deserialize_with_duplicates() {
        let json = r#"{
            "recipe": null,
            "error": false,
            "msg": "Duplicates found",
            "duplicates": [
                {"id": 1, "name": "Existing Recipe 1"},
                {"id": 2, "name": "Existing Recipe 2"}
            ]
        }"#;
        let result: AiImportResponse =
            serde_json::from_str(json).expect("Failed to deserialize");
        assert_eq!(result.duplicates.len(), 2);
        assert_eq!(result.duplicates.first().map(|d| d.id), Some(1));
        assert_eq!(
            result.duplicates.first().map(|d| d.name.as_str()),
            Some("Existing Recipe 1")
        );
    }

    #[test]
    fn test_ai_import_response_clone() {
        let original = AiImportResponse {
            recipe: None,
            recipe_id: Some(42),
            images: vec!["test.jpg".to_string()],
            error: false,
            msg: "Test message".to_string(),
            duplicates: vec![],
        };
        let cloned = original.clone();
        assert_eq!(original.recipe_id, cloned.recipe_id);
        assert_eq!(original.images, cloned.images);
        assert_eq!(original.error, cloned.error);
        assert_eq!(original.msg, cloned.msg);
    }

    #[test]
    fn test_ai_import_response_serialize() {
        let response = AiImportResponse {
            recipe: None,
            recipe_id: Some(100),
            images: vec!["img.jpg".to_string()],
            error: false,
            msg: "OK".to_string(),
            duplicates: vec![],
        };
        let json = serde_json::to_string(&response).expect("Failed to serialize");
        assert!(json.contains("\"recipe_id\":100"));
        assert!(json.contains("\"msg\":\"OK\""));
    }
}
