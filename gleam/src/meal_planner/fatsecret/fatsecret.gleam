// ============================================================================
// Core Configuration and Errors
// ============================================================================

/// FatSecret SDK for Gleam
///
/// This is the main facade module for easy consumption of the FatSecret SDK.
/// Import this module to access all core types and functions:
///
/// ```gleam
/// import meal_planner/fatsecret/fatsecret
///
/// let food_id = fatsecret.food_id("12345")
/// case fatsecret.get_food(food_id) {
///   Ok(food) -> io.println("Found: " <> food.food_name)
///   Error(_) -> io.println("Failed to get food")
/// }
/// ```
import meal_planner/fatsecret/core/config
import meal_planner/fatsecret/core/errors
import meal_planner/fatsecret/core/oauth

/// FatSecret API configuration
pub type FatSecretConfig =
  config.FatSecretConfig

/// All possible errors from the FatSecret SDK
pub type FatSecretError =
  errors.FatSecretError

/// FatSecret API error codes
pub type ApiErrorCode =
  errors.ApiErrorCode

/// OAuth 1.0a access token for 3-legged authentication
pub type AccessToken =
  oauth.AccessToken

/// OAuth 1.0a request token (Step 1 of 3-legged flow)
pub type RequestToken =
  oauth.RequestToken

// Configuration functions
pub const from_env = config.from_env

pub const new_config = config.new

pub const api_url = config.api_url

pub const authorization_url = config.authorization_url

// Error handling functions
pub const error_to_string = errors.error_to_string

pub const is_recoverable = errors.is_recoverable

pub const is_auth_error = errors.is_auth_error

// ============================================================================
// Foods Domain
// ============================================================================

import meal_planner/fatsecret/foods/service as foods_service
import meal_planner/fatsecret/foods/types as foods_types

/// Service-level error for Foods API
pub type FoodsServiceError =
  foods_service.ServiceError

/// Opaque type for FatSecret food IDs
pub type FoodId =
  foods_types.FoodId

/// Complete food details with all servings
pub type Food =
  foods_types.Food

/// Single food search result
pub type FoodSearchResult =
  foods_types.FoodSearchResult

/// Response from foods.search API
pub type FoodSearchResponse =
  foods_types.FoodSearchResponse

/// Nutrition information for a food serving
pub type Nutrition =
  foods_types.Nutrition

/// A serving size option for a food
pub type Serving =
  foods_types.Serving

/// Opaque type for serving IDs
pub type ServingId =
  foods_types.ServingId

// Food ID constructors
pub const food_id = foods_types.food_id

pub const food_id_to_string = foods_types.food_id_to_string

pub const serving_id = foods_types.serving_id

pub const serving_id_to_string = foods_types.serving_id_to_string

// Food service functions
pub const get_food = foods_service.get_food

pub const search_foods = foods_service.search_foods

// ============================================================================
// Recipes Domain
// ============================================================================

import meal_planner/fatsecret/recipes/service as recipes_service
import meal_planner/fatsecret/recipes/types as recipes_types

/// Service-level error for Recipes API
pub type RecipesServiceError =
  recipes_service.RecipeServiceError

/// Opaque type for recipe IDs
pub type RecipeId =
  recipes_types.RecipeId

/// Complete recipe details
pub type Recipe =
  recipes_types.Recipe

/// Recipe search result item
pub type RecipeSearchResult =
  recipes_types.RecipeSearchResult

/// Response from recipes.search API
pub type RecipeSearchResponse =
  recipes_types.RecipeSearchResponse

/// Recipe category/type
pub type RecipeType =
  recipes_types.RecipeType

/// Ingredient in a recipe
pub type RecipeIngredient =
  recipes_types.RecipeIngredient

/// Direction/step in recipe preparation
pub type RecipeDirection =
  recipes_types.RecipeDirection

/// Response from recipe_types.get API
pub type RecipeTypesResponse =
  recipes_types.RecipeTypesResponse

// Recipe ID constructors
pub const recipe_id = recipes_types.recipe_id

pub const recipe_id_to_string = recipes_types.recipe_id_to_string

// Recipe service functions
pub const get_recipe = recipes_service.get_recipe

pub const search_recipes = recipes_service.search_recipes

pub const search_recipes_by_type = recipes_service.search_recipes_by_type

pub const get_recipe_types = recipes_service.get_recipe_types

// ============================================================================
// Favorites Domain
// ============================================================================

import meal_planner/fatsecret/favorites/service as favorites_service
import meal_planner/fatsecret/favorites/types as favorites_types

/// A favorite food item
pub type FavoriteFood =
  favorites_types.FavoriteFood

/// A most-eaten food with consumption count
pub type MostEatenFood =
  favorites_types.MostEatenFood

/// A recently eaten food item
pub type RecentlyEatenFood =
  favorites_types.RecentlyEatenFood

/// A favorite recipe
pub type FavoriteRecipe =
  favorites_types.FavoriteRecipe

/// Response containing favorite foods with pagination
pub type FavoriteFoodsResponse =
  favorites_types.FavoriteFoodsResponse

/// Response containing most eaten foods
pub type MostEatenResponse =
  favorites_types.MostEatenResponse

/// Response containing recently eaten foods
pub type RecentlyEatenResponse =
  favorites_types.RecentlyEatenResponse

/// Response containing favorite recipes with pagination
pub type FavoriteRecipesResponse =
  favorites_types.FavoriteRecipesResponse

/// Meal type filter for most/recently eaten queries
pub type FavoritesMealFilter =
  favorites_types.MealFilter

// Favorites service functions
pub const add_favorite_food = favorites_service.add_favorite_food

pub const delete_favorite_food = favorites_service.delete_favorite_food

pub const get_favorite_foods = favorites_service.get_favorite_foods

pub const get_most_eaten = favorites_service.get_most_eaten

pub const get_recently_eaten = favorites_service.get_recently_eaten

pub const add_favorite_recipe = favorites_service.add_favorite_recipe

pub const delete_favorite_recipe = favorites_service.delete_favorite_recipe

pub const get_favorite_recipes = favorites_service.get_favorite_recipes

// ============================================================================
// Saved Meals Domain
// ============================================================================

import meal_planner/fatsecret/saved_meals/service as saved_meals_service
import meal_planner/fatsecret/saved_meals/types as saved_meals_types

/// Opaque type for saved meal IDs
pub type SavedMealId =
  saved_meals_types.SavedMealId

/// Opaque type for saved meal item IDs
pub type SavedMealItemId =
  saved_meals_types.SavedMealItemId

/// A saved meal template (collection of food items)
pub type SavedMeal =
  saved_meals_types.SavedMeal

/// A food item within a saved meal
pub type SavedMealItem =
  saved_meals_types.SavedMealItem

/// Input for creating/editing saved meal items
pub type SavedMealItemInput =
  saved_meals_types.SavedMealItemInput

/// Response from saved_meals.get API
pub type SavedMealsResponse =
  saved_meals_types.SavedMealsResponse

/// Response from saved_meal_items.get API
pub type SavedMealItemsResponse =
  saved_meals_types.SavedMealItemsResponse

/// Meal type for saved meals
pub type SavedMealMealType =
  saved_meals_types.MealType

// Saved meal ID constructors
pub const saved_meal_id_to_string = saved_meals_types.saved_meal_id_to_string

pub const saved_meal_id_from_string = saved_meals_types.saved_meal_id_from_string

pub const saved_meal_item_id_to_string = saved_meals_types.saved_meal_item_id_to_string

pub const saved_meal_item_id_from_string = saved_meals_types.saved_meal_item_id_from_string

// Saved meals service functions
pub const create_saved_meal = saved_meals_service.create_saved_meal

pub const get_saved_meals = saved_meals_service.get_saved_meals

pub const edit_saved_meal = saved_meals_service.edit_saved_meal

pub const delete_saved_meal = saved_meals_service.delete_saved_meal

pub const get_saved_meal_items = saved_meals_service.get_saved_meal_items

pub const add_saved_meal_item = saved_meals_service.add_saved_meal_item

pub const edit_saved_meal_item = saved_meals_service.edit_saved_meal_item

pub const delete_saved_meal_item = saved_meals_service.delete_saved_meal_item

// ============================================================================
// Diary Domain
// ============================================================================

import meal_planner/fatsecret/diary/types as diary_types

/// Opaque food entry ID from FatSecret API
pub type FoodEntryId =
  diary_types.FoodEntryId

/// Complete food diary entry
pub type FoodEntry =
  diary_types.FoodEntry

/// Input for creating a new food entry
pub type FoodEntryInput =
  diary_types.FoodEntryInput

/// Update for an existing food entry
pub type FoodEntryUpdate =
  diary_types.FoodEntryUpdate

/// Daily nutrition summary
pub type DaySummary =
  diary_types.DaySummary

/// Monthly nutrition summary
pub type MonthSummary =
  diary_types.MonthSummary

/// Meal type for diary entries
pub type DiaryMealType =
  diary_types.MealType

// Food entry ID constructors
pub const food_entry_id = diary_types.food_entry_id

pub const food_entry_id_to_string = diary_types.food_entry_id_to_string

// Date conversion functions
pub const date_to_int = diary_types.date_to_int

pub const int_to_date = diary_types.int_to_date

// Meal type conversion
pub const diary_meal_type_to_string = diary_types.meal_type_to_string

pub const diary_meal_type_from_string = diary_types.meal_type_from_string

// Note: Diary service functions will be added when the service module is created

// ============================================================================
// Weight Domain
// ============================================================================

import meal_planner/fatsecret/weight/service as weight_service
import meal_planner/fatsecret/weight/types as weight_types

/// Weight entry with date
pub type WeightEntry =
  weight_types.WeightEntry

/// Weight update input
pub type WeightUpdate =
  weight_types.WeightUpdate

/// Daily weight summary
pub type WeightDaySummary =
  weight_types.WeightDaySummary

/// Monthly summary of weight entries
pub type WeightMonthSummary =
  weight_types.WeightMonthSummary

// Weight service functions
pub const update_weight = weight_service.update_weight

pub const get_weight_month_summary = weight_service.get_weight_month_summary

// ============================================================================
// Profile Domain
// ============================================================================

import meal_planner/fatsecret/profile/oauth as profile_oauth
import meal_planner/fatsecret/profile/types as profile_types

/// User profile information
pub type Profile =
  profile_types.Profile

/// Profile auth response
pub type ProfileAuth =
  profile_types.ProfileAuth

/// Profile create input
pub type ProfileCreateInput =
  profile_types.ProfileCreateInput

/// Step 1: Get request token for OAuth
pub const get_request_token = profile_oauth.get_request_token

/// Step 2: Get authorization URL
pub const get_authorization_url = profile_oauth.get_authorization_url

/// Step 3: Exchange request token for access token
pub const get_access_token = profile_oauth.get_access_token
// Note: Profile service functions will be added when the service module is created
