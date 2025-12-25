/// Tandoor API client aggregator module
///
/// This module re-exports the main types and functions from the Tandoor client
/// family of modules, providing a unified interface for API interactions.
///
/// The client is organized by resource type:
/// - http: Low-level HTTP utilities and configuration
/// - recipes: Recipe management operations
/// - shopping: Shopping list operations
/// - mealplan: Meal plan operations
/// - foods: Food database operations
/// - users: User management operations
///
/// ## Usage
///
/// ```gleam
/// import meal_planner/tandoor/client.{
///   ClientConfig, AuthMethod, BearerAuth,
/// }
///
/// let config = ClientConfig(
///   base_url: "http://localhost:8000",
///   auth: BearerAuth(token: "your-token"),
///   timeout_ms: 10_000,
///   retry_on_transient: True,
///   max_retries: 3,
/// )
/// ```
import gleam/option.{type Option}

// ============================================================================
// Core Client Types
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
// Re-exports from submodules
// ============================================================================

// These would be imported and re-exported once the submodules are created:
//
// pub use meal_planner/tandoor/client/http.{...}
// pub use meal_planner/tandoor/client/recipes.{...}
// pub use meal_planner/tandoor/client/shopping.{...}
// pub use meal_planner/tandoor/client/mealplan.{...}
// pub use meal_planner/tandoor/client/foods.{...}
// pub use meal_planner/tandoor/client/users.{...}
