//! FatSecret SDK Library
//!
//! This library provides a type-safe Rust client for the FatSecret API.
//! Organized into modules: core (OAuth, HTTP), diary (food entries), foods (search).

// Re-export the fatsecret module
pub mod fatsecret;

// Re-export commonly used types for convenience
pub use fatsecret::core::{FatSecretConfig, FatSecretError, AccessToken};
pub use fatsecret::core::http::{make_api_request, make_authenticated_request, make_oauth_request};
pub use fatsecret::core::errors::parse_error_response;

// Diary types (commonly used by lambdas)
pub use fatsecret::diary::{FoodEntry, FoodEntryId, FoodEntryInput, MealType};

// Foods types
pub use fatsecret::foods::{FoodSearchResponse, FoodSearchResult};
