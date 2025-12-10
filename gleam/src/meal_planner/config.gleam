// Configuration module for the Meal Planner application
// Loads and validates environment variables

import envoy
import gleam/int
import gleam/result

/// Application configuration
pub type Config {
  Config(
    // Database configuration
    database_host: String,
    database_port: Int,
    database_name: String,
    database_user: String,
    database_password: String,
    database_pool_size: Int,
    // Server configuration
    port: Int,
    environment: String,
    // Mealie integration
    mealie_base_url: String,
    mealie_api_token: String,
    // External services (optional)
    todoist_api_key: String,
    usda_api_key: String,
    openai_api_key: String,
    openai_model: String,
  )
}

/// Load configuration from environment variables
///
/// Returns a Config struct with all required settings.
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
/// - MEALIE_BASE_URL (default: http://localhost:9000)
/// - MEALIE_API_TOKEN (required in production)
/// - TODOIST_API_KEY (optional)
/// - USDA_API_KEY (optional)
/// - OPENAI_API_KEY (optional)
/// - OPENAI_MODEL (default: gpt-4o)
pub fn load() -> Config {
  Config(
    // Database configuration
    database_host: result.unwrap(envoy.get("DATABASE_HOST"), "localhost"),
    database_port: result.unwrap(
      envoy.get("DATABASE_PORT")
        |> result.then(int.parse),
      5432,
    ),
    database_name: result.unwrap(envoy.get("DATABASE_NAME"), "meal_planner"),
    database_user: result.unwrap(envoy.get("DATABASE_USER"), "postgres"),
    database_password: result.unwrap(envoy.get("DATABASE_PASSWORD"), ""),
    database_pool_size: result.unwrap(
      envoy.get("DATABASE_POOL_SIZE")
        |> result.then(int.parse),
      10,
    ),
    // Server configuration
    port: result.unwrap(
      envoy.get("PORT")
        |> result.then(int.parse),
      8080,
    ),
    environment: result.unwrap(envoy.get("ENVIRONMENT"), "development"),
    // Mealie integration
    mealie_base_url: result.unwrap(
      envoy.get("MEALIE_BASE_URL"),
      "http://localhost:9000",
    ),
    mealie_api_token: result.unwrap(envoy.get("MEALIE_API_TOKEN"), ""),
    // External services (optional)
    todoist_api_key: result.unwrap(envoy.get("TODOIST_API_KEY"), ""),
    usda_api_key: result.unwrap(envoy.get("USDA_API_KEY"), ""),
    openai_api_key: result.unwrap(envoy.get("OPENAI_API_KEY"), ""),
    openai_model: result.unwrap(envoy.get("OPENAI_MODEL"), "gpt-4o"),
  )
}

/// Check if the configuration is valid for production use
///
/// Returns True if all required production settings are configured
pub fn is_production_ready(config: Config) -> Bool {
  config.environment == "production"
  && config.mealie_api_token != ""
  && config.database_password != ""
}

/// Get the database connection URL
///
/// Builds a PostgreSQL connection URL from the config
pub fn database_url(config: Config) -> String {
  let password_part = case config.database_password {
    "" -> ""
    pwd -> ":" <> pwd
  }

  "postgresql://"
  <> config.database_user
  <> password_part
  <> "@"
  <> config.database_host
  <> ":"
  <> int.to_string(config.database_port)
  <> "/"
  <> config.database_name
}

/// Check if Mealie integration is configured
pub fn has_mealie_integration(config: Config) -> Bool {
  config.mealie_api_token != ""
}

/// Check if OpenAI integration is configured
pub fn has_openai_integration(config: Config) -> Bool {
  config.openai_api_key != ""
}

/// Check if USDA integration is configured
pub fn has_usda_integration(config: Config) -> Bool {
  config.usda_api_key != ""
}
