/// FatSecret Saved Meals Service Layer - Automatic token management
///
/// High-level API that handles OAuth automatically:
/// - Loads stored tokens from database
/// - Makes authenticated API calls without manual token handling
/// - Detects auth failures and reports status clearly
import gleam/list
import gleam/option.{type Option, None, Some}
import meal_planner/env
import meal_planner/fatsecret/client
import meal_planner/fatsecret/saved_meals/client as saved_meals_client
import meal_planner/fatsecret/saved_meals/types.{
  type MealType, type SavedMeal, type SavedMealId, type SavedMealItem,
  type SavedMealItemId, type SavedMealItemInput, type SavedMealItemsResponse,
  type SavedMealsResponse,
}
import meal_planner/fatsecret/service as fatsecret_service
import meal_planner/fatsecret/storage
import pog

pub type ServiceError {
  NotConnected
  NotConfigured
  AuthRevoked
  EncryptionError(message: String)
  ApiError(inner: client.FatSecretError)
  StorageError(inner: storage.StorageError)
}

// =============================================================================
// Saved Meal Management
// =============================================================================

/// Create a new saved meal template
pub fn create_saved_meal(
  conn: pog.Connection,
  name: String,
  description: Option(String),
  meals: List(MealType),
) -> Result(SavedMealId, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            saved_meals_client.create_saved_meal(
              config,
              token,
              name,
              description,
              meals,
            )
          {
            Ok(id) -> {
              let _ = storage.touch_access_token(conn)
              Ok(id)
            }
            Error(client.RequestFailed(status: 401, body: _)) ->
              Error(AuthRevoked)
            Error(client.RequestFailed(status: 403, body: _)) ->
              Error(AuthRevoked)
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

/// Edit an existing saved meal
pub fn edit_saved_meal(
  conn: pog.Connection,
  saved_meal_id: SavedMealId,
  name: Option(String),
  description: Option(String),
  meals: Option(List(MealType)),
) -> Result(Nil, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            saved_meals_client.edit_saved_meal(
              config,
              token,
              saved_meal_id,
              name,
              description,
              meals,
            )
          {
            Ok(Nil) -> {
              let _ = storage.touch_access_token(conn)
              Ok(Nil)
            }
            Error(client.RequestFailed(status: 401, body: _)) ->
              Error(AuthRevoked)
            Error(client.RequestFailed(status: 403, body: _)) ->
              Error(AuthRevoked)
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

/// Delete a saved meal
pub fn delete_saved_meal(
  conn: pog.Connection,
  saved_meal_id: SavedMealId,
) -> Result(Nil, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            saved_meals_client.delete_saved_meal(config, token, saved_meal_id)
          {
            Ok(Nil) -> {
              let _ = storage.touch_access_token(conn)
              Ok(Nil)
            }
            Error(client.RequestFailed(status: 401, body: _)) ->
              Error(AuthRevoked)
            Error(client.RequestFailed(status: 403, body: _)) ->
              Error(AuthRevoked)
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

/// Get user's saved meals, optionally filtered by meal type
pub fn get_saved_meals(
  conn: pog.Connection,
  meal_filter: Option(MealType),
) -> Result(SavedMealsResponse, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case saved_meals_client.get_saved_meals(config, token, meal_filter) {
            Ok(response) -> {
              let _ = storage.touch_access_token(conn)
              Ok(response)
            }
            Error(client.RequestFailed(status: 401, body: _)) ->
              Error(AuthRevoked)
            Error(client.RequestFailed(status: 403, body: _)) ->
              Error(AuthRevoked)
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

// =============================================================================
// Saved Meal Items Management
// =============================================================================

/// Add a food item to a saved meal
pub fn add_saved_meal_item(
  conn: pog.Connection,
  saved_meal_id: SavedMealId,
  item: SavedMealItemInput,
) -> Result(SavedMealItemId, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            saved_meals_client.add_saved_meal_item(
              config,
              token,
              saved_meal_id,
              item,
            )
          {
            Ok(id) -> {
              let _ = storage.touch_access_token(conn)
              Ok(id)
            }
            Error(client.RequestFailed(status: 401, body: _)) ->
              Error(AuthRevoked)
            Error(client.RequestFailed(status: 403, body: _)) ->
              Error(AuthRevoked)
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

/// Edit a saved meal item
pub fn edit_saved_meal_item(
  conn: pog.Connection,
  saved_meal_item_id: SavedMealItemId,
  item: SavedMealItemInput,
) -> Result(Nil, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            saved_meals_client.edit_saved_meal_item(
              config,
              token,
              saved_meal_item_id,
              item,
            )
          {
            Ok(Nil) -> {
              let _ = storage.touch_access_token(conn)
              Ok(Nil)
            }
            Error(client.RequestFailed(status: 401, body: _)) ->
              Error(AuthRevoked)
            Error(client.RequestFailed(status: 403, body: _)) ->
              Error(AuthRevoked)
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

/// Delete a saved meal item
pub fn delete_saved_meal_item(
  conn: pog.Connection,
  saved_meal_item_id: SavedMealItemId,
) -> Result(Nil, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            saved_meals_client.delete_saved_meal_item(
              config,
              token,
              saved_meal_item_id,
            )
          {
            Ok(Nil) -> {
              let _ = storage.touch_access_token(conn)
              Ok(Nil)
            }
            Error(client.RequestFailed(status: 401, body: _)) ->
              Error(AuthRevoked)
            Error(client.RequestFailed(status: 403, body: _)) ->
              Error(AuthRevoked)
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

/// Get items in a saved meal
pub fn get_saved_meal_items(
  conn: pog.Connection,
  saved_meal_id: SavedMealId,
) -> Result(SavedMealItemsResponse, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            saved_meals_client.get_saved_meal_items(
              config,
              token,
              saved_meal_id,
            )
          {
            Ok(response) -> {
              let _ = storage.touch_access_token(conn)
              Ok(response)
            }
            Error(client.RequestFailed(status: 401, body: _)) ->
              Error(AuthRevoked)
            Error(client.RequestFailed(status: 403, body: _)) ->
              Error(AuthRevoked)
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

// =============================================================================
// Helper Functions
// =============================================================================

/// Convert service error to user-friendly string
pub fn error_to_string(error: ServiceError) -> String {
  case error {
    NotConnected -> "Not connected to FatSecret"
    NotConfigured -> "FatSecret API not configured"
    AuthRevoked -> "FatSecret authorization was revoked"
    EncryptionError(msg) -> "Encryption error: " <> msg
    ApiError(inner) ->
      fatsecret_service.error_to_string(fatsecret_service.ApiError(inner))
    StorageError(inner) ->
      fatsecret_service.error_to_string(fatsecret_service.StorageError(inner))
  }
}

fn get_token(conn: pog.Connection) -> Result(client.AccessToken, ServiceError) {
  case storage.encryption_configured() {
    False -> Error(EncryptionError("OAUTH_ENCRYPTION_KEY not set"))
    True -> {
      case storage.get_access_token(conn) {
        Ok(token) -> Ok(token)
        Error(storage.NotFound) -> Error(NotConnected)
        Error(e) -> Error(StorageError(e))
      }
    }
  }
}
