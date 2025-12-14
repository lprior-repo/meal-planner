/// FatSecret Profile Service - Manage user profile OAuth connections
///
/// This module provides high-level operations for managing FatSecret profile connections:
/// - Check connection status (connected, disconnected, config missing)
/// - Start OAuth connection flow (returns authorization URL)
/// - Complete OAuth connection (exchanges verifier for access token)
/// - Disconnect (revoke and delete tokens)
/// - Get profile data (fetch user profile from FatSecret API)
/// - Validate connection (test if stored token is still valid)
import gleam/option.{type Option, None, Some}
import meal_planner/env
import meal_planner/fatsecret/client
import meal_planner/fatsecret/storage
import pog

/// Profile data returned from FatSecret API
pub type Profile {
  Profile(user_id: String, profile_json: String)
}

/// Service-level errors with clear categorization
pub type ServiceError {
  NotConfigured
  NotConnected
  AuthRevoked
  TokenExpired
  InvalidVerifier
  ApiError(inner: client.FatSecretError)
  StorageError(message: String)
  EncryptionError(message: String)
}

/// Connection status with detailed state information
pub type ConnectionStatus {
  Connected(profile: Option(Profile))
  Disconnected(reason: String)
  ConfigMissing
  EncryptionKeyMissing
}

/// Check if FatSecret is configured and connected
/// Returns current connection status without making API calls
pub fn check_status(conn: pog.Connection) -> ConnectionStatus {
  case env.load_fatsecret_config() {
    None -> ConfigMissing
    Some(_config) -> {
      case storage.encryption_configured() {
        False -> EncryptionKeyMissing
        True -> {
          case storage.get_access_token(conn) {
            Ok(_token) -> Connected(profile: None)
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

/// Start the OAuth connection flow
/// Returns the authorization URL for the user to visit
/// The request token is stored in the database for later verification
pub fn start_connect(
  conn: pog.Connection,
  callback_url: String,
) -> Result(String, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      case storage.encryption_configured() {
        False ->
          Error(EncryptionError(
            "OAUTH_ENCRYPTION_KEY not set. Generate one with: openssl rand -hex 32",
          ))
        True -> {
          use request_token <- result_try(
            client.get_request_token(config, callback_url)
            |> result.map_error(ApiError),
          )

          use _nil <- result_try(
            storage.store_pending_token(conn, request_token)
            |> result.map_error(storage_error_to_service_error),
          )

          let auth_url = client.get_authorization_url(request_token)
          Ok(auth_url)
        }
      }
    }
  }
}

/// Complete the OAuth connection flow
/// Exchanges the oauth_verifier for an access token
/// Returns the user's profile data on success
pub fn complete_connect(
  conn: pog.Connection,
  oauth_token: String,
  oauth_verifier: String,
) -> Result(Profile, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      use token_secret <- result_try(
        storage.get_pending_token(conn, oauth_token)
        |> result.map_error(fn(e) {
          case e {
            storage.NotFound -> InvalidVerifier
            other -> storage_error_to_service_error(other)
          }
        }),
      )

      let request_token =
        client.RequestToken(
          oauth_token:,
          oauth_token_secret: token_secret,
          oauth_callback_confirmed: True,
        )

      use access_token <- result_try(
        client.get_access_token(config, request_token, oauth_verifier)
        |> result.map_error(ApiError),
      )

      use _nil <- result_try(
        storage.store_access_token(conn, access_token)
        |> result.map_error(storage_error_to_service_error),
      )

      // Fetch profile to confirm connection works
      get_profile(conn)
    }
  }
}

/// Disconnect from FatSecret
/// Removes the stored access token
pub fn disconnect(conn: pog.Connection) -> Result(Nil, ServiceError) {
  storage.delete_access_token(conn)
  |> result.map_error(storage_error_to_service_error)
}

/// Get the user's FatSecret profile
/// Makes an authenticated API call to fetch profile data
pub fn get_profile(conn: pog.Connection) -> Result(Profile, ServiceError) {
  case env.load_fatsecret_config() {
    None -> Error(NotConfigured)
    Some(config) -> {
      use token <- result_try(get_token(conn))

      use profile_json <- result_try(
        client.get_profile(config, token)
        |> result.map_error(fn(e) {
          case e {
            client.RequestFailed(status: 401, body: _) -> AuthRevoked
            client.RequestFailed(status: 403, body: _) -> AuthRevoked
            client.ApiError(code: "6", message: _) -> TokenExpired
            other -> ApiError(other)
          }
        }),
      )

      let _ = storage.touch_access_token(conn)

      // For now, we just return the JSON string
      // In a production app, you'd parse this to extract user_id
      Ok(Profile(user_id: "unknown", profile_json:))
    }
  }
}

/// Validate the stored token by making a test API call
/// Returns True if the token is valid, False if revoked/expired
pub fn validate_connection(conn: pog.Connection) -> Result(Bool, ServiceError) {
  case get_profile(conn) {
    Ok(_) -> Ok(True)
    Error(AuthRevoked) -> Ok(False)
    Error(TokenExpired) -> Ok(False)
    Error(e) -> Error(e)
  }
}

// =============================================================================
// Internal Helpers
// =============================================================================

/// Get the stored access token from database
fn get_token(conn: pog.Connection) -> Result(client.AccessToken, ServiceError) {
  case storage.encryption_configured() {
    False ->
      Error(EncryptionError(
        "OAUTH_ENCRYPTION_KEY not set. Generate one with: openssl rand -hex 32",
      ))
    True -> {
      case storage.get_access_token(conn) {
        Ok(token) -> Ok(token)
        Error(storage.NotFound) -> Error(NotConnected)
        Error(e) -> Error(storage_error_to_service_error(e))
      }
    }
  }
}

/// Convert storage error to service error
fn storage_error_to_service_error(error: storage.StorageError) -> ServiceError {
  case error {
    storage.DatabaseError(msg) -> StorageError(msg)
    storage.NotFound -> NotConnected
    storage.EncryptionError(msg) -> EncryptionError(msg)
  }
}

/// Result try helper (since we can't use use <- in all contexts)
fn result_try(result: Result(a, e), next: fn(a) -> Result(b, e)) -> Result(b, e) {
  case result {
    Ok(value) -> next(value)
    Error(error) -> Error(error)
  }
}
