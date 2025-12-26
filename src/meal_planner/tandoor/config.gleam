/// Tandoor Client Configuration Module
///
/// Provides configuration types and builder functions for Tandoor API clients.
/// This module exists to break circular dependencies between client and other modules.
///
/// Configuration Types:
/// - ClientConfig: Main configuration for Tandoor API client
/// - AuthType: Authentication method (Bearer or Session)
/// - BearerAuth: Bearer token authentication
/// - SessionAuth: Django session authentication
///
/// This module is intentionally kept minimal to avoid dependencies.
import gleam/option.{type Option}

// ============================================================================
// Authentication Types
// ============================================================================

/// Authentication method for Tandoor API
pub type AuthType {
  BearerAuth(token: String)
  SessionAuth(session_id: String, csrf_token: String)
}

// ============================================================================
// Client Configuration
// ============================================================================

/// Configuration for Tandoor API client
///
/// Fields:
/// - base_url: Tandoor server URL (e.g., "http://localhost:8000")
/// - auth: Authentication method (Bearer token or Session)
/// - timeout_ms: Request timeout in milliseconds (default: 10000)
/// - retry_on_transient: Whether to retry transient errors (default: True)
pub type ClientConfig {
  ClientConfig(
    base_url: String,
    auth: AuthType,
    timeout_ms: Int,
    retry_on_transient: Bool,
  )
}

// ============================================================================
// Configuration Builders
// ============================================================================

/// Create client configuration with Bearer token authentication
///
/// Arguments:
/// - base_url: Tandoor server URL
/// - token: Bearer authentication token
///
/// Returns:
/// - ClientConfig ready for API calls
///
/// Example:
/// ```gleam
/// let config = bearer_config("http://localhost:8000", "my-token")
/// ```
pub fn bearer_config(base_url: String, token: String) -> ClientConfig {
  ClientConfig(
    base_url: base_url,
    auth: BearerAuth(token: token),
    timeout_ms: 10_000,
    retry_on_transient: True,
  )
}

/// Create client configuration with Django session authentication
///
/// Arguments:
/// - base_url: Tandoor server URL
/// - session_id: Django session cookie value
/// - csrf_token: CSRF middleware token from login page
///
/// Returns:
/// - ClientConfig ready for API calls
///
/// Example:
/// ```gleam
/// let config = session_config("http://localhost:8000", "session123", "csrf456")
/// ```
pub fn session_config(
  base_url: String,
  session_id: String,
  csrf_token: String,
) -> ClientConfig {
  ClientConfig(
    base_url: base_url,
    auth: SessionAuth(session_id: session_id, csrf_token: csrf_token),
    timeout_ms: 10_000,
    retry_on_transient: True,
  )
}

/// Update authentication method in existing configuration
///
/// Arguments:
/// - config: Existing ClientConfig
/// - auth: New AuthType to use
///
/// Returns:
/// - Updated ClientConfig with new authentication
///
/// Example:
/// ```gleam
/// let old_config = bearer_config("http://localhost:8000", "old-token")
/// let new_config = update_auth(old_config, BearerAuth("new-token"))
/// ```
pub fn update_auth(config: ClientConfig, auth: AuthType) -> ClientConfig {
  ClientConfig(
    base_url: config.base_url,
    auth: auth,
    timeout_ms: config.timeout_ms,
    retry_on_transient: config.retry_on_transient,
  )
}

/// Update request timeout in existing configuration
///
/// Arguments:
/// - config: Existing ClientConfig
/// - timeout_ms: New timeout in milliseconds
///
/// Returns:
/// - Updated ClientConfig with new timeout
///
/// Example:
/// ```gleam
/// let config = bearer_config("http://localhost:8000", "token")
/// let slower_config = update_timeout(config, 30_000)
/// ```
pub fn update_timeout(config: ClientConfig, timeout_ms: Int) -> ClientConfig {
  ClientConfig(
    base_url: config.base_url,
    auth: config.auth,
    timeout_ms: timeout_ms,
    retry_on_transient: config.retry_on_transient,
  )
}
