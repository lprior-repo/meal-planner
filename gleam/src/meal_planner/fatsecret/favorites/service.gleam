/// FatSecret Favorites Service Layer
///
/// High-level API with automatic token management for favorites operations.
/// Loads access token from database and handles auth errors gracefully.
import gleam/option.{type Option}
import meal_planner/env
import meal_planner/fatsecret/client
import meal_planner/fatsecret/favorites/client as favorites_client
import meal_planner/fatsecret/favorites/types
import meal_planner/fatsecret/service.{type ServiceError}
import meal_planner/fatsecret/storage
import pog

/// Get token from storage with error handling
fn get_token(conn: pog.Connection) -> Result(client.AccessToken, ServiceError) {
  case storage.encryption_configured() {
    False -> Error(service.EncryptionError("OAUTH_ENCRYPTION_KEY not set"))
    True -> {
      case storage.get_access_token(conn) {
        Ok(token) -> Ok(token)
        Error(storage.NotFound) -> Error(service.NotConnected)
        Error(e) -> Error(service.StorageError(e))
      }
    }
  }
}

/// Handle API auth errors
fn handle_auth_error(error: client.FatSecretError) -> ServiceError {
  case error {
    client.RequestFailed(status: 401, body: _) -> service.AuthRevoked
    client.RequestFailed(status: 403, body: _) -> service.AuthRevoked
    client.ApiError(code: "2", message: _) -> service.AuthRevoked
    e -> service.ApiError(e)
  }
}

/// Touch token on successful request
fn touch_token(conn: pog.Connection) {
  let _ = storage.touch_access_token(conn)
  Nil
}

// =============================================================================
// Favorite Foods
// =============================================================================

/// Add a food to favorites
pub fn add_favorite_food(
  conn: pog.Connection,
  food_id: String,
) -> Result(String, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(service.NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case favorites_client.add_favorite_food(config, token, food_id) {
            Ok(result) -> {
              touch_token(conn)
              Ok(result)
            }
            Error(e) -> Error(handle_auth_error(e))
          }
        }
      }
    }
  }
}

/// Remove a food from favorites
pub fn delete_favorite_food(
  conn: pog.Connection,
  food_id: String,
) -> Result(String, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(service.NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case favorites_client.delete_favorite_food(config, token, food_id) {
            Ok(result) -> {
              touch_token(conn)
              Ok(result)
            }
            Error(e) -> Error(handle_auth_error(e))
          }
        }
      }
    }
  }
}

/// Get user's favorite foods
pub fn get_favorite_foods(
  conn: pog.Connection,
  max_results: Option(Int),
  page_number: Option(Int),
) -> Result(types.FavoriteFoodsResponse, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(service.NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            favorites_client.get_favorite_foods_parsed(
              config,
              token,
              max_results,
              page_number,
            )
          {
            Ok(foods) -> {
              touch_token(conn)
              Ok(foods)
            }
            Error(e) -> Error(handle_auth_error(e))
          }
        }
      }
    }
  }
}

// =============================================================================
// Most/Recently Eaten
// =============================================================================

/// Get user's most eaten foods
pub fn get_most_eaten(
  conn: pog.Connection,
  meal: Option(types.MealFilter),
) -> Result(types.MostEatenResponse, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(service.NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case favorites_client.get_most_eaten_parsed(config, token, meal) {
            Ok(foods) -> {
              touch_token(conn)
              Ok(foods)
            }
            Error(e) -> Error(handle_auth_error(e))
          }
        }
      }
    }
  }
}

/// Get user's recently eaten foods
pub fn get_recently_eaten(
  conn: pog.Connection,
  meal: Option(types.MealFilter),
) -> Result(types.RecentlyEatenResponse, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(service.NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case favorites_client.get_recently_eaten_parsed(config, token, meal) {
            Ok(foods) -> {
              touch_token(conn)
              Ok(foods)
            }
            Error(e) -> Error(handle_auth_error(e))
          }
        }
      }
    }
  }
}

// =============================================================================
// Favorite Recipes
// =============================================================================

/// Add a recipe to favorites
pub fn add_favorite_recipe(
  conn: pog.Connection,
  recipe_id: String,
) -> Result(String, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(service.NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case favorites_client.add_favorite_recipe(config, token, recipe_id) {
            Ok(result) -> {
              touch_token(conn)
              Ok(result)
            }
            Error(e) -> Error(handle_auth_error(e))
          }
        }
      }
    }
  }
}

/// Remove a recipe from favorites
pub fn delete_favorite_recipe(
  conn: pog.Connection,
  recipe_id: String,
) -> Result(String, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(service.NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            favorites_client.delete_favorite_recipe(config, token, recipe_id)
          {
            Ok(result) -> {
              touch_token(conn)
              Ok(result)
            }
            Error(e) -> Error(handle_auth_error(e))
          }
        }
      }
    }
  }
}

/// Get user's favorite recipes
pub fn get_favorite_recipes(
  conn: pog.Connection,
  max_results: Option(Int),
  page_number: Option(Int),
) -> Result(types.FavoriteRecipesResponse, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(service.NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            favorites_client.get_favorite_recipes_parsed(
              config,
              token,
              max_results,
              page_number,
            )
          {
            Ok(recipes) -> {
              touch_token(conn)
              Ok(recipes)
            }
            Error(e) -> Error(handle_auth_error(e))
          }
        }
      }
    }
  }
}
