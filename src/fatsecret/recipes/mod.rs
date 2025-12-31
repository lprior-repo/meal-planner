//! FatSecret Recipe API domain module.
//!
//! This module provides access to the FatSecret Recipe API, enabling search,
//! retrieval, and autocomplete functionality for recipes from the FatSecret database.
//!
//! # Key Types
//!
//! - [`Recipe`] - Complete recipe details including ingredients, directions, and nutrition
//! - [`RecipeId`] - Opaque type-safe wrapper for recipe identifiers
//! - [`RecipeSearchResult`] - Lightweight recipe summary from search results
//! - [`RecipeSuggestion`] - Autocomplete suggestion for recipe names
//!
//! # API Functions
//!
//! - [`client::get_recipe()`] - Fetch full recipe details by ID
//! - [`client::search_recipes()`] - Search recipes by expression with pagination
//! - [`client::autocomplete_recipes()`] - Get recipe name suggestions for autocomplete
//! - [`client::get_recipe_types()`] - List all available recipe categories
//!
//! # Usage Example
//!
//! ```no_run
//! use meal_planner::fatsecret::core::config::FatSecretConfig;
//! use meal_planner::fatsecret::recipes::{search_recipes, get_recipe};
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = FatSecretConfig::from_env()?;
//!
//! // Search for chicken recipes
//! let search = search_recipes(&config, "chicken", Some(10), Some(0), None).await?;
//! println!("Found {} recipes", search.total_results);
//!
//! // Get full details for first result
//! if let Some(result) = search.recipes.first() {
//!     let recipe = get_recipe(&config, &result.recipe_id).await?;
//!     println!("Recipe: {}", recipe.recipe_name);
//!     println!("Servings: {}", recipe.number_of_servings);
//!     println!("Ingredients: {}", recipe.ingredients.ingredients.len());
//! }
//! # Ok(())
//! # }
//! ```
//!
//! # API Authentication
//!
//! All functions in this module use **2-legged OAuth** (application-only auth).
//! User-specific OAuth tokens are not required.

pub mod client;
pub mod types;

pub use client::*;
pub use types::*;
