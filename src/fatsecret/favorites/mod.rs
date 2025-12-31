//! FatSecret Favorites Domain - Favorite foods and recipes management
//!
//! Types for managing user's favorite foods, recipes, and eating patterns.
//! All API methods require 3-legged OAuth authentication.
//!
//! API Reference: https://platform.fatsecret.com/api/Default.aspx?screen=rapir

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
