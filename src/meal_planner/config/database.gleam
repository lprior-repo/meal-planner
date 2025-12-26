//// Database Configuration for Meal Planner
////
//// This module provides:
//// - Database configuration types
//// - Database config loading from environment variables
//// - Connection URL generation
//// - Database configuration validation
////
//// Configuration is loaded from environment variables:
//// - DATABASE_HOST (default: localhost)
//// - DATABASE_PORT (default: 5432)
//// - DATABASE_NAME (default: meal_planner)
//// - DATABASE_USER (default: postgres)
//// - DATABASE_PASSWORD (default: empty)
//// - DATABASE_POOL_SIZE (default: 10)
//// - DATABASE_CONNECTION_TIMEOUT_MS (default: 30000)

import gleam/int
import gleam/result
import meal_planner/config/environment.{
  type ConfigError, get_env_int, get_env_optional, get_env_or,
}

// ============================================================================
// TYPES
// ============================================================================

/// Database configuration
///
/// Contains all settings needed to connect to PostgreSQL:
/// - host: Database server hostname
/// - port: Database server port (typically 5432)
/// - name: Database name
/// - user: Database username
/// - password: Database password (optional for dev)
/// - pool_size: Connection pool size (1-100)
/// - connection_timeout_ms: Timeout for establishing connections
pub type DatabaseConfig {
  DatabaseConfig(
    host: String,
    port: Int,
    name: String,
    user: String,
    password: String,
    pool_size: Int,
    connection_timeout_ms: Int,
  )
}

// ============================================================================
// CONFIGURATION LOADING
// ============================================================================

/// Load database configuration from environment variables
///
/// Uses sensible defaults for development:
/// - host: localhost
/// - port: 5432
/// - name: meal_planner
/// - user: postgres
/// - password: (empty string)
/// - pool_size: 10
/// - connection_timeout_ms: 30000
///
/// Returns ConfigError if:
/// - DATABASE_PORT is not a valid integer
/// - DATABASE_POOL_SIZE is not a valid integer
/// - DATABASE_CONNECTION_TIMEOUT_MS is not a valid integer
pub fn load() -> Result(DatabaseConfig, ConfigError) {
  use database_port <- result.try(get_env_int("DATABASE_PORT", 5432))
  use database_pool_size <- result.try(get_env_int("DATABASE_POOL_SIZE", 10))
  use db_conn_timeout <- result.try(get_env_int(
    "DATABASE_CONNECTION_TIMEOUT_MS",
    30_000,
  ))

  Ok(DatabaseConfig(
    host: get_env_or("DATABASE_HOST", "localhost"),
    port: database_port,
    name: get_env_or("DATABASE_NAME", "meal_planner"),
    user: get_env_or("DATABASE_USER", "postgres"),
    password: get_env_optional("DATABASE_PASSWORD"),
    pool_size: database_pool_size,
    connection_timeout_ms: db_conn_timeout,
  ))
}

// ============================================================================
// VALIDATION
// ============================================================================

/// Validate database configuration
///
/// Checks:
/// - Pool size is between 1 and 100
///
/// Returns Ok(Nil) if valid, Error with validation messages if invalid
pub fn validate(config: DatabaseConfig) -> Result(Nil, List(String)) {
  let errors = []

  // Validate pool size
  let errors = case config.pool_size {
    size if size < 1 || size > 100 -> [
      "Database pool size must be between 1 and 100",
      ..errors
    ]
    _ -> errors
  }

  case errors {
    [] -> Ok(Nil)
    _ -> Error(errors)
  }
}

// ============================================================================
// CONNECTION URL GENERATION
// ============================================================================

/// Get the database connection URL
///
/// Builds a PostgreSQL connection URL from the config.
/// Format: postgresql://user[:password]@host:port/database
///
/// If password is empty, it's omitted from the URL.
pub fn database_url(config: DatabaseConfig) -> String {
  let password_part = case config.password {
    "" -> ""
    pwd -> ":" <> pwd
  }

  "postgresql://"
  <> config.user
  <> password_part
  <> "@"
  <> config.host
  <> ":"
  <> int.to_string(config.port)
  <> "/"
  <> config.name
}
