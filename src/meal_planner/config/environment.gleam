//// Environment Configuration and Loading
////
//// This module provides:
//// - Environment types (Development, Staging, Production)
//// - Log level types (Debug, Info, Warn, Error)
//// - Configuration error types
//// - Environment variable loading helpers
//// - String parsing for environment and log levels
////
//// All configuration loading starts here with the foundational
//// environment variable helpers and type definitions.

import dot_env
import envoy
import gleam/int
import gleam/list
import gleam/result
import gleam/string

// ============================================================================
// Core Types
// ============================================================================

/// Application environment
pub type Environment {
  Development
  Staging
  Production
}

/// Log level
pub type LogLevel {
  DebugLevel
  InfoLevel
  WarnLevel
  ErrorLevel
}

/// Configuration error type
pub type ConfigError {
  MissingEnvVar(name: String)
  InvalidEnvVar(name: String, value: String, expected: String)
  ValidationError(errors: List(String))
}

// ============================================================================
// Environment Variable Helpers
// ============================================================================

/// Load .env file if it exists
pub fn load_dotenv() -> Nil {
  dot_env.new()
  |> dot_env.set_path("../.env")
  |> dot_env.set_debug(False)
  |> dot_env.set_ignore_missing_file(True)
  |> dot_env.load

  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(False)
  |> dot_env.set_ignore_missing_file(True)
  |> dot_env.load
}

/// Get environment variable with a default value
pub fn get_env_or(name: String, default: String) -> String {
  envoy.get(name) |> result.unwrap(default)
}

/// Get optional environment variable (returns empty string if not set)
pub fn get_env_optional(name: String) -> String {
  envoy.get(name) |> result.unwrap("")
}

/// Parse integer from environment variable with default
pub fn get_env_int(name: String, default: Int) -> Result(Int, ConfigError) {
  case envoy.get(name) {
    Ok(value) ->
      case int.parse(value) {
        Ok(parsed) -> Ok(parsed)
        Error(_) ->
          Error(InvalidEnvVar(name: name, value: value, expected: "integer"))
      }
    Error(_) -> Ok(default)
  }
}

/// Parse boolean from environment variable
pub fn get_env_bool(name: String, default: Bool) -> Bool {
  case envoy.get(name) {
    Ok(value) ->
      case string.lowercase(value) {
        "true" -> True
        "1" -> True
        "yes" -> True
        "false" -> False
        "0" -> False
        "no" -> False
        _ -> default
      }
    Error(_) -> default
  }
}

/// Parse comma-separated list from environment variable
pub fn get_env_list(name: String, default: List(String)) -> List(String) {
  case envoy.get(name) {
    Ok(value) ->
      value
      |> string.split(",")
      |> list.map(string.trim)
      |> list.filter(fn(s) { !string.is_empty(s) })
    Error(_) -> default
  }
}

// ============================================================================
// Parsing Functions
// ============================================================================

/// Parse environment from string
pub fn parse_environment(env_str: String) -> Environment {
  case string.lowercase(env_str) {
    "production" -> Production
    "staging" -> Staging
    _ -> Development
  }
}

/// Parse log level from string
pub fn parse_log_level(level_str: String) -> LogLevel {
  case string.lowercase(level_str) {
    "debug" -> DebugLevel
    "info" -> InfoLevel
    "warn" -> WarnLevel
    "error" -> ErrorLevel
    _ -> InfoLevel
  }
}

// ============================================================================
// Helper Functions for Environment
// ============================================================================

/// Check if environment is production
pub fn is_production(env: Environment) -> Bool {
  case env {
    Production -> True
    _ -> False
  }
}

/// Check if environment is development
pub fn is_development(env: Environment) -> Bool {
  case env {
    Development -> True
    _ -> False
  }
}

/// Convert environment to string
pub fn environment_to_string(env: Environment) -> String {
  case env {
    Development -> "development"
    Staging -> "staging"
    Production -> "production"
  }
}

/// Convert log level to string
pub fn log_level_to_string(level: LogLevel) -> String {
  case level {
    DebugLevel -> "debug"
    InfoLevel -> "info"
    WarnLevel -> "warn"
    ErrorLevel -> "error"
  }
}
