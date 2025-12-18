/// FatSecret Service Layer - Automatic token management
///
/// This module provides a high-level API that handles OAuth automatically:
/// - Loads stored tokens from database
/// - Makes authenticated API calls without manual token handling
/// - Detects auth failures and reports status clearly
/// - Validates tokens on startup
import gleam/int
import gleam/io
import gleam/option.{type Option, None, Some}
import meal_planner/env
import meal_planner/fatsecret/client
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

pub type ConnectionStatus {
  Connected(last_validated: Option(String))
  Disconnected(reason: String)
  ConfigMissing
  EncryptionKeyMissing
}

/// Check if FatSecret is fully configured and connected
pub fn check_status(conn: pog.Connection) -> ConnectionStatus {
  case env.load_fatsecret_config() {
    None -> ConfigMissing
    Some(_config) -> {
      case storage.encryption_configured() {
        False -> EncryptionKeyMissing
        True -> {
          case storage.get_access_token(conn) {
            Ok(_token) -> Connected(last_validated: None)
            Error(storage.NotFound) -> Disconnected(reason: "Not connected yet")
            Error(storage.EncryptionError(msg)) ->
              Disconnected(reason: "Encryption error: " <> msg)
            Error(storage.DatabaseError(msg)) ->
              Disconnected(reason: "Database error: " <> msg)
          }
        }
      }
    }
  }
}

/// Validate the stored token by making a test API call
pub fn validate_connection(conn: pog.Connection) -> Result(Bool, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case client.get_profile(config, token) {
            Ok(_) -> {
              let _ = storage.touch_access_token(conn)
              Ok(True)
            }
            Error(client.RequestFailed(status: 401, body: _)) -> Ok(False)
            Error(client.RequestFailed(status: 403, body: _)) -> Ok(False)
            Error(client.ApiError(code: "2", message: _)) -> Ok(False)
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

/// Get user profile - fully automatic token handling
pub fn get_profile(conn: pog.Connection) -> Result(String, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case client.get_profile(config, token) {
            Ok(profile) -> {
              let _ = storage.touch_access_token(conn)
              Ok(profile)
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

/// Get food entries for a date - fully automatic token handling
pub fn get_food_entries(
  conn: pog.Connection,
  date: String,
) -> Result(String, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case client.get_food_entries(config, token, date) {
            Ok(entries) -> {
              let _ = storage.touch_access_token(conn)
              Ok(entries)
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

/// Create a food entry - fully automatic token handling
pub fn create_food_entry(
  conn: pog.Connection,
  entry: client.FoodEntry,
) -> Result(String, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case client.create_food_entry(config, token, entry) {
            Ok(result) -> {
              let _ = storage.touch_access_token(conn)
              Ok(result)
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

/// Search foods (2-legged, no user token needed)
pub fn search_foods(query: String) -> Result(String, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case client.search_foods(config, query) {
        Ok(results) -> Ok(results)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

/// Search foods and get parsed results
pub fn search_foods_parsed(
  query: String,
) -> Result(List(client.FoodResult), ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case client.search_foods_parsed(config, query) {
        Ok(results) -> Ok(results)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

/// Get food details by ID (2-legged, no user token needed)
pub fn get_food(food_id: String) -> Result(String, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case client.get_food(config, food_id) {
        Ok(result) -> Ok(result)
        Error(e) -> Error(ApiError(e))
      }
    }
  }
}

/// Startup validation - call this when server starts
pub fn startup_check(conn: pog.Connection) -> String {
  case check_status(conn) {
    ConfigMissing ->
      "⚠ FatSecret: API credentials not configured (set FATSECRET_CONSUMER_KEY/SECRET)"

    EncryptionKeyMissing ->
      "⚠ FatSecret: Encryption key not set (set OAUTH_ENCRYPTION_KEY)"

    Disconnected(reason) ->
      "⚠ FatSecret: " <> reason <> " - visit /fatsecret/connect to authorize"

    Connected(_) -> {
      case validate_connection(conn) {
        Ok(True) -> "✓ FatSecret: Connected and validated"
        Ok(False) -> {
          io.println(
            "⚠ FatSecret: Token revoked - clearing stored token. Please reconnect.",
          )
          let _ = storage.delete_access_token(conn)
          "⚠ FatSecret: Token was revoked - visit /fatsecret/connect to reconnect"
        }
        Error(e) -> "⚠ FatSecret: Validation failed - " <> error_to_string(e)
      }
    }
  }
}

/// Convert service error to user-friendly string
pub fn error_to_string(error: ServiceError) -> String {
  case error {
    NotConnected -> "Not connected to FatSecret"
    NotConfigured -> "FatSecret API not configured"
    AuthRevoked -> "FatSecret authorization was revoked"
    EncryptionError(msg) -> "Encryption error: " <> msg
    ApiError(inner) -> client_error_to_string(inner)
    StorageError(inner) -> storage_error_to_string(inner)
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

fn client_error_to_string(error: client.FatSecretError) -> String {
  case error {
    client.ConfigMissing -> "API configuration missing"
    client.RequestFailed(status, body) ->
      "Request failed (" <> int.to_string(status) <> "): " <> body
    client.InvalidResponse(msg) -> "Invalid response: " <> msg
    client.OAuthError(msg) -> "OAuth error: " <> msg
    client.NetworkError(msg) -> "Network error: " <> msg
    client.ApiError(code, msg) -> "API error " <> code <> ": " <> msg
    client.ParseError(msg) -> "Parse error: " <> msg
  }
}

fn storage_error_to_string(error: storage.StorageError) -> String {
  case error {
    storage.DatabaseError(msg) -> "Database error: " <> msg
    storage.NotFound -> "Token not found"
    storage.EncryptionError(msg) -> "Encryption error: " <> msg
  }
}
