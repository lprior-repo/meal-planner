//! Meal Planner SDK Library
//!
//! This library provides type-safe Rust clients for meal planning APIs.
//!
//! ## Modules
//!
//! - `fatsecret` - FatSecret API client (nutrition tracking)
//! - `tandoor` - Tandoor Recipes API client (recipe management)

// API client modules
pub mod fatsecret;
pub mod tandoor;

// Re-export commonly used types for convenience
pub use fatsecret::core::errors::parse_error_response;
pub use fatsecret::core::http::{make_api_request, make_authenticated_request, make_oauth_request};
pub use fatsecret::core::{AccessToken, FatSecretConfig, FatSecretError};

// Diary types (commonly used by lambdas)
pub use fatsecret::diary::{FoodEntry, FoodEntryId, FoodEntryInput, MealType};

// Foods types
pub use fatsecret::foods::{FoodSearchResponse, FoodSearchResult};
