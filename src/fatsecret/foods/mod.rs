//! FatSecret Foods API Domain
//!
//! This module provides a complete interface to the FatSecret Foods API for searching,
//! retrieving, and analyzing food nutrition data. It implements the domain-driven design
//! pattern with clear separation between types and client operations.
//!
//! # Organization
//!
//! - [`client`] - API client functions for interacting with FatSecret foods endpoints
//! - [`types`] - Type definitions for foods, servings, and nutrition information
//!
//! # Key Types
//!
//! - [`Food`] - Complete food details including all serving options
//! - [`FoodId`] - Opaque identifier for a specific food
//! - [`Serving`] - A serving size option with associated nutrition data
//! - [`Nutrition`] - Comprehensive nutrition information (macros, micros, vitamins)
//! - [`FoodSearchResponse`] - Paginated search results from foods.search API
//! - [`FoodAutocompleteResponse`] - Quick suggestions from foods.autocomplete API
//!
//! # API Coverage
//!
//! This module wraps these FatSecret Platform API endpoints:
//!
//! - `food.get.v5` - Get complete food details by ID
//! - `foods.search` - Search foods by text query with pagination
//! - `foods.autocomplete.v2` - Get food suggestions for autocomplete
//! - `food.find_id_for_barcode.v2` - Lookup food by barcode (UPC/EAN)
//!
//! All endpoints use 2-legged OAuth (no user token required).
//!
//! # Examples
//!
//! ## Search for foods and get details
//!
//! ```no_run
//! use meal_planner::fatsecret::foods::{search_foods_simple, get_food};
//! use meal_planner::fatsecret::core::FatSecretConfig;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = FatSecretConfig::from_env()?;
//!
//! // Search for "chicken breast"
//! let results = search_foods_simple(&config, "chicken breast").await?;
//! println!("Found {} foods", results.total_results);
//!
//! // Get detailed nutrition for first result
//! if let Some(first) = results.foods.first() {
//!     let food = get_food(&config, &first.food_id).await?;
//!     println!("{} has {} servings", food.food_name, food.servings.serving.len());
//!     
//!     // Show nutrition for default serving
//!     if let Some(serving) = food.servings.serving.first() {
//!         println!("{}: {} cal, {}g protein",
//!             serving.serving_description,
//!             serving.nutrition.calories,
//!             serving.nutrition.protein
//!         );
//!     }
//! }
//! # Ok(())
//! # }
//! ```
//!
//! ## Autocomplete for search-as-you-type
//!
//! ```no_run
//! use meal_planner::fatsecret::foods::autocomplete_foods;
//! use meal_planner::fatsecret::core::FatSecretConfig;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = FatSecretConfig::from_env()?;
//!
//! let suggestions = autocomplete_foods(&config, "chick").await?;
//! for suggestion in suggestions.suggestions {
//!     println!("{}: {}", suggestion.food_id, suggestion.food_name);
//! }
//! # Ok(())
//! # }
//! ```
//!
//! ## Barcode lookup
//!
//! ```no_run
//! use meal_planner::fatsecret::foods::find_food_by_barcode;
//! use meal_planner::fatsecret::core::FatSecretConfig;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = FatSecretConfig::from_env()?;
//!
//! // Lookup by UPC barcode
//! let food = find_food_by_barcode(&config, "012345678901", Some("upc")).await?;
//! println!("Found: {}", food.food_name);
//! # Ok(())
//! # }
//! ```
//!
//! # See Also
//!
//! - [FatSecret Foods API Documentation](https://platform.fatsecret.com/api/Default.aspx?screen=rapiref2&method=foods.search)
//! - [`crate::fatsecret::core`] for OAuth configuration
//! - [`crate::fatsecret::diary`] for logging food consumption

pub mod client;
pub mod types;

pub use client::{
    autocomplete_foods, autocomplete_foods_with_options, find_food_by_barcode, get_food,
    list_foods_with_options, search_foods, search_foods_simple,
};
pub use types::{
    Food, FoodAutocompleteResponse, FoodId, FoodSearchResponse, FoodSearchResult, FoodSuggestion,
    Nutrition, Serving, ServingId,
};
