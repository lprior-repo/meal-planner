// Configuration module for the Meal Planner application
// Loads and validates environment variables

import envoy
import gleam/int
import gleam/result

/// Configuration error type
pub type ConfigError {
  MissingEnvVar(name: String)
  InvalidEnvVar(name: String, value: String, expected: String)
}

/// Database configuration
pub type DatabaseConfig {
  DatabaseConfig(
    host: String,
    port: Int,
    name: String,
    user: String,
    password: String,
    pool_size: Int,
  )
}

/// Server configuration
pub type ServerConfig {
  ServerConfig(port: Int, environment: String)
}

/// Tandoor integration configuration
pub type TandoorConfig {
  TandoorConfig(
    base_url: String,
    api_token: String,
    connect_timeout_ms: Int,
    request_timeout_ms: Int,
  )
}

/// External services configuration
pub type ExternalServicesConfig {
  ExternalServicesConfig(
    todoist_api_key: String,
    usda_api_key: String,
    openai_api_key: String,
    openai_model: String,
  )
}

/// Application configuration
pub type Config {
  Config(
    database: DatabaseConfig,
    server: ServerConfig,
    tandoor: TandoorConfig,
    external_services: ExternalServicesConfig,
  )
}

/// Get environment variable with a default value
fn get_env_or(name: String, default: String) -> String {
  envoy.get(name)
  |> result.unwrap(default)
}

/// Get optional environment variable (returns empty string if not set)
fn get_env_optional(name: String) -> String {
  envoy.get(name)
  |> result.unwrap("")
}

/// Parse integer from environment variable with default
fn get_env_int(name: String, default: Int) -> Result(Int, ConfigError) {
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

/// Load configuration from environment variables
///
/// Returns a Result with Config on success or ConfigError on failure.
/// Uses sensible defaults for development.
///
/// Environment variables:
/// - DATABASE_HOST (default: localhost)
/// - DATABASE_PORT (default: 5432)
/// - DATABASE_NAME (default: meal_planner)
/// - DATABASE_USER (default: postgres)
/// - DATABASE_PASSWORD (default: empty)
/// - DATABASE_POOL_SIZE (default: 10)
/// - PORT (default: 8080)
/// - ENVIRONMENT (default: development)
/// - TANDOOR_BASE_URL (default: http://localhost:8000)
/// - TANDOOR_API_TOKEN (optional)
/// - TANDOOR_CONNECT_TIMEOUT_MS (default: 5000)
/// - TANDOOR_REQUEST_TIMEOUT_MS (default: 30000)
/// - TODOIST_API_KEY (optional)
/// - USDA_API_KEY (optional)
/// - OPENAI_API_KEY (optional)
/// - OPENAI_MODEL (default: gpt-4o)
pub fn load() -> Result(Config, ConfigError) {
  use database_port <- result.try(get_env_int("DATABASE_PORT", 5432))
  use database_pool_size <- result.try(get_env_int("DATABASE_POOL_SIZE", 10))
  use server_port <- result.try(get_env_int("PORT", 8080))
  use tandoor_connect_timeout <- result.try(get_env_int(
    "TANDOOR_CONNECT_TIMEOUT_MS",
    5000,
  ))
  use tandoor_request_timeout <- result.try(get_env_int(
    "TANDOOR_REQUEST_TIMEOUT_MS",
    30_000,
  ))

  let database =
    DatabaseConfig(
      host: get_env_or("DATABASE_HOST", "localhost"),
      port: database_port,
      name: get_env_or("DATABASE_NAME", "meal_planner"),
      user: get_env_or("DATABASE_USER", "postgres"),
      password: get_env_optional("DATABASE_PASSWORD"),
      pool_size: database_pool_size,
    )

  let server =
    ServerConfig(
      port: server_port,
      environment: get_env_or("ENVIRONMENT", "development"),
    )

  let tandoor =
    TandoorConfig(
      base_url: get_env_or("TANDOOR_BASE_URL", "http://localhost:8000"),
      api_token: get_env_optional("TANDOOR_API_TOKEN"),
      connect_timeout_ms: tandoor_connect_timeout,
      request_timeout_ms: tandoor_request_timeout,
    )

  let external_services =
    ExternalServicesConfig(
      todoist_api_key: get_env_optional("TODOIST_API_KEY"),
      usda_api_key: get_env_optional("USDA_API_KEY"),
      openai_api_key: get_env_optional("OPENAI_API_KEY"),
      openai_model: get_env_or("OPENAI_MODEL", "gpt-4o"),
    )

  Ok(Config(
    database: database,
    server: server,
    tandoor: tandoor,
    external_services: external_services,
  ))
}

/// Check if the configuration is valid for production use
///
/// Returns True if all required production settings are configured
pub fn is_production_ready(config: Config) -> Bool {
  config.server.environment == "production"
  && config.tandoor.api_token != ""
  && config.database.password != ""
}

/// Get the database connection URL
///
/// Builds a PostgreSQL connection URL from the config
pub fn database_url(config: Config) -> String {
  let password_part = case config.database.password {
    "" -> ""
    pwd -> ":" <> pwd
  }

  "postgresql://"
  <> config.database.user
  <> password_part
  <> "@"
  <> config.database.host
  <> ":"
  <> int.to_string(config.database.port)
  <> "/"
  <> config.database.name
}

/// Check if Tandoor integration is configured
pub fn has_tandoor_integration(config: Config) -> Bool {
  config.tandoor.api_token != ""
}

/// Check if OpenAI integration is configured
pub fn has_openai_integration(config: Config) -> Bool {
  config.external_services.openai_api_key != ""
}

/// Check if USDA integration is configured
pub fn has_usda_integration(config: Config) -> Bool {
  config.external_services.usda_api_key != ""
}
