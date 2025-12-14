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
import gleam/erlang/os
import gleam/option.{None, Some}
import gleam/result
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, bearer_config, ensure_authenticated,
  session_config,
}

/// Get test configuration from environment variables
///
/// Tries session auth first (TANDOOR_USERNAME/PASSWORD), falls back to bearer token.
///
/// # Returns
/// Result with authenticated client config or error message
pub fn get_test_config() -> Result(ClientConfig, String) {
  use url <- result.try(
    os.get_env("TANDOOR_URL")
    |> result.replace_error(
      "TANDOOR_URL not set - set it to your Tandoor instance URL (e.g., http://localhost:8000)",
    ),
  )

  // Try session auth first (recommended)
  case os.get_env("TANDOOR_USERNAME"), os.get_env("TANDOOR_PASSWORD") {
    Ok(username), Ok(password) -> {
      let config = session_config(url, username, password)
      // Authenticate and return config
      case ensure_authenticated(config) {
        Ok(authenticated_config) -> Ok(authenticated_config)
        Error(err) ->
          Error(
            "Failed to authenticate with Tandoor: "
            <> client.error_to_string(err),
          )
      }
    }
    _, _ -> {
      // Fall back to bearer token
      use token <- result.try(
        os.get_env("TANDOOR_TOKEN")
        |> result.replace_error(
          "Neither TANDOOR_USERNAME/PASSWORD nor TANDOOR_TOKEN set - provide credentials for testing",
        ),
      )
      Ok(bearer_config(url, token))
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
/// Returns True if TANDOOR_URL is not set (tests should be skipped).
/// Returns False if TANDOOR_URL is set (tests can run).
pub fn skip_if_no_tandoor() -> Bool {
  case os.get_env("TANDOOR_URL") {
    Ok(_) -> False
    Error(_) -> True
  }
}

/// Get environment variable or default value
pub fn get_env_or_default(key: String, default: String) -> String {
  case os.get_env(key) {
    Ok(value) -> value
    Error(_) -> default
  }
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
