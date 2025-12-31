//! `FatSecret` Platform API - Nutrition tracking and food diary management
//!
//! This module provides comprehensive access to the `FatSecret` Platform API, enabling
//! nutrition tracking, food logging, exercise tracking, and meal planning functionality.
//! All API calls require OAuth 1.0a authentication (3-legged flow for user-specific data).
//!
//! # Purpose and Scope
//!
//! The `FatSecret` domain covers:
//! - **Food Diary**: Log meals, track daily nutrition, retrieve summaries
//! - **Food Database**: Search 500,000+ foods, get nutritional details
//! - **Exercise Tracking**: Log workouts, track calories burned
//! - **Favorites**: Manage frequently eaten foods and recipes
//! - **Recipes**: Search and retrieve cooking recipes with nutrition
//! - **Weight Tracking**: Log weight entries, view trends
//! - **Profile Management**: User authentication and profile data
//! - **Saved Meals**: Create meal templates for quick logging
//!
//! # Key Submodules
//!
//! ## Core Infrastructure
//! - [`core`] - OAuth client, HTTP utilities, error types, configuration
//! - [`crypto`] - Encryption/decryption for secure token storage
//! - [`storage`] - SQLx-based persistent OAuth token storage
//!
//! ## API Domains
//! - [`diary`] - Food diary entries and daily/monthly summaries
//! - [`foods`] - Food search, nutritional details, autocomplete
//! - [`exercise`] - Exercise entries and activity tracking
//! - [`favorites`] - Favorite foods, recipes, most/recently eaten
//! - [`recipes`] - Recipe search, details, ingredients, directions
//! - [`weight`] - Weight entries and historical tracking
//! - [`profile`] - User profile and authentication
//! - [`saved_meals`] - Meal templates for quick food logging
//!
//! # OAuth Requirements
//!
//! `FatSecret` uses **OAuth 1.0a** with a 3-legged flow for user-specific operations:
//!
//! 1. **Request Token**: Obtain temporary credentials
//! 2. **User Authorization**: User approves access via `FatSecret` web UI
//! 3. **Access Token**: Exchange verifier for long-lived credentials
//!
//! All authenticated requests require an [`AccessToken`] containing:
//! - `oauth_token` - Access token string
//! - `oauth_token_secret` - Token secret for signing requests
//!
//! ## Token Storage and Encryption
//!
//! Tokens are stored securely in `PostgreSQL` with AES-256-GCM encryption:
//!
//! - Requires `OAUTH_ENCRYPTION_KEY` environment variable (32-byte base64)
//! - Use [`TokenStorage`] for persistent token management
//! - Use [`crypto`] module for encryption/decryption primitives
//!
//! # Example Usage
//!
//! ## Basic Food Diary Workflow
//!
//! ```rust,no_run
//! use meal_planner::fatsecret::{
//!     core::{FatSecretConfig, AccessToken},
//!     diary::{get_food_entries, FoodEntryInput, MealType, create_food_entry},
//!     storage::TokenStorage,
//! };
//! use sqlx::PgPool;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! // 1. Configure API credentials
//! let config = FatSecretConfig::from_env()
//!     .ok_or("Missing FATSECRET_CONSUMER_KEY or FATSECRET_CONSUMER_SECRET")?;
//!
//! // 2. Load access token from storage
//! let db = PgPool::connect(&std::env::var("DATABASE_URL")?).await?;
//! let storage = TokenStorage::new(db);
//! let token = storage.get_access_token().await?
//!     .ok_or("No access token found - run OAuth flow first")?;
//!
//! // 3. Get today's food entries
//! let date_int = 20088; // Days since Unix epoch
//! let entries = get_food_entries(&config, &token, date_int).await?;
//! println!("Found {} entries", entries.len());
//!
//! // 4. Log a new food entry
//! let entry_input = FoodEntryInput::FromFood {
//!     food_id: "12345".to_string(),
//!     food_entry_name: "Banana".to_string(),
//!     serving_id: "67890".to_string(),
//!     number_of_units: 1.0,
//!     meal: MealType::Breakfast,
//!     date_int,
//! };
//! let entry_id = create_food_entry(&config, &token, &entry_input).await?;
//! println!("Created entry: {}", entry_id.value);
//! # Ok(())
//! # }
//! ```
//!
//! ## OAuth Flow (3-Legged)
//!
//! ```rust,no_run
//! use meal_planner::fatsecret::{
//!     core::{FatSecretConfig, oauth::{get_request_token, get_access_token}},
//!     storage::TokenStorage,
//! };
//! use sqlx::PgPool;
//!
//! # async fn oauth_example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = FatSecretConfig::from_env().unwrap();
//! let db = PgPool::connect(&std::env::var("DATABASE_URL")?).await?;
//! let storage = TokenStorage::new(db);
//!
//! // Step 1: Get request token
//! let request_token = get_request_token(&config, "oob").await?;
//! storage.store_pending_token(&request_token).await?;
//!
//! // Step 2: User authorizes (get verifier from FatSecret web UI)
//! let auth_url = format!(
//!     "https://www.fatsecret.com/oauth/authorize?oauth_token={}",
//!     request_token.oauth_token
//! );
//! println!("Visit: {}", auth_url);
//!
//! // Step 3: Exchange verifier for access token
//! let verifier = "USER_ENTERS_VERIFIER_HERE";
//! let access_token = get_access_token(&config, &request_token, verifier).await?;
//! storage.store_access_token(&access_token).await?;
//! # Ok(())
//! # }
//! ```
//!
//! ## Food Search
//!
//! ```rust,no_run
//! use meal_planner::fatsecret::{
//!     core::FatSecretConfig,
//!     foods::search_foods,
//! };
//!
//! # async fn search_example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = FatSecretConfig::from_env().unwrap();
//!
//! // Search requires only API credentials (no user token)
//! let results = search_foods(
//!     &config,
//!     "banana",
//!     None, // page_number
//!     None, // max_results
//! ).await?;
//!
//! for food in results.foods.food {
//!     println!("{}: {}", food.food_id, food.food_name);
//! }
//! # Ok(())
//! # }
//! ```
//!
//! # Binary Usage (Windmill Integration)
//!
//! This library is designed for use with Windmill workflows via small CLI binaries.
//! Each binary accepts JSON input and returns JSON output:
//!
//! ```bash
//! # Get food entries for a date
//! echo '{
//!   "access_token": "...",
//!   "access_secret": "...",
//!   "date_int": 20088
//! }' | fatsecret_food_entries_get
//!
//! # Output: {"success": true, "entries": [...]}
//! ```
//!
//! See individual binaries in `src/bin/fatsecret_*.rs` for detailed usage.
//!
//! # Error Handling
//!
//! All API calls return `Result<T, FatSecretError>` with variants:
//! - `ConfigMissing` - Missing API credentials
//! - `HttpError` - Network/HTTP failures
//! - `ParseError` - JSON deserialization failures
//! - `ApiError` - `FatSecret` API error responses (with error code)
//!
//! # Environment Variables
//!
//! - `FATSECRET_CONSUMER_KEY` - OAuth consumer key (required)
//! - `FATSECRET_CONSUMER_SECRET` - OAuth consumer secret (required)
//! - `OAUTH_ENCRYPTION_KEY` - 32-byte base64 key for token encryption (required for storage)
//! - `DATABASE_URL` - `PostgreSQL` connection string (required for token storage)
//!
//! # Further Reading
//!
//! - [FatSecret Platform API Documentation](https://platform.fatsecret.com/api/)
//! - [`diary`] module for food logging
//! - [`foods`] module for food database search
//! - [`core::oauth`] for OAuth flow details

/// Core configuration and error types for FatSecret API
pub mod core;

/// Encryption and decryption utilities for secure token storage
pub mod crypto;

/// Persistent token storage with encryption support
pub mod storage;

/// Food diary entries and daily/monthly summaries
pub mod diary;

/// Exercise entries and activity tracking
pub mod exercise;

/// Favorite foods and recipes management
pub mod favorites;

/// Food search and nutritional details from FatSecret API
pub mod foods;

/// User profile management and authentication
pub mod profile;

/// Recipe search and details
pub mod recipes;

/// Saved meal templates for quick food logging
pub mod saved_meals;

/// Weight tracking and history
pub mod weight;

// Re-export exercise types
pub use exercise::{
    date_to_int as exercise_date_to_int, int_to_date as exercise_int_to_date, Exercise,
    ExerciseDaySummary, ExerciseEntry, ExerciseEntryId, ExerciseEntryInput, ExerciseEntryUpdate,
    ExerciseId, ExerciseMonthSummary,
};

// Re-export favorites types
pub use favorites::{
    FavoriteFood, FavoriteFoodsResponse, FavoriteRecipe, FavoriteRecipesResponse, MealFilter,
    MostEatenFood, MostEatenResponse, RecentlyEatenFood, RecentlyEatenResponse,
};

// Re-export foods types
pub use foods::{
    Food, FoodAutocompleteResponse, FoodId, FoodSearchResponse, FoodSearchResult, FoodSuggestion,
    Nutrition, Serving, ServingId,
};

// Re-export profile types
pub use profile::{Profile, ProfileAuth, ProfileAuthResponse, ProfileCreateInput};

// Re-export recipes types
pub use recipes::{
    Recipe, RecipeAutocompleteResponse, RecipeDirection, RecipeId, RecipeIngredient,
    RecipeSearchResponse, RecipeSearchResult, RecipeSuggestion, RecipeType, RecipeTypesResponse,
};

// Re-export saved_meals types
pub use saved_meals::{
    MealType as SavedMealType, SavedMeal, SavedMealId, SavedMealItem, SavedMealItemId,
    SavedMealItemInput, SavedMealItemsResponse, SavedMealsResponse,
};

// Re-export weight types
pub use weight::{WeightDaySummary, WeightEntry, WeightEntryId, WeightMonthSummary, WeightUpdate};

// Re-export diary types
pub use diary::{
    date_to_int, int_to_date, map_auth_error, validate_custom_entry, validate_date_int_string,
    validate_number_of_units, AuthError, DaySummary, FoodEntry, FoodEntryId, FoodEntryInput,
    FoodEntryUpdate, MealType, MonthSummary, ValidationError,
};

// Re-export crypto types
pub use crypto::{
    decrypt, encrypt, encryption_configured, generate_key, CryptoError, StorageError, TokenValidity,
};

// Re-export OAuth types
pub use core::{AccessToken, RequestToken};

// Re-export storage
pub use storage::TokenStorage;
