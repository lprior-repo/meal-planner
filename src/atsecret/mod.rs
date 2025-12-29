//! FatSecret module
//!
//! Provides access to FatSecret SDK.

pub mod config;
pub mod diary;
pub mod errors;
pub mod http;
pub mod oauth;
pub mod serde_utils;

pub use config::FatSecretConfig;
pub use errors::{parse_error_response, ApiErrorCode, FatSecretError};
pub use http::{make_api_request, make_authenticated_request, make_oauth_request};
pub use oauth::{AccessToken, RequestToken};

// Domain modules with types needed by lambdas
pub use diary::{FoodEntry, FoodEntryId, FoodEntryInput, MealType};
pub use foods::{FoodSearchResponse, FoodSearchResult};
