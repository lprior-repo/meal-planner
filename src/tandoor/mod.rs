//! Tandoor Recipes API Client
//!
//! A type-safe Rust client for interacting with the [Tandoor Recipes](https://docs.tandoor.dev/)
//! API. This module provides a blocking HTTP client for managing recipes, importing from URLs,
//! and testing connectivity.
//!
//! # Architecture
//!
//! The module is organized into three parts:
//!
//! - `client` - HTTP client implementation ([`TandoorClient`])
//! - `types` - Request/response types and configuration
//! - This module - Public API surface
//!
//! # Key Types
//!
//! - [`TandoorClient`] - Main client for making API requests
//! - [`TandoorConfig`] - Configuration (base URL + API token)
//! - [`RecipeSummary`] - Recipe metadata from list endpoints
//! - [`RecipeImportResult`] - Result of importing a recipe from a URL
//!
//! # Usage Example
//!
//! ```rust,no_run
//! use meal_planner::tandoor::{TandoorClient, TandoorConfig};
//!
//! # fn main() -> Result<(), Box<dyn std::error::Error>> {
//! // Configure client
//! let config = TandoorConfig {
//!     base_url: "http://localhost:8090".to_string(),
//!     api_token: "your-api-token".to_string(),
//! };
//!
//! // Create client and test connection
//! let client = TandoorClient::new(&config)?;
//! let result = client.test_connection()?;
//! println!("Connected! Found {} recipes", result.recipe_count);
//!
//! // List recipes with pagination
//! let recipes = client.list_recipes(Some(1), Some(10))?;
//! for recipe in recipes.results {
//!     println!("Recipe: {}", recipe.name);
//! }
//!
//! // Import a recipe from a URL
//! let import = client.import_recipe_from_url(
//!     "https://example.com/recipe",
//!     Some(vec!["dinner".to_string(), "quick".to_string()])
//! )?;
//!
//! if import.success {
//!     println!("Imported: {} (ID: {})",
//!         import.recipe_name.unwrap(),
//!         import.`recipe_id`.unwrap()
//!     );
//! }
//! # Ok(())
//! # }
//! ```
//!
//! # Binary Usage
//!
//! This module is used by small, focused binaries in `src/bin/tandoor_*.rs`:
//!
//! - `tandoor_test_connection` - Verify API connectivity
//! - `tandoor_list_recipes` - List recipes with pagination
//! - `tandoor_import_recipe` - Import from URL
//!
//! See [`ARCHITECTURE.md`](../../../docs/ARCHITECTURE.md) for design principles.

mod client;
mod types;

pub use client::TandoorClient;
pub use types::*;
