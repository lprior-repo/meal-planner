/// FatSecret Favorites Domain Types
///
/// Types for managing user's favorite foods, recipes, and eating patterns.
/// All API methods require 3-legged OAuth authentication.
///
/// API Reference: https://platform.fatsecret.com/api/Default.aspx?screen=rapir
import gleam/option.{type Option}

/// A favorite food item
pub type FavoriteFood {
  FavoriteFood(
    food_id: String,
    food_name: String,
    food_type: String,
    brand_name: Option(String),
    food_description: String,
    food_url: String,
  )
}

/// A most-eaten food with consumption count
pub type MostEatenFood {
  MostEatenFood(
    food_id: String,
    food_name: String,
    food_type: String,
    brand_name: Option(String),
    food_description: String,
    food_url: String,
    eat_count: Int,
  )
}

/// A recently eaten food item
pub type RecentlyEatenFood {
  RecentlyEatenFood(
    food_id: String,
    food_name: String,
    food_type: String,
    brand_name: Option(String),
    food_description: String,
    food_url: String,
  )
}

/// A favorite recipe
pub type FavoriteRecipe {
  FavoriteRecipe(
    recipe_id: String,
    recipe_name: String,
    recipe_description: String,
    recipe_url: String,
    recipe_image: Option(String),
  )
}

/// Response containing favorite foods with pagination
pub type FavoriteFoodsResponse {
  FavoriteFoodsResponse(
    foods: List(FavoriteFood),
    max_results: Int,
    total_results: Int,
    page_number: Int,
  )
}

/// Response containing most eaten foods
pub type MostEatenResponse {
  MostEatenResponse(foods: List(MostEatenFood), meal: Option(String))
}

/// Response containing recently eaten foods
pub type RecentlyEatenResponse {
  RecentlyEatenResponse(foods: List(RecentlyEatenFood), meal: Option(String))
}

/// Response containing favorite recipes with pagination
pub type FavoriteRecipesResponse {
  FavoriteRecipesResponse(
    recipes: List(FavoriteRecipe),
    max_results: Int,
    total_results: Int,
    page_number: Int,
  )
}

/// Meal type filter for most/recently eaten queries
pub type MealFilter {
  AllMeals
  Breakfast
  Lunch
  Dinner
  Snack
}

/// Convert MealFilter to API parameter string
pub fn meal_filter_to_string(meal: MealFilter) -> String {
  case meal {
    AllMeals -> "all"
    Breakfast -> "breakfast"
    Lunch -> "lunch"
    Dinner -> "dinner"
    Snack -> "other"
  }
}
