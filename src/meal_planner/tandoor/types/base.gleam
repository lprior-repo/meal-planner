/// Shared base types for Tandoor API client
///
/// This module contains shared types used across the Tandoor API client implementation.
import gleam/option.{type Option, None}

// ============================================================================
// Types
// ============================================================================

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
///
/// This is the recommended method for Tandoor as it properly establishes
/// the space scope context required for multi-tenant operations.
///
/// # Arguments
/// * `base_url` - Base URL for Tandoor (e.g., "http://localhost:8000")
/// * `username` - Tandoor username
/// * `password` - Tandoor password
///
/// # Returns
/// ClientConfig with session auth (not yet authenticated)
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
///
/// Use this for OAuth2 tokens. Note: Token-based auth may not work with
/// Tandoor's multi-tenant scope system - prefer session_config for full
/// API access.
///
/// # Arguments
/// * `base_url` - Base URL for Tandoor (e.g., "http://localhost:8000")
/// * `token` - Bearer token (OAuth2 access token)
///
/// # Returns
/// ClientConfig with bearer auth
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
///
/// # Arguments
/// * `base_url` - Base URL for Tandoor (e.g., "http://localhost:8000")
/// * `api_token` - Bearer token for authentication
///
/// # Returns
/// ClientConfig with bearer auth
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
