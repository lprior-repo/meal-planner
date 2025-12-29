//! FatSecret Domain Types for Rust
//!
//! This module contains Rust ports of FatSecret API domain types.
//! Ported from Gleam implementation in src/meal_planner/fatsecret/.
//!
//! ## Domain Modules
//!
//! - `diary` - Food diary entries and summaries
//! - `exercise` - Exercise entries and summaries
//! - `favorites` - Favorite foods and recipes
//! - `foods` - Food search and details
//! - `profile` - User profile management
//! - `recipes` - Recipe search and details
//! - `saved_meals` - Saved meal templates
//! - `weight` - Weight tracking and history

// Core module (config, errors)
pub mod core;

// Support modules
pub mod crypto;
pub mod storage;

// Domain type modules
pub mod diary;
pub mod exercise;
pub mod favorites;
pub mod foods;
pub mod profile;
pub mod recipes;
pub mod saved_meals;
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
pub use crypto::{CryptoError, decrypt, encrypt, encryption_configured, generate_key, StorageError, TokenValidity};

// Re-export OAuth types
pub use core::{AccessToken, RequestToken};

// Re-export storage
pub use storage::TokenStorage;
