//! FatSecret Domain Types for Rust
//!
//! This module contains Rust ports of FatSecret API domain types.
//! Ported from the Gleam implementation in src/meal_planner/fatsecret/.
//!
//! ## Domain Modules
//!
//! - `exercise` - Exercise entries and summaries
//! - `favorites` - Favorite foods and recipes
//! - `profile` - User profile management
//! - `recipes` - Recipe search and details
//! - `saved_meals` - Saved meal templates
//! - `weight` - Weight tracking and history

// Domain type modules
pub mod exercise;
pub mod favorites;
pub mod profile;
pub mod recipes;
pub mod saved_meals;
pub mod weight;

// Re-export exercise types
pub use exercise::{
    date_to_int, int_to_date, Exercise, ExerciseDaySummary, ExerciseEntry, ExerciseEntryId,
    ExerciseEntryInput, ExerciseEntryUpdate, ExerciseId, ExerciseMonthSummary,
};

// Re-export favorites types
pub use favorites::{
    FavoriteFood, FavoriteFoodsResponse, FavoriteRecipe, FavoriteRecipesResponse, MealFilter,
    MostEatenFood, MostEatenResponse, RecentlyEatenFood, RecentlyEatenResponse,
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
    MealType, SavedMeal, SavedMealId, SavedMealItem, SavedMealItemId, SavedMealItemInput,
    SavedMealItemsResponse, SavedMealsResponse,
};

// Re-export weight types
pub use weight::{
    WeightDaySummary, WeightEntry, WeightEntryId, WeightMonthSummary, WeightUpdate,
};
