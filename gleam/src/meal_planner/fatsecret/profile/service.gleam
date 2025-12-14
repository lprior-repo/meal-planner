/// FatSecret Profile Service Layer - Automatic token management
///
/// High-level API for profile operations with automatic OAuth handling.
/// Loads stored tokens from database and handles authentication errors.
import gleam/option.{type Option}
import meal_planner/env.{
  type FatSecretConfig as EnvFatSecretConfig,
  load_fatsecret_config as load_env_fatsecret_config,
}
import meal_planner/fatsecret/core/config.{
  type FatSecretConfig as CoreFatSecretConfig, FatSecretConfig,
}
import meal_planner/fatsecret/core/errors
import meal_planner/fatsecret/core/oauth.{type AccessToken, AccessToken}
import meal_planner/fatsecret/profile/client as profile_client
import meal_planner/fatsecret/profile/types.{type Profile, type ProfileAuth}
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
  ApiError(inner: errors.FatSecretError)
  StorageError(message: String)
}

// ============================================================================
// Profile Data (3-legged)
// ============================================================================

/// Get user's profile information with automatic token handling
///
/// Parameters:
/// - conn: Database connection
///
/// Returns:
/// - Ok(Profile) with user's profile data
/// - Error(ServiceError) on failure
pub fn get_profile(conn: pog.Connection) -> Result(Profile, ServiceError) {
  case load_env_fatsecret_config() {
    option.None -> Error(NotConfigured)
    option.Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            profile_client.get_profile(
              FatSecretConfig(
                consumer_key: config.consumer_key,
                consumer_secret: config.consumer_secret,
                api_host: option.None,
                auth_host: option.None,
              ),
              token,
            )
          {
            Ok(profile) -> {
              let _ = storage.touch_access_token(conn)
              Ok(profile)
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
// Profile Management (3-legged)
// ============================================================================

/// Create a new profile for a user with automatic token handling
///
/// Parameters:
/// - conn: Database connection
/// - user_id: Your application's unique user identifier
///
/// Returns:
/// - Ok(ProfileAuth) with oauth credentials
/// - Error(ServiceError) on failure
pub fn create_profile(
  conn: pog.Connection,
  user_id: String,
) -> Result(ProfileAuth, ServiceError) {
  case load_env_fatsecret_config() {
    option.None -> Error(NotConfigured)
    option.Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            profile_client.create_profile(
              FatSecretConfig(
                consumer_key: config.consumer_key,
                consumer_secret: config.consumer_secret,
                api_host: option.None,
                auth_host: option.None,
              ),
              token,
              user_id,
            )
          {
            Ok(auth) -> {
              let _ = storage.touch_access_token(conn)
              Ok(auth)
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

/// Get profile authentication credentials for a user with automatic token handling
///
/// Parameters:
/// - conn: Database connection
/// - user_id: Your application's unique user identifier
///
/// Returns:
/// - Ok(ProfileAuth) with oauth credentials
/// - Error(ServiceError) on failure
pub fn get_profile_auth(
  conn: pog.Connection,
  user_id: String,
) -> Result(ProfileAuth, ServiceError) {
  case load_env_fatsecret_config() {
    option.None -> Error(NotConfigured)
    option.Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            profile_client.get_profile_auth(
              FatSecretConfig(
                consumer_key: config.consumer_key,
                consumer_secret: config.consumer_secret,
                api_host: option.None,
                auth_host: option.None,
              ),
              token,
              user_id,
            )
          {
            Ok(auth) -> {
              let _ = storage.touch_access_token(conn)
              Ok(auth)
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
    ApiError(inner) -> errors.error_to_string(inner)
  }
}
