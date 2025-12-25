/// Tandoor API client core types and configuration
///
/// This module provides the core types and configuration management for the
/// Tandoor API client. All other modules build upon these types.
import gleam/option.{type Option, None, Some}
import gleam/int

// ============================================================================
// Core Types
// ============================================================================

/// HTTP request method
pub type HttpMethod {
  Get
  Post
  Put
  Patch
  Delete
}

/// Tandoor API error type
pub type TandoorError {
  /// Authentication failed (401)
  AuthenticationError(message: String)
  /// Authorization failed (403)
  AuthorizationError(message: String)
  /// Resource not found (404)
  NotFoundError(resource: String)
  /// Request validation failed (400)
  BadRequestError(message: String)
  /// Server error (5xx)
  ServerError(status_code: Int, message: String)
  /// Network or connection error
  NetworkError(message: String)
  /// Timeout waiting for response
  TimeoutError
  /// Error parsing response JSON
  ParseError(message: String)
  /// Unknown error
  UnknownError(message: String)
}

/// Authentication method for Tandoor API
pub type AuthMethod {
  /// Session-based authentication (username/password -> session cookie)
  /// This is the recommended method as it properly establishes space scope
  SessionAuth(
    username: String,
    password: String,
    session_id: Option(String),
    csrf_token: Option(String),
  )
  /// Bearer token authentication (for OAuth2 tokens)
  BearerAuth(token: String)
}

/// HTTP client configuration
pub type ClientConfig {
  ClientConfig(
    /// Base URL for Tandoor API (e.g., "http://localhost:8000")
    base_url: String,
    /// Authentication method
    auth: AuthMethod,
    /// Request timeout in milliseconds
    timeout_ms: Int,
    /// Retry on transient failures
    retry_on_transient: Bool,
    /// Maximum retries for transient failures
    max_retries: Int,
  )
}

/// HTTP response from Tandoor API
pub type ApiResponse {
  ApiResponse(status: Int, headers: List(#(String, String)), body: String)
}

// ============================================================================
// Client Configuration
// ============================================================================

/// Create a client configuration with session-based authentication
pub fn session_config(
  base_url: String,
  username: String,
  password: String,
) -> ClientConfig {
  ClientConfig(
    base_url: base_url,
    auth: SessionAuth(
      username: username,
      password: password,
      session_id: None,
      csrf_token: None,
    ),
    timeout_ms: 10_000,
    retry_on_transient: True,
    max_retries: 3,
  )
}

/// Create a client configuration with Bearer token authentication
pub fn bearer_config(base_url: String, token: String) -> ClientConfig {
  ClientConfig(
    base_url: base_url,
    auth: BearerAuth(token: token),
    timeout_ms: 10_000,
    retry_on_transient: True,
    max_retries: 3,
  )
}

/// Create a default client configuration (deprecated - use session_config)
pub fn default_config(base_url: String, api_token: String) -> ClientConfig {
  bearer_config(base_url, api_token)
}

/// Create a client configuration with custom timeout
pub fn with_timeout(config: ClientConfig, timeout_ms: Int) -> ClientConfig {
  ClientConfig(
    base_url: config.base_url,
    auth: config.auth,
    timeout_ms: timeout_ms,
    retry_on_transient: config.retry_on_transient,
    max_retries: config.max_retries,
  )
}

/// Create a client configuration with retry settings
pub fn with_retry_config(
  config: ClientConfig,
  retry_on_transient: Bool,
  max_retries: Int,
) -> ClientConfig {
  ClientConfig(
    base_url: config.base_url,
    auth: config.auth,
    timeout_ms: config.timeout_ms,
    retry_on_transient: retry_on_transient,
    max_retries: max_retries,
  )
}

// ============================================================================
// Error Utilities
// ============================================================================

/// Check if error is retryable (transient failure)
pub fn is_transient_error(error: TandoorError) -> Bool {
  case error {
    NetworkError(_) | TimeoutError -> True
    ServerError(status, _) if status >= 500 && status < 600 -> True
    _ -> False
  }
}

/// Convert error to human-readable message
pub fn error_to_string(error: TandoorError) -> String {
  case error {
    AuthenticationError(msg) -> "Authentication error: " <> msg
    AuthorizationError(msg) -> "Authorization error: " <> msg
    NotFoundError(resource) -> "Resource not found: " <> resource
    BadRequestError(msg) -> "Bad request: " <> msg
    ServerError(status, msg) ->
      "Server error " <> int.to_string(status) <> ": " <> msg
    NetworkError(msg) -> "Network error: " <> msg
    TimeoutError -> "Request timeout"
    ParseError(msg) -> "Parse error: " <> msg
    UnknownError(msg) -> "Unknown error: " <> msg
  }
}

// ============================================================================
// Authentication Utilities
// ============================================================================

/// Check if config has an active session
pub fn is_authenticated(config: ClientConfig) -> Bool {
  case config.auth {
    BearerAuth(_) -> True
    SessionAuth(_, _, session_id, _) -> option.is_some(session_id)
  }
}

/// Update config with session tokens after login
pub fn with_session(
  config: ClientConfig,
  session_id: String,
  csrf_token: String,
) -> ClientConfig {
  case config.auth {
    SessionAuth(username, password, _, _) ->
      ClientConfig(
        base_url: config.base_url,
        auth: SessionAuth(
          username: username,
          password: password,
          session_id: Some(session_id),
          csrf_token: Some(csrf_token),
        ),
        timeout_ms: config.timeout_ms,
        retry_on_transient: config.retry_on_transient,
        max_retries: config.max_retries,
      )
    BearerAuth(_) -> config
  }
}
