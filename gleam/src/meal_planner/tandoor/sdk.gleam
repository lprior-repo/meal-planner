/// Tandoor SDK - Unified Facade
///
/// This module provides a unified entry point for the Tandoor API SDK,
/// combining all API modules into a single, easy-to-use interface.
///
/// Usage:
/// ```gleam
/// let sdk = sdk.new(
///   base_url: "http://localhost:8000",
///   auth: sdk.BearerAuth("my-token")
/// )
///
/// // Use the SDK
/// let assert Ok(recipe) = sdk |> recipes.get(recipe_id: 1)
/// let assert Ok(foods) = sdk |> foods.list()
/// ```
import gleam/option.{type Option, None, Some}
import meal_planner/tandoor/client.{
  type ClientConfig, BearerAuth, SessionAuth,
}
import meal_planner/tandoor/core/http.{type HttpTransport}

// Re-export commonly used types for convenience
pub type TandoorError =
  client.TandoorError

pub type AuthMethod =
  client.AuthMethod

// ============================================================================
// SDK Configuration
// ============================================================================

/// SDK configuration that wraps ClientConfig with additional features
pub type SDK {
  SDK(
    /// Base URL for Tandoor instance
    base_url: String,
    /// Authentication method
    auth: AuthMethod,
    /// Request timeout in milliseconds
    timeout_ms: Int,
    /// Maximum retry attempts
    max_retries: Int,
    /// Custom HTTP transport (for testing)
    transport: Option(HttpTransport),
  )
}

/// Create a new SDK instance
pub fn new(base_url base_url: String, auth auth: AuthMethod) -> SDK {
  SDK(
    base_url: base_url,
    auth: auth,
    timeout_ms: 30_000,
    max_retries: 3,
    transport: None,
  )
}

/// Set custom timeout
pub fn with_timeout(sdk: SDK, timeout_ms: Int) -> SDK {
  SDK(..sdk, timeout_ms: timeout_ms)
}

/// Set maximum retries
pub fn with_retry(sdk: SDK, max_retries max_retries: Int) -> SDK {
  SDK(..sdk, max_retries: max_retries)
}

/// Set custom HTTP transport (for testing)
pub fn with_transport(sdk: SDK, transport: HttpTransport) -> SDK {
  SDK(..sdk, transport: Some(transport))
}

/// Update authentication
pub fn with_auth(sdk: SDK, auth: AuthMethod) -> SDK {
  SDK(..sdk, auth: auth)
}

// ============================================================================
// Internal Conversion
// ============================================================================

/// Convert SDK to ClientConfig for use with existing API modules
pub fn to_client_config(sdk: SDK) -> ClientConfig {
  client.ClientConfig(
    base_url: sdk.base_url,
    auth: sdk.auth,
    timeout_ms: sdk.timeout_ms,
    retry_on_transient: True,
    max_retries: sdk.max_retries,
  )
}

// ============================================================================
// API Module Namespaces (Future Implementation)
// ============================================================================

// Note: These would be implemented as separate modules that take SDK as input
// For now, we document the intended API structure:
//
// pub module recipes {
//   pub fn get(sdk: SDK, recipe_id: Int) -> Result(Recipe, TandoorError)
//   pub fn list(sdk: SDK) -> Result(PaginatedResponse(Recipe), TandoorError)
//   pub fn create(sdk: SDK, ...) -> Result(Recipe, TandoorError)
//   pub fn update(sdk: SDK, ...) -> Result(Recipe, TandoorError)
//   pub fn delete(sdk: SDK, recipe_id: Int) -> Result(Nil, TandoorError)
// }
//
// pub module foods {
//   pub fn get(sdk: SDK, food_id: Int) -> Result(Food, TandoorError)
//   pub fn list(sdk: SDK) -> Result(PaginatedResponse(Food), TandoorError)
//   pub fn create(sdk: SDK, ...) -> Result(Food, TandoorError)
//   pub fn update(sdk: SDK, ...) -> Result(Food, TandoorError)
//   pub fn delete(sdk: SDK, food_id: Int) -> Result(Nil, TandoorError)
// }
//
// pub module mealplans {
//   pub fn get(sdk: SDK, mealplan_id: Int) -> Result(MealPlan, TandoorError)
//   pub fn list(sdk: SDK) -> Result(PaginatedResponse(MealPlan), TandoorError)
//   pub fn create(sdk: SDK, ...) -> Result(MealPlan, TandoorError)
//   pub fn update(sdk: SDK, ...) -> Result(MealPlan, TandoorError)
//   pub fn delete(sdk: SDK, mealplan_id: Int) -> Result(Nil, TandoorError)
// }
//
// pub module keywords {
//   pub fn list(sdk: SDK) -> Result(PaginatedResponse(Keyword), TandoorError)
// }
//
// pub module units {
//   pub fn get(sdk: SDK, unit_id: Int) -> Result(Unit, TandoorError)
//   pub fn list(sdk: SDK) -> Result(PaginatedResponse(Unit), TandoorError)
// }
//
// pub module auth {
//   pub fn login(sdk: SDK, username: String, password: String) -> Result(String, TandoorError)
//   pub fn logout(sdk: SDK) -> Result(Nil, TandoorError)
// }

// ============================================================================
// Migration Helpers
// ============================================================================

/// Create SDK from existing ClientConfig (migration helper)
pub fn from_client_config(config: ClientConfig) -> SDK {
  SDK(
    base_url: config.base_url,
    auth: config.auth,
    timeout_ms: config.timeout_ms,
    max_retries: config.max_retries,
    transport: None,
  )
}

/// Helper to create SDK with Bearer token
pub fn with_bearer_token(base_url: String, token: String) -> SDK {
  new(base_url: base_url, auth: BearerAuth(token))
}

/// Helper to create SDK with session auth
pub fn with_session(base_url: String, username: String, password: String) -> SDK {
  new(
    base_url: base_url,
    auth: SessionAuth(
      username: username,
      password: password,
      session_id: None,
      csrf_token: None,
    ),
  )
}

// ============================================================================
// NoAuth Type (for testing/migration)
// ============================================================================

/// No authentication (for testing)
/// Note: This is a placeholder - actual implementation would need
/// to add NoAuth variant to client.AuthMethod
pub type NoAuth {
  NoAuth
}
