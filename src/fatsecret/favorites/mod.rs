//! `FatSecret` Favorites Domain - User favorite foods and recipes management
//!
//! This module provides functionality for managing a user's favorite foods, recipes, and
//! eating patterns through the `FatSecret` Platform API. It supports tracking favorites,
//! analyzing eating habits, and retrieving frequently consumed items.
//!
//! # Authentication
//!
//! All API methods in this module require **3-legged OAuth** authentication with user
//! authorization. You must obtain an access token through the OAuth flow before calling
//! any favorites endpoints.
//!
//! # Features
//!
//! - **Favorites Management**: Add/remove foods and recipes from user favorites
//! - **Usage Analytics**: Track most-eaten and recently-eaten foods
//! - **Meal Filtering**: Filter analytics by meal type (breakfast, lunch, dinner, snack)
//! - **Pagination**: Support for paginated results on large favorite lists
//!
//! # Key Types
//!
//! - [`FavoriteFood`] - A food item marked as favorite
//! - [`FavoriteRecipe`] - A recipe marked as favorite
//! - [`MostEatenFood`] - Food item with usage frequency data
//! - [`RecentlyEatenFood`] - Food item from recent consumption history
//! - [`MealFilter`] - Filter for meal type (breakfast, lunch, dinner, snack, all)
//!
//! # Example
//!
//! ```rust,no_run
//! use meal_planner::fatsecret::favorites::{
//!     get_favorite_foods,
//!     add_favorite_food,
//!     get_most_eaten,
//!     MealFilter
//! };
//! use meal_planner::fatsecret::core::config::`FatSecretConfig`;
//! use meal_planner::fatsecret::core::oauth::`AccessToken`;
//!
//! # async fn example() -> Result<(), Box<dyn std::error::Error>> {
//! let config = `FatSecretConfig`::from_env()?;
//! let access_token = `AccessToken` {
//!     token: "user_access_token".to_string(),
//!     secret: "user_token_secret".to_string(),
//! };
//!
//! // Get user's favorite foods
//! let favorites = get_favorite_foods(&config, &access_token, Some(50), None).await?;
//! println!("Found {} favorite foods", favorites.len());
//!
//! // Add a new favorite
//! add_favorite_food(&config, &access_token, "12345").await?;
//!
//! // Analyze eating patterns
//! let breakfast_foods = get_most_eaten(
//!     &config,
//!     &access_token,
//!     Some(MealFilter::Breakfast)
//! ).await?;
//! println!("Most eaten at breakfast: {:?}", breakfast_foods);
//! # Ok(())
//! # }
//! ```
//!
//! # API Reference
//!
//! - [`FatSecret` Platform API - Favorites](https://platform.fatsecret.com/api/Default.aspx?screen=rapir)
//!
//! # Module Organization
//!
//! - [`client`] - API client functions for favorites operations
//! - [`types`] - Data types and request/response models

pub mod client;
pub mod types;

pub use client::{
    add_favorite_food, add_favorite_recipe, delete_favorite_food, delete_favorite_recipe,
    get_favorite_foods, get_favorite_recipes, get_most_eaten, get_recently_eaten,
};
pub use types::{
    FavoriteFood, FavoriteFoodsResponse, FavoriteRecipe, FavoriteRecipesResponse, MealFilter,
    MostEatenFood, MostEatenResponse, RecentlyEatenFood, RecentlyEatenResponse,
};
