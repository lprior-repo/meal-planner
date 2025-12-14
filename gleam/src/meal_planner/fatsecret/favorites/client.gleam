/// FatSecret Favorites API Client
///
/// Low-level OAuth 1.0a signed requests for favorites endpoints.
/// All methods require 3-legged OAuth (user access token).
///
/// API Reference: https://platform.fatsecret.com/api/Default.aspx?screen=rapir
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/env.{type FatSecretConfig}
import meal_planner/fatsecret/client.{type AccessToken, type FatSecretError}
import meal_planner/fatsecret/favorites/decoders
import meal_planner/fatsecret/favorites/types

/// Make authenticated API request with user's access token
/// Delegates to the main client module's authenticated request logic
fn make_authenticated_request(
  config: FatSecretConfig,
  access_token: AccessToken,
  method_name: String,
  params: Dict(String, String),
) -> Result(String, FatSecretError) {
  // The client module already has a public make_authenticated_request function
  // that handles OAuth signing and error checking
  client.make_authenticated_request(config, access_token, method_name, params)
}

// =============================================================================
// Favorite Foods
// =============================================================================

/// Add a food to favorites
/// API: food.add_favorite
pub fn add_favorite_food(
  config: FatSecretConfig,
  access_token: AccessToken,
  food_id: String,
) -> Result(String, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("food_id", food_id)

  make_authenticated_request(config, access_token, "food.add_favorite", params)
}

/// Remove a food from favorites
/// API: food.delete_favorite
pub fn delete_favorite_food(
  config: FatSecretConfig,
  access_token: AccessToken,
  food_id: String,
) -> Result(String, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("food_id", food_id)

  make_authenticated_request(
    config,
    access_token,
    "food.delete_favorite",
    params,
  )
}

/// Get user's favorite foods
/// API: foods.get_favorites.v2
pub fn get_favorite_foods(
  config: FatSecretConfig,
  access_token: AccessToken,
  max_results: Option(Int),
  page_number: Option(Int),
) -> Result(String, FatSecretError) {
  let params = dict.new()

  let params = case max_results {
    Some(n) -> dict.insert(params, "max_results", int.to_string(n))
    None -> params
  }

  let params = case page_number {
    Some(n) -> dict.insert(params, "page_number", int.to_string(n))
    None -> params
  }

  make_authenticated_request(
    config,
    access_token,
    "foods.get_favorites.v2",
    params,
  )
}

/// Get user's favorite foods (parsed)
pub fn get_favorite_foods_parsed(
  config: FatSecretConfig,
  access_token: AccessToken,
  max_results: Option(Int),
  page_number: Option(Int),
) -> Result(types.FavoriteFoodsResponse, FatSecretError) {
  use response <- result.try(get_favorite_foods(
    config,
    access_token,
    max_results,
    page_number,
  ))

  case decoders.decode_favorite_foods(response) {
    Ok(foods) -> Ok(foods)
    Error(decoders.ParseError(msg)) -> Error(ParseError(msg))
  }
}

// =============================================================================
// Most Eaten Foods
// =============================================================================

/// Get user's most eaten foods
/// API: foods.get_most_eaten.v2
pub fn get_most_eaten(
  config: FatSecretConfig,
  access_token: AccessToken,
  meal: Option(types.MealFilter),
) -> Result(String, FatSecretError) {
  let params = dict.new()

  let params = case meal {
    Some(m) -> dict.insert(params, "meal", types.meal_filter_to_string(m))
    None -> params
  }

  make_authenticated_request(
    config,
    access_token,
    "foods.get_most_eaten.v2",
    params,
  )
}

/// Get user's most eaten foods (parsed)
pub fn get_most_eaten_parsed(
  config: FatSecretConfig,
  access_token: AccessToken,
  meal: Option(types.MealFilter),
) -> Result(types.MostEatenResponse, FatSecretError) {
  use response <- result.try(get_most_eaten(config, access_token, meal))

  case decoders.decode_most_eaten(response) {
    Ok(foods) -> Ok(foods)
    Error(decoders.ParseError(msg)) -> Error(ParseError(msg))
  }
}

// =============================================================================
// Recently Eaten Foods
// =============================================================================

/// Get user's recently eaten foods
/// API: foods.get_recently_eaten.v2
pub fn get_recently_eaten(
  config: FatSecretConfig,
  access_token: AccessToken,
  meal: Option(types.MealFilter),
) -> Result(String, FatSecretError) {
  let params = dict.new()

  let params = case meal {
    Some(m) -> dict.insert(params, "meal", types.meal_filter_to_string(m))
    None -> params
  }

  make_authenticated_request(
    config,
    access_token,
    "foods.get_recently_eaten.v2",
    params,
  )
}

/// Get user's recently eaten foods (parsed)
pub fn get_recently_eaten_parsed(
  config: FatSecretConfig,
  access_token: AccessToken,
  meal: Option(types.MealFilter),
) -> Result(types.RecentlyEatenResponse, FatSecretError) {
  use response <- result.try(get_recently_eaten(config, access_token, meal))

  case decoders.decode_recently_eaten(response) {
    Ok(foods) -> Ok(foods)
    Error(decoders.ParseError(msg)) -> Error(ParseError(msg))
  }
}

// =============================================================================
// Favorite Recipes
// =============================================================================

/// Add a recipe to favorites
/// API: recipe.add_favorite
pub fn add_favorite_recipe(
  config: FatSecretConfig,
  access_token: AccessToken,
  recipe_id: String,
) -> Result(String, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("recipe_id", recipe_id)

  make_authenticated_request(
    config,
    access_token,
    "recipe.add_favorite",
    params,
  )
}

/// Remove a recipe from favorites
/// API: recipe.delete_favorite
pub fn delete_favorite_recipe(
  config: FatSecretConfig,
  access_token: AccessToken,
  recipe_id: String,
) -> Result(String, FatSecretError) {
  let params =
    dict.new()
    |> dict.insert("recipe_id", recipe_id)

  make_authenticated_request(
    config,
    access_token,
    "recipe.delete_favorite",
    params,
  )
}

/// Get user's favorite recipes
/// API: recipes.get_favorites.v2
pub fn get_favorite_recipes(
  config: FatSecretConfig,
  access_token: AccessToken,
  max_results: Option(Int),
  page_number: Option(Int),
) -> Result(String, FatSecretError) {
  let params = dict.new()

  let params = case max_results {
    Some(n) -> dict.insert(params, "max_results", int.to_string(n))
    None -> params
  }

  let params = case page_number {
    Some(n) -> dict.insert(params, "page_number", int.to_string(n))
    None -> params
  }

  make_authenticated_request(
    config,
    access_token,
    "recipes.get_favorites.v2",
    params,
  )
}

/// Get user's favorite recipes (parsed)
pub fn get_favorite_recipes_parsed(
  config: FatSecretConfig,
  access_token: AccessToken,
  max_results: Option(Int),
  page_number: Option(Int),
) -> Result(types.FavoriteRecipesResponse, FatSecretError) {
  use response <- result.try(get_favorite_recipes(
    config,
    access_token,
    max_results,
    page_number,
  ))

  case decoders.decode_favorite_recipes(response) {
    Ok(recipes) -> Ok(recipes)
    Error(decoders.ParseError(msg)) -> Error(ParseError(msg))
  }
}
