/// Test helpers for Tandoor SDK integration tests
///
/// These helpers require a running Tandoor instance.
/// Set TANDOOR_URL and TANDOOR_TOKEN environment variables.
///
/// Usage:
/// ```bash
/// export TANDOOR_URL=http://localhost:8000
/// export TANDOOR_TOKEN=your_api_token
/// gleam test
/// ```
///
/// Or for session-based auth (recommended):
/// ```bash
/// export TANDOOR_URL=http://localhost:8000
/// export TANDOOR_USERNAME=admin
/// export TANDOOR_PASSWORD=password
/// gleam test
/// ```
import gleam/option
import gleam/result
import meal_planner/env
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, bearer_config, ensure_authenticated,
  session_config,
}

/// Get test configuration from environment variables
///
/// Uses centralized env.gleam module for consistency.
/// Tries session auth first (TANDOOR_USERNAME/PASSWORD), falls back to infrastructure defaults.
///
/// # Returns
/// Result with authenticated client config or error message
pub fn get_test_config() -> Result(ClientConfig, String) {
  // Use centralized env module to load Tandoor configuration
  case env.load_tandoor_config() {
    option.Some(tandoor_config) -> {
      // Use configuration from environment variables
      let config =
        session_config(
          tandoor_config.base_url,
          tandoor_config.username,
          tandoor_config.password,
        )

      // Authenticate and return config
      case ensure_authenticated(config) {
        Ok(authenticated_config) -> Ok(authenticated_config)
        Error(err) ->
          Error(
            "Failed to authenticate with Tandoor (from env): "
            <> client.error_to_string(err),
          )
      }
    }
    option.None -> {
      // Fall back to infrastructure defaults (http://localhost:8100, admin/admin)
      // This matches what docker-compose.test.yml provides
      let config = session_config("http://localhost:8100", "admin", "admin")
      case ensure_authenticated(config) {
        Ok(authenticated_config) -> Ok(authenticated_config)
        Error(err) ->
          Error(
            "Failed to authenticate with default credentials (admin/admin): "
            <> client.error_to_string(err),
          )
      }
    }
  }
}

/// Get test configuration with custom timeout
pub fn get_test_config_with_timeout(
  timeout_ms: Int,
) -> Result(ClientConfig, String) {
  use config <- result.try(get_test_config())
  Ok(client.with_timeout(config, timeout_ms))
}

/// Check if integration tests should be skipped
///
/// Always returns False - tests use infrastructure defaults when env vars not set
pub fn skip_if_no_tandoor() -> Bool {
  // Never skip - use infrastructure defaults (http://localhost:8100, admin/admin)
  False
}

/// Get environment variable or default value
pub fn get_env_or_default(key: String, default: String) -> String {
  env.get_env(key, default)
}

/// Helper to run a test only if Tandoor is available
///
/// # Arguments
/// * `test_fn` - Function to run if Tandoor is available
///
/// # Returns
/// Result of test_fn or Ok(Nil) if skipped
pub fn run_if_available(
  test_fn: fn(ClientConfig) -> Result(a, TandoorError),
) -> Result(a, String) {
  case skip_if_no_tandoor() {
    True -> {
      // Test skipped - return dummy success
      // Note: In real tests, we'll check skip_if_no_tandoor() before calling this
      Error("Skipped: Tandoor not available")
    }
    False -> {
      use config <- result.try(get_test_config())
      test_fn(config)
      |> result.map_error(client.error_to_string)
    }
  }
}

/// Create a test recipe name with timestamp to avoid conflicts
pub fn test_recipe_name() -> String {
  let timestamp =
    erlang_system_time_milliseconds()
    |> int_to_string()

  "Test Recipe " <> timestamp
}

/// Get current system time in milliseconds (for unique test data)
@external(erlang, "erlang", "system_time")
fn erlang_system_time_milliseconds() -> Int

/// Convert integer to string for recipe naming
@external(erlang, "erlang", "integer_to_binary")
fn int_to_string(value: Int) -> String
