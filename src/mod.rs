//! Meal Planner SDK Library
//!
//! This library provides type-safe Rust clients for meal planning APIs.
//!
//! ## Modules
//!
//! - `fatsecret` - `FatSecret` API client (nutrition tracking)
//! - `tandoor` - Tandoor Recipes API client (recipe management)

// =============================================================================
// NIGHTLY FEATURES - Maximum safety with latest Rust
// =============================================================================
// Enable stricter lints only available on nightly
#![feature(non_exhaustive_omitted_patterns_lint)]
// Enable must_not_suspend lint for async safety
#![feature(must_not_suspend)]
// Enable strict provenance lints (pointer safety)
#![feature(strict_provenance_lints)]
// =============================================================================
// CRATE-LEVEL LINTS - Additional safety beyond Cargo.toml
// =============================================================================
// Deny lossy pointer-to-integer casts (strict provenance)
#![deny(fuzzy_provenance_casts)]
#![deny(lossy_provenance_casts)]
// Warn on types that shouldn't be held across await points
#![warn(must_not_suspend)]
// =============================================================================
// TEST CODE - Allow panics in tests (that's how test failures work)
// =============================================================================
#![cfg_attr(test, allow(clippy::unwrap_used))]
#![cfg_attr(test, allow(clippy::expect_used))]
#![cfg_attr(test, allow(clippy::panic))]

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
