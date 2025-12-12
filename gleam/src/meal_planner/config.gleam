// Configuration module for the Meal Planner application
// Loads and validates environment variables

import envoy
import gleam/int
import gleam/result

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

/// Mealie integration configuration
pub type MealieConfig {
  MealieConfig(base_url: String, api_token: String)
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
    mealie: MealieConfig,
    external_services: ExternalServicesConfig,
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
  let database =
    DatabaseConfig(
      host: result.unwrap(envoy.get("DATABASE_HOST"), "localhost"),
      port: result.unwrap(
        envoy.get("DATABASE_PORT")
          |> result.try(int.parse),
        5432,
      ),
      name: result.unwrap(envoy.get("DATABASE_NAME"), "meal_planner"),
      user: result.unwrap(envoy.get("DATABASE_USER"), "postgres"),
      password: result.unwrap(envoy.get("DATABASE_PASSWORD"), ""),
      pool_size: result.unwrap(
        envoy.get("DATABASE_POOL_SIZE")
          |> result.try(int.parse),
        10,
      ),
    )

  let server =
    ServerConfig(
      port: result.unwrap(
        envoy.get("PORT")
          |> result.try(int.parse),
        8080,
      ),
      environment: result.unwrap(envoy.get("ENVIRONMENT"), "development"),
    )

  let mealie =
    MealieConfig(
      base_url: result.unwrap(
        envoy.get("MEALIE_BASE_URL"),
        "http://localhost:9000",
      ),
      api_token: result.unwrap(envoy.get("MEALIE_API_TOKEN"), ""),
    )

  let external_services =
    ExternalServicesConfig(
      todoist_api_key: result.unwrap(envoy.get("TODOIST_API_KEY"), ""),
      usda_api_key: result.unwrap(envoy.get("USDA_API_KEY"), ""),
      openai_api_key: result.unwrap(envoy.get("OPENAI_API_KEY"), ""),
      openai_model: result.unwrap(envoy.get("OPENAI_MODEL"), "gpt-4o"),
    )

  Config(
    database: database,
    server: server,
    mealie: mealie,
    external_services: external_services,
  )
}

/// Check if the configuration is valid for production use
///
/// Returns True if all required production settings are configured
pub fn is_production_ready(config: Config) -> Bool {
  config.server.environment == "production"
  && config.mealie.api_token != ""
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

/// Check if Mealie integration is configured
pub fn has_mealie_integration(config: Config) -> Bool {
  config.mealie.api_token != ""
}

/// Check if OpenAI integration is configured
pub fn has_openai_integration(config: Config) -> Bool {
  config.external_services.openai_api_key != ""
}

/// Check if USDA integration is configured
pub fn has_usda_integration(config: Config) -> Bool {
  config.external_services.usda_api_key != ""
}
