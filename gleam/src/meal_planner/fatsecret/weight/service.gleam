/// FatSecret Weight Service Layer - Automatic token management
///
/// High-level API for weight operations with automatic OAuth handling.
/// Loads stored tokens from database and handles authentication errors.
import gleam/option.{type Option}
import meal_planner/env.{
  type FatSecretConfig as EnvFatSecretConfig,
  load_fatsecret_config as load_env_fatsecret_config,
}
import meal_planner/fatsecret/core/config.{
  type FatSecretConfig as CoreFatSecretConfig, FatSecretConfig,
}
import meal_planner/fatsecret/core/errors.{
  type ApiErrorCode, type FatSecretError, WeightDateEarlier, WeightDateTooFar,
}
import meal_planner/fatsecret/core/oauth.{type AccessToken, AccessToken}
import meal_planner/fatsecret/storage
import meal_planner/fatsecret/weight/client as weight_client
import meal_planner/fatsecret/weight/types.{
  type WeightMonthSummary, type WeightUpdate,
}
import pog

// ============================================================================
// Service Error Type
// ============================================================================

/// Service-level errors with user-friendly messages
pub type ServiceError {
  NotConfigured
  NotConnected
  AuthRevoked
  /// Date is more than 2 days from today
  DateTooFar
  /// Cannot update date earlier than existing weight entry
  DateEarlierThanExisting
  ApiError(inner: FatSecretError)
  StorageError(message: String)
}

// ============================================================================
// Weight Update (3-legged)
// ============================================================================

/// Update weight measurement with automatic token handling
///
/// Parameters:
/// - conn: Database connection
/// - update: Weight update data
///
/// Returns:
/// - Ok(Nil) on success
/// - Error(DateTooFar) if date is more than 2 days from today (API error 205)
/// - Error(DateEarlierThanExisting) if updating earlier date (API error 206)
/// - Error(NotConfigured/NotConnected/AuthRevoked) for auth issues
/// - Error(ApiError) for other API failures
pub fn update_weight(
  conn: pog.Connection,
  update: WeightUpdate,
) -> Result(Nil, ServiceError) {
  case load_env_fatsecret_config() {
    option.None -> Error(NotConfigured)
    option.Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            weight_client.update_weight(
              FatSecretConfig(
                consumer_key: config.consumer_key,
                consumer_secret: config.consumer_secret,
                api_host: option.None,
                auth_host: option.None,
              ),
              token,
              update,
            )
          {
            Ok(nil) -> {
              let _ = storage.touch_access_token(conn)
              Ok(nil)
            }
            // Map specific weight API errors
            Error(errors.ApiError(code, message)) -> {
              case code {
                WeightDateTooFar -> Error(DateTooFar)
                WeightDateEarlier -> Error(DateEarlierThanExisting)
                _ -> Error(ApiError(errors.ApiError(code, message)))
              }
            }
            // Auth errors
            Error(errors.RequestFailed(status: 401, body: _)) ->
              Error(AuthRevoked)
            Error(errors.RequestFailed(status: 403, body: _)) ->
              Error(AuthRevoked)
            // Generic errors
            Error(e) -> Error(ApiError(e))
          }
        }
      }
    }
  }
}

// ============================================================================
// Weight Month Summary (3-legged)
// ============================================================================

/// Get weight measurements for a month with automatic token handling
///
/// Parameters:
/// - conn: Database connection
/// - date_int: Any date within the desired month
///
/// Returns:
/// - Ok(WeightMonthSummary) with all measurements
/// - Error(ServiceError) on failure
pub fn get_weight_month_summary(
  conn: pog.Connection,
  date_int: Int,
) -> Result(WeightMonthSummary, ServiceError) {
  case load_env_fatsecret_config() {
    option.None -> Error(NotConfigured)
    option.Some(config) -> {
      case get_token(conn) {
        Error(e) -> Error(e)
        Ok(token) -> {
          case
            weight_client.get_weight_month_summary(
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
    DateTooFar -> "Weight date must be within 2 days of today"
    DateEarlierThanExisting ->
      "Cannot update a date earlier than existing weight entries"
    StorageError(msg) -> "Storage error: " <> msg
    ApiError(inner) -> errors.error_to_string(inner)
  }
}

/// Check if error is a date validation error (should be 400 Bad Request)
pub fn is_date_validation_error(error: ServiceError) -> Bool {
  case error {
    DateTooFar -> True
    DateEarlierThanExisting -> True
    _ -> False
  }
}
