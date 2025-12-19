/// CLI OAuth device flow authentication
///
/// This module handles FatSecret OAuth authentication for the CLI application.
/// Tokens are stored in ~/.meal-planner/token.json with AES-256-GCM encryption.
///
/// OAuth Device Flow:
/// 1. start_oauth_device_flow() - Initiate auth, get request token
/// 2. User visits authorization URL and approves
/// 3. poll_for_token() - Poll until user authorizes (or timeout)
/// 4. save_token() - Save access token to encrypted file
/// 5. load_token() - Load token for API calls
/// 6. is_authenticated() - Check if valid token exists
///
/// Security:
/// - Never log tokens or secrets
/// - Tokens encrypted at rest using AES-256-GCM
/// - Encryption key from OAUTH_ENCRYPTION_KEY env var
import gleam/bit_array
import gleam/crypto
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/fatsecret/core/config.{type FatSecretConfig}
import meal_planner/fatsecret/core/errors.{type FatSecretError}
import meal_planner/fatsecret/core/oauth.{type AccessToken, type RequestToken}
import meal_planner/fatsecret/crypto
import meal_planner/fatsecret/profile/oauth as profile_oauth
import simplifile

// ============================================================================
// Types
// ============================================================================

/// Token storage format for CLI (file-based)
pub type TokenStorage {
  TokenStorage(oauth_token: String, oauth_token_secret: String)
}

/// Errors that can occur during CLI auth operations
pub type AuthError {
  FileError(message: String)
  EncryptionError(message: String)
  OAuthError(error: FatSecretError)
  TokenNotFound
  InvalidToken
}

/// Device flow state for polling
pub type DeviceFlowState {
  DeviceFlowState(
    request_token: RequestToken,
    authorization_url: String,
    poll_interval_seconds: Int,
  )
}

// ============================================================================
// OAuth Device Flow - Step 1: Initiate
// ============================================================================

/// Start OAuth device flow
///
/// Initiates the 3-legged OAuth flow for CLI applications.
/// Returns a DeviceFlowState with authorization URL for the user.
///
/// Usage:
/// ```gleam
/// let assert Ok(flow_state) = start_oauth_device_flow(config)
/// io.println("Visit: " <> flow_state.authorization_url)
/// ```
pub fn start_oauth_device_flow(
  config: FatSecretConfig,
) -> Result(DeviceFlowState, AuthError) {
  // Get request token (Step 1 of OAuth 1.0a)
  use request_token <- result.try(
    profile_oauth.get_request_token(config, "oob")
    |> result.map_error(OAuthError),
  )

  // Build authorization URL (Step 2)
  let authorization_url =
    profile_oauth.get_authorization_url(config, request_token)

  Ok(DeviceFlowState(
    request_token: request_token,
    authorization_url: authorization_url,
    poll_interval_seconds: 5,
  ))
}

// ============================================================================
// OAuth Device Flow - Step 2: Poll for Authorization
// ============================================================================

/// Poll for user authorization
///
/// After user visits authorization URL and approves, exchange the
/// request token + verifier for an access token.
///
/// Usage:
/// ```gleam
/// let verifier = "user_entered_verifier_code"
/// let assert Ok(access_token) = poll_for_token(config, flow_state, verifier)
/// ```
pub fn poll_for_token(
  config: FatSecretConfig,
  flow_state: DeviceFlowState,
  oauth_verifier: String,
) -> Result(AccessToken, AuthError) {
  profile_oauth.get_access_token(
    config,
    flow_state.request_token,
    oauth_verifier,
  )
  |> result.map_error(OAuthError)
}

// ============================================================================
// Token Storage - Save
// ============================================================================

/// Save access token to encrypted file
///
/// Writes the token to ~/.meal-planner/token.json (or custom directory).
/// The token is encrypted using AES-256-GCM before writing.
///
/// Parameters:
/// - token: AccessToken to save
/// - base_dir: Optional base directory (defaults to ~/.meal-planner)
///
/// Usage:
/// ```gleam
/// let assert Ok(_) = save_token(access_token, None)
/// ```
pub fn save_token(
  token: TokenStorage,
  base_dir: String,
) -> Result(Nil, AuthError) {
  // Ensure directory exists
  use _ <- result.try(
    simplifile.create_directory_all(base_dir)
    |> result.map_error(fn(e) { FileError(simplifile_error_to_string(e)) }),
  )

  // Convert token to JSON
  let token_json =
    json.object([
      #("oauth_token", json.string(token.oauth_token)),
      #("oauth_token_secret", json.string(token.oauth_token_secret)),
    ])
    |> json.to_string

  // Encrypt the JSON
  use encrypted <- result.try(
    crypto.encrypt(token_json)
    |> result.map_error(fn(e) { EncryptionError(crypto_error_to_string(e)) }),
  )

  // Write to file
  let token_path = base_dir <> "/token.json"
  simplifile.write(token_path, encrypted)
  |> result.map_error(fn(e) { FileError(simplifile_error_to_string(e)) })
}

// ============================================================================
// Token Storage - Load
// ============================================================================

/// Load access token from encrypted file
///
/// Reads and decrypts the token from ~/.meal-planner/token.json.
///
/// Parameters:
/// - base_dir: Optional base directory (defaults to ~/.meal-planner)
///
/// Usage:
/// ```gleam
/// let assert Ok(token) = load_token(None)
/// ```
pub fn load_token(base_dir: String) -> Result(TokenStorage, AuthError) {
  let token_path = base_dir <> "/token.json"

  // Read encrypted file
  use encrypted <- result.try(
    simplifile.read(token_path)
    |> result.map_error(fn(e) {
      case e {
        simplifile.Enoent -> TokenNotFound
        _ -> FileError(simplifile_error_to_string(e))
      }
    }),
  )

  // Decrypt
  use decrypted <- result.try(
    crypto.decrypt(encrypted)
    |> result.map_error(fn(e) { EncryptionError(crypto_error_to_string(e)) }),
  )

  // Parse JSON
  let decoder = {
    use oauth_token <- decode.field("oauth_token", decode.string)
    use oauth_token_secret <- decode.field("oauth_token_secret", decode.string)
    decode.success(TokenStorage(
      oauth_token: oauth_token,
      oauth_token_secret: oauth_token_secret,
    ))
  }

  json.parse(from: decrypted, using: decoder)
  |> result.map_error(fn(_) { InvalidToken })
}

// ============================================================================
// Token Validation
// ============================================================================

/// Check if user is authenticated
///
/// Returns True if a valid token file exists and can be decrypted.
///
/// Parameters:
/// - base_dir: Optional base directory (defaults to ~/.meal-planner)
///
/// Usage:
/// ```gleam
/// case is_authenticated(None) {
///   True -> io.println("Already authenticated")
///   False -> io.println("Need to authenticate")
/// }
/// ```
pub fn is_authenticated(base_dir: String) -> Bool {
  case load_token(base_dir) {
    Ok(_) -> True
    Error(_) -> False
  }
}

/// Refresh access token
///
/// Note: FatSecret OAuth 1.0a tokens do not expire, so this is a no-op.
/// Included for API compatibility with OAuth 2.0 flows.
pub fn refresh_token(
  _config: FatSecretConfig,
  token: TokenStorage,
) -> Result(TokenStorage, AuthError) {
  // OAuth 1.0a tokens don't expire
  Ok(token)
}

// ============================================================================
// Helpers
// ============================================================================

/// Generate a unique test ID for testing
pub fn generate_test_id() -> String {
  crypto.strong_random_bytes(8)
  |> bit_array.base16_encode
  |> string.lowercase
}

/// Convert simplifile error to string
fn simplifile_error_to_string(error: simplifile.FileError) -> String {
  case error {
    simplifile.Eacces -> "Permission denied"
    simplifile.Eagain -> "Resource temporarily unavailable"
    simplifile.Ebadf -> "Bad file descriptor"
    simplifile.Ebadmsg -> "Bad message"
    simplifile.Ebusy -> "Resource busy"
    simplifile.Edeadlk -> "Resource deadlock avoided"
    simplifile.Edeadlock -> "Resource deadlock"
    simplifile.Edquot -> "Disk quota exceeded"
    simplifile.Eexist -> "File exists"
    simplifile.Efault -> "Bad address"
    simplifile.Efbig -> "File too large"
    simplifile.Eftype -> "Inappropriate file type"
    simplifile.Eintr -> "Interrupted system call"
    simplifile.Einval -> "Invalid argument"
    simplifile.Eio -> "I/O error"
    simplifile.Eisdir -> "Is a directory"
    simplifile.Eloop -> "Too many symbolic links"
    simplifile.Emfile -> "Too many open files"
    simplifile.Emlink -> "Too many links"
    simplifile.Emultihop -> "Multihop attempted"
    simplifile.Enametoolong -> "File name too long"
    simplifile.Enfile -> "Too many open files in system"
    simplifile.Enobufs -> "No buffer space available"
    simplifile.Enodev -> "No such device"
    simplifile.Enolck -> "No locks available"
    simplifile.Enolink -> "Link has been severed"
    simplifile.Enoent -> "No such file or directory"
    simplifile.Enomem -> "Not enough memory"
    simplifile.Enospc -> "No space left on device"
    simplifile.Enosr -> "No stream resources"
    simplifile.Enostr -> "Not a stream"
    simplifile.Enosys -> "Function not implemented"
    simplifile.Enotblk -> "Block device required"
    simplifile.Enotdir -> "Not a directory"
    simplifile.Enotsup -> "Operation not supported"
    simplifile.Enxio -> "No such device or address"
    simplifile.Eopnotsupp -> "Operation not supported on socket"
    simplifile.Eoverflow -> "Value too large"
    simplifile.Eperm -> "Operation not permitted"
    simplifile.Epipe -> "Broken pipe"
    simplifile.Erange -> "Result too large"
    simplifile.Erofs -> "Read-only file system"
    simplifile.Espipe -> "Invalid seek"
    simplifile.Esrch -> "No such process"
    simplifile.Estale -> "Stale file handle"
    simplifile.Etxtbsy -> "Text file busy"
    simplifile.Exdev -> "Cross-device link"
    simplifile.NotUtf8 -> "File content is not valid UTF-8"
    simplifile.Unknown(msg) -> "Unknown error: " <> msg
  }
}

/// Convert crypto error to string
fn crypto_error_to_string(error: crypto.CryptoError) -> String {
  case error {
    crypto.KeyNotConfigured -> "OAUTH_ENCRYPTION_KEY not set"
    crypto.KeyInvalidLength ->
      "OAUTH_ENCRYPTION_KEY must be 64 hex chars (32 bytes)"
    crypto.EncryptionFailed -> "Encryption failed"
    crypto.DecryptionFailed -> "Decryption failed"
    crypto.InvalidCiphertext -> "Invalid ciphertext"
  }
}
