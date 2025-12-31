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

/// Unit conversion
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct UnitConversion {
    /// Conversion ID
    pub id: i64,
    /// From unit ID
    pub from_unit: i64,
    /// To unit ID
    pub to_unit: i64,
    /// Conversion factor
    pub factor: f64,
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

/// Ingredient (food + unit in a recipe)
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Ingredient {
    /// Ingredient ID
    pub id: i64,
    /// Food ID
    pub food: i64,
    /// Unit ID (optional)
    pub unit: Option<i64>,
    /// Amount (optional)
    pub amount: Option<f64>,
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

/// Parsed ingredient from text
#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct ParsedIngredient {
    /// Parsed amount
    pub amount: Option<f64>,
    /// Parsed unit
    pub unit: Option<String>,
    /// Parsed food name
    pub food: Option<String>,
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
