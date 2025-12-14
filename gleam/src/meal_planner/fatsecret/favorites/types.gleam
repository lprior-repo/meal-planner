/// FatSecret Favorites Domain Types
///
/// Types for managing user's favorite foods, recipes, and eating patterns.
/// All API methods require 3-legged OAuth authentication.
///
/// API Reference: https://platform.fatsecret.com/api/Default.aspx?screen=rapir
import gleam/option.{type Option}

/// A favorite food item
/// API: foods.get_favorites.v2
pub type FavoriteFood {
  FavoriteFood(
    food_id: String,
    food_name: String,
    food_type: String,
    brand_name: Option(String),
    food_description: String,
    food_url: String,
    serving_id: String,
    number_of_units: String,
  )
}

/// A most-eaten food item
/// API: foods.get_most_eaten.v2
pub type MostEatenFood {
  MostEatenFood(
    food_id: String,
    food_name: String,
    food_type: String,
    brand_name: Option(String),
    food_description: String,
    food_url: String,
    serving_id: String,
    number_of_units: String,
  )
}

/// A recently eaten food item
/// API: foods.get_recently_eaten.v2
pub type RecentlyEatenFood {
  RecentlyEatenFood(
    food_id: String,
    food_name: String,
    food_type: String,
    brand_name: Option(String),
    food_description: String,
    food_url: String,
    serving_id: String,
    number_of_units: String,
  )
}

/// A favorite recipe
/// API: recipes.get_favorites.v2
pub type FavoriteRecipe {
  FavoriteRecipe(
    recipe_id: String,
    recipe_name: String,
    recipe_description: String,
    recipe_url: String,
    recipe_image: Option(String),
  )
}

/// Response containing favorite foods (no pagination per API docs)
/// API: foods.get_favorites.v2
pub type FavoriteFoodsResponse {
  FavoriteFoodsResponse(foods: List(FavoriteFood))
}

/// Response containing most eaten foods (no pagination per API docs)
/// API: foods.get_most_eaten.v2
pub type MostEatenResponse {
  MostEatenResponse(foods: List(MostEatenFood))
}

/// Response containing recently eaten foods (no pagination per API docs)
/// API: foods.get_recently_eaten.v2
pub type RecentlyEatenResponse {
  RecentlyEatenResponse(foods: List(RecentlyEatenFood))
}

/// Response containing favorite recipes (no pagination per API docs)
/// API: recipes.get_favorites.v2
pub type FavoriteRecipesResponse {
  FavoriteRecipesResponse(recipes: List(FavoriteRecipe))
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
