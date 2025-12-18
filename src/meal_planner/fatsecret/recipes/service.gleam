/// FatSecret Recipes Service Layer
/// High-level operations for recipe functionality
/// All recipe methods are 2-legged OAuth (no user authentication required)
import gleam/int
import gleam/option.{type Option}
import meal_planner/env
import meal_planner/fatsecret/client
import meal_planner/fatsecret/recipes/client as recipe_client
import meal_planner/fatsecret/recipes/types

pub type RecipeServiceError {
  NotConfigured
  ApiError(inner: client.FatSecretError)
}

/// Get recipe by ID
pub fn get_recipe(
  recipe_id: types.RecipeId,
) -> Result(types.Recipe, RecipeServiceError) {
  case env.load_fatsecret_config() {
    option.None -> Error(NotConfigured)
    option.Some(config) -> {
      case recipe_client.get_recipe_parsed(config, recipe_id) {
        Ok(recipe) -> Ok(recipe)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

/// Search for recipes by query string
pub fn search_recipes(
  query: String,
  page_number: Option(Int),
  max_results: Option(Int),
) -> Result(types.RecipeSearchResponse, RecipeServiceError) {
  case env.load_fatsecret_config() {
    option.None -> Error(NotConfigured)
    option.Some(config) -> {
      case
        recipe_client.search_recipes_parsed(
          config,
          query,
          page_number,
          max_results,
        )
      {
        Ok(results) -> Ok(results)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

/// Get all available recipe types/categories
pub fn get_recipe_types() -> Result(
  types.RecipeTypesResponse,
  RecipeServiceError,
) {
  case env.load_fatsecret_config() {
    option.None -> Error(NotConfigured)
    option.Some(config) -> {
      case recipe_client.get_recipe_types_parsed(config) {
        Ok(types_response) -> Ok(types_response)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

/// Search recipes by type/category
pub fn search_recipes_by_type(
  recipe_type_id: String,
  page_number: Option(Int),
  max_results: Option(Int),
) -> Result(types.RecipeSearchResponse, RecipeServiceError) {
  case env.load_fatsecret_config() {
    option.None -> Error(NotConfigured)
    option.Some(config) -> {
      case
        recipe_client.search_recipes_by_type_parsed(
          config,
          recipe_type_id,
          page_number,
          max_results,
        )
      {
        Ok(results) -> Ok(results)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

/// Convert service error to user-friendly string
pub fn error_to_string(error: RecipeServiceError) -> String {
  case error {
    NotConfigured -> "FatSecret API not configured"
    ApiError(inner) -> client_error_to_string(inner)
  }
}

fn client_error_to_string(error: client.FatSecretError) -> String {
  case error {
    client.ConfigMissing -> "API configuration missing"
    client.RequestFailed(status, body) ->
      "Request failed: HTTP " <> int.to_string(status) <> " - " <> body
    client.InvalidResponse(msg) -> "Invalid response: " <> msg
    client.OAuthError(msg) -> "OAuth error: " <> msg
    client.NetworkError(msg) -> "Network error: " <> msg
    client.ApiError(code, msg) -> "API error " <> code <> ": " <> msg
    client.ParseError(msg) -> "Parse error: " <> msg
  }
}
