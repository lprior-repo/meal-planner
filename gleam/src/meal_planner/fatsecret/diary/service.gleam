/// FatSecret Diary Service Layer - Automatic token management
///
/// High-level API for food diary operations with automatic OAuth handling.
/// Loads stored tokens from database and handles authentication errors.
import gleam/option
import meal_planner/env.{load_fatsecret_config as load_env_fatsecret_config}
import meal_planner/fatsecret/core/config.{FatSecretConfig}
import meal_planner/fatsecret/core/errors.{type FatSecretError}
import meal_planner/fatsecret/core/errors as core_errors
import meal_planner/fatsecret/core/oauth.{type AccessToken, AccessToken}
import meal_planner/fatsecret/diary/client as diary_client
import meal_planner/fatsecret/diary/types.{
  type FoodEntry, type FoodEntryId, type FoodEntryInput, type FoodEntryUpdate,
  type MonthSummary,
}
import meal_planner/fatsecret/storage
import pog

// ============================================================================
// Service Error Type
// ============================================================================

/// Service-level errors with user-friendly messages
pub type ServiceError {
  NotConfigured
  NotConnected
  AuthRevoked
  ApiError(inner: FatSecretError)
  StorageError(message: String)
}

// ============================================================================
// Create Food Entry
// ============================================================================

/// Create a new food diary entry with automatic token handling
///
/// Parameters:
/// - conn: Database connection
/// - input: FoodEntryInput specifying either FromFood or Custom entry
///
/// Returns:
/// - Ok(FoodEntryId) on success
/// - Error(NotConfigured/NotConnected/AuthRevoked) for auth issues
/// - Error(ApiError) for other API failures
pub fn create_food_entry(
  conn: pog.Connection,
  input: FoodEntryInput,
) -> Result(FoodEntryId, ServiceError) {
  case load_env_fatsecret_config() {
    option.None -> Error(NotConfigured)
    option.Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            diary_client.create_food_entry(
              FatSecretConfig(
                consumer_key: config.consumer_key,
                consumer_secret: config.consumer_secret,
                api_host: option.None,
                auth_host: option.None,
              ),
              token,
              input,
            )
          {
            Ok(entry_id) -> {
              let _ = storage.touch_access_token(conn)
              Ok(entry_id)
            }
            Error(errors.RequestFailed(status: 401, body: _)) ->
              Error(AuthRevoked)
            Error(errors.RequestFailed(status: 403, body: _)) ->
              Error(AuthRevoked)
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

// ============================================================================
// Get Single Food Entry
// ============================================================================

/// Get a specific food entry by ID with automatic token handling
///
/// Parameters:
/// - conn: Database connection
/// - entry_id: The ID of the entry to retrieve
///
/// Returns:
/// - Ok(FoodEntry) with complete details
/// - Error(ServiceError) on failure
pub fn get_food_entry(
  conn: pog.Connection,
  entry_id: FoodEntryId,
) -> Result(FoodEntry, ServiceError) {
  case load_env_fatsecret_config() {
    option.None -> Error(NotConfigured)
    option.Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            diary_client.get_food_entry(
              FatSecretConfig(
                consumer_key: config.consumer_key,
                consumer_secret: config.consumer_secret,
                api_host: option.None,
                auth_host: option.None,
              ),
              token,
              entry_id,
            )
          {
            Ok(entry) -> {
              let _ = storage.touch_access_token(conn)
              Ok(entry)
            }
            Error(errors.RequestFailed(status: 401, body: _)) ->
              Error(AuthRevoked)
            Error(errors.RequestFailed(status: 403, body: _)) ->
              Error(AuthRevoked)
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

// ============================================================================
// Update Food Entry
// ============================================================================

/// Update an existing food entry with automatic token handling
///
/// Parameters:
/// - conn: Database connection
/// - entry_id: The ID of the entry to update
/// - update: FoodEntryUpdate with fields to change
///
/// Returns:
/// - Ok(Nil) on success
/// - Error(ServiceError) on failure
pub fn update_food_entry(
  conn: pog.Connection,
  entry_id: FoodEntryId,
  update: FoodEntryUpdate,
) -> Result(Nil, ServiceError) {
  case load_env_fatsecret_config() {
    option.None -> Error(NotConfigured)
    option.Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            diary_client.edit_food_entry(
              FatSecretConfig(
                consumer_key: config.consumer_key,
                consumer_secret: config.consumer_secret,
                api_host: option.None,
                auth_host: option.None,
              ),
              token,
              entry_id,
              update,
            )
          {
            Ok(nil) -> {
              let _ = storage.touch_access_token(conn)
              Ok(nil)
            }
            Error(errors.RequestFailed(status: 401, body: _)) ->
              Error(AuthRevoked)
            Error(errors.RequestFailed(status: 403, body: _)) ->
              Error(AuthRevoked)
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

// ============================================================================
// Delete Food Entry
// ============================================================================

/// Delete a food entry with automatic token handling
///
/// Parameters:
/// - conn: Database connection
/// - entry_id: The ID of the entry to delete
///
/// Returns:
/// - Ok(Nil) on success
/// - Error(ServiceError) on failure
pub fn delete_food_entry(
  conn: pog.Connection,
  entry_id: FoodEntryId,
) -> Result(Nil, ServiceError) {
  case load_env_fatsecret_config() {
    option.None -> Error(NotConfigured)
    option.Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            diary_client.delete_food_entry(
              FatSecretConfig(
                consumer_key: config.consumer_key,
                consumer_secret: config.consumer_secret,
                api_host: option.None,
                auth_host: option.None,
              ),
              token,
              entry_id,
            )
          {
            Ok(nil) -> {
              let _ = storage.touch_access_token(conn)
              Ok(nil)
            }
            Error(errors.RequestFailed(status: 401, body: _)) ->
              Error(AuthRevoked)
            Error(errors.RequestFailed(status: 403, body: _)) ->
              Error(AuthRevoked)
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

// ============================================================================
// Get Day Summary (All Entries for Date)
// ============================================================================

/// Get all food entries for a specific date with automatic token handling
///
/// Parameters:
/// - conn: Database connection
/// - date_int: Date as days since Unix epoch
///
/// Returns:
/// - Ok(List(FoodEntry)) with all entries for the date
/// - Error(ServiceError) on failure
pub fn get_day_entries(
  conn: pog.Connection,
  date_int: Int,
) -> Result(List(FoodEntry), ServiceError) {
  case load_env_fatsecret_config() {
    option.None -> Error(NotConfigured)
    option.Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            diary_client.get_food_entries(
              FatSecretConfig(
                consumer_key: config.consumer_key,
                consumer_secret: config.consumer_secret,
                api_host: option.None,
                auth_host: option.None,
              ),
              token,
              date_int,
            )
          {
            Ok(entries) -> {
              let _ = storage.touch_access_token(conn)
              Ok(entries)
            }
            Error(errors.RequestFailed(status: 401, body: _)) ->
              Error(AuthRevoked)
            Error(errors.RequestFailed(status: 403, body: _)) ->
              Error(AuthRevoked)
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

// ============================================================================
// Get Month Summary
// ============================================================================

/// Get monthly nutrition summary with automatic token handling
///
/// Parameters:
/// - conn: Database connection
/// - date_int: Any date within the desired month
///
/// Returns:
/// - Ok(MonthSummary) with daily aggregates
/// - Error(ServiceError) on failure
pub fn get_month_summary(
  conn: pog.Connection,
  date_int: Int,
) -> Result(MonthSummary, ServiceError) {
  case load_env_fatsecret_config() {
    option.None -> Error(NotConfigured)
    option.Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            diary_client.get_month_summary(
              FatSecretConfig(
                consumer_key: config.consumer_key,
                consumer_secret: config.consumer_secret,
                api_host: option.None,
                auth_host: option.None,
              ),
              token,
              date_int,
            )
          {
            Ok(summary) -> {
              let _ = storage.touch_access_token(conn)
              Ok(summary)
            }
            Error(errors.RequestFailed(status: 401, body: _)) ->
              Error(AuthRevoked)
            Error(errors.RequestFailed(status: 403, body: _)) ->
              Error(AuthRevoked)
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

/// Get stored access token with error mapping
/// Note: Converts from storage.AccessToken to core/oauth.AccessToken
fn get_token(conn: pog.Connection) -> Result(AccessToken, ServiceError) {
  case storage.encryption_configured() {
    False -> Error(StorageError("OAUTH_ENCRYPTION_KEY not set"))
    True -> {
      case storage.get_access_token(conn) {
        Ok(token) ->
          Ok(AccessToken(
            oauth_token: token.oauth_token,
            oauth_token_secret: token.oauth_token_secret,
          ))
        Error(storage.NotFound) -> Error(NotConnected)
        Error(storage.EncryptionError(msg)) -> Error(StorageError(msg))
        Error(storage.DatabaseError(msg)) -> Error(StorageError(msg))
      }
    }
  }
}

/// Convert service error to HTTP-friendly message
pub fn error_to_message(error: ServiceError) -> String {
  case error {
    NotConfigured -> "FatSecret API not configured"
    NotConnected -> "Not connected to FatSecret. Please authorize first."
    AuthRevoked -> "FatSecret authorization was revoked. Please reconnect."
    StorageError(msg) -> "Storage error: " <> msg
    ApiError(inner) -> core_errors.error_to_string(inner)
  }
}
