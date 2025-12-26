//// Comprehensive Configuration Management for Meal Planner
////
//// This module provides type-safe configuration loading with:
//// - Environment-based configuration (development/staging/production)
//// - Secrets management with encryption support
//// - Feature flags for runtime behavior control
//// - Database connection pooling configuration
//// - Logging levels and configuration
//// - Performance tuning parameters
//// - Validation on startup

import envoy
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/config/database.{type DatabaseConfig}
import meal_planner/config/environment.{
  type ConfigError, type Environment, type LogLevel, DebugLevel, Development,
  ErrorLevel, InfoLevel, InvalidEnvVar, MissingEnvVar, Production, Staging,
  ValidationError, WarnLevel,
}
import meal_planner/config/features.{
  type Feature, FeatureCORS, FeatureFatSecret, FeatureHealthCheck, FeatureOpenAI,
  FeatureRateLimiting, FeatureTandoor, FeatureTodoist, FeatureUSDA,
}

// ============================================================================
// TYPES
// ============================================================================

/// Server configuration
pub type ServerConfig {
  ServerConfig(port: Int, cors_allowed_origins: List(String))
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

/// FatSecret integration configuration
pub type FatSecretConfig {
  FatSecretConfig(consumer_key: String, consumer_secret: String)
}

/// External services configuration
pub type ExternalServicesConfig {
  ExternalServicesConfig(
    fatsecret: Option(FatSecretConfig),
    todoist_api_key: String,
    usda_api_key: String,
    openai_api_key: String,
    openai_model: String,
  )
}

/// Secrets configuration (sensitive data)
pub type SecretsConfig {
  SecretsConfig(
    oauth_encryption_key: Option(String),
    jwt_secret: Option(String),
    database_password: String,
    tandoor_token: String,
  )
}

/// Logging configuration
pub type LoggingConfig {
  LoggingConfig(level: LogLevel, debug_mode: Bool)
}

/// Performance tuning parameters
pub type PerformanceConfig {
  PerformanceConfig(
    request_timeout_ms: Int,
    connection_timeout_ms: Int,
    max_concurrent_requests: Int,
    rate_limit_requests: Int,
  )
}

/// Application configuration
pub type Config {
  Config(
    environment: Environment,
    database: DatabaseConfig,
    server: ServerConfig,
    tandoor: TandoorConfig,
    external_services: ExternalServicesConfig,
    secrets: SecretsConfig,
    logging: LoggingConfig,
    performance: PerformanceConfig,
  )
}

// ============================================================================
// ENVIRONMENT VARIABLE HELPERS (Re-exported from environment module)
// ============================================================================

/// Load .env file if it exists
fn load_dotenv() -> Nil {
  environment.load_dotenv()
}

/// Get environment variable with a default value
fn get_env_or(name: String, default: String) -> String {
  environment.get_env_or(name, default)
}

/// Get optional environment variable (returns empty string if not set)
fn get_env_optional(name: String) -> String {
  environment.get_env_optional(name)
}

/// Parse integer from environment variable with default
fn get_env_int(name: String, default: Int) -> Result(Int, ConfigError) {
  environment.get_env_int(name, default)
}

/// Parse boolean from environment variable
fn get_env_bool(name: String, default: Bool) -> Bool {
  environment.get_env_bool(name, default)
}

/// Parse comma-separated list from environment variable
fn get_env_list(name: String, default: List(String)) -> List(String) {
  environment.get_env_list(name, default)
}

/// Parse environment from string
fn parse_environment(env_str: String) -> Environment {
  environment.parse_environment(env_str)
}

/// Parse log level from string
fn parse_log_level(level_str: String) -> LogLevel {
  environment.parse_log_level(level_str)
}

// ============================================================================
// CONFIGURATION LOADING
// ============================================================================

/// Load configuration from environment variables
///
/// Returns a Result with Config on success or ConfigError on failure.
/// Uses sensible defaults for development.
///
/// # Environment Variables
///
/// ## Required (Production)
/// - ENVIRONMENT (development | staging | production)
/// - DATABASE_PASSWORD (required in production)
/// - TANDOOR_API_TOKEN (required in production)
/// - OAUTH_ENCRYPTION_KEY (required for FatSecret OAuth)
///
/// ## Database
/// - DATABASE_HOST (default: localhost)
/// - DATABASE_PORT (default: 5432)
/// - DATABASE_NAME (default: meal_planner)
/// - DATABASE_USER (default: postgres)
/// - DATABASE_PASSWORD (default: empty)
/// - DATABASE_POOL_SIZE (default: 10)
/// - DATABASE_CONNECTION_TIMEOUT_MS (default: 30000)
///
/// ## Server
/// - PORT (default: 8080)
/// - CORS_ALLOWED_ORIGINS (default: http://localhost:3000)
///
/// ## Tandoor
/// - TANDOOR_BASE_URL (default: http://localhost:8000)
/// - TANDOOR_API_TOKEN (optional)
/// - TANDOOR_CONNECT_TIMEOUT_MS (default: 5000)
/// - TANDOOR_REQUEST_TIMEOUT_MS (default: 30000)
///
/// ## External Services
/// - FATSECRET_CONSUMER_KEY (optional)
/// - FATSECRET_CONSUMER_SECRET (optional)
/// - TODOIST_API_KEY (optional)
/// - USDA_API_KEY (optional)
/// - OPENAI_API_KEY (optional)
/// - OPENAI_MODEL (default: gpt-4o)
///
/// ## Secrets
/// - OAUTH_ENCRYPTION_KEY (optional, required for FatSecret)
/// - JWT_SECRET (optional, required for auth)
///
/// ## Logging
/// - LOG_LEVEL (debug | info | warn | error, default: info)
/// - DEBUG_MODE (true | false, default: false)
///
/// ## Performance
/// - REQUEST_TIMEOUT_MS (default: 60000)
/// - CONNECTION_TIMEOUT_MS (default: 10000)
/// - MAX_CONCURRENT_REQUESTS (default: 100)
/// - RATE_LIMIT_REQUESTS (default: 100)
///
/// ## Feature Flags
/// - ENABLE_HEALTH_CHECK (default: true)
/// - SKIP_INTEGRATION_TESTS (default: false)
pub fn load() -> Result(Config, ConfigError) {
  load_dotenv()

  // Parse environment
  let environment =
    get_env_or("ENVIRONMENT", "development") |> parse_environment

  // Load database config
  use database <- result.try(database.load())

  // Parse server config
  use server_port <- result.try(get_env_int("PORT", 8080))

  // Parse Tandoor config
  use tandoor_connect_timeout <- result.try(get_env_int(
    "TANDOOR_CONNECT_TIMEOUT_MS",
    5000,
  ))
  use tandoor_request_timeout <- result.try(get_env_int(
    "TANDOOR_REQUEST_TIMEOUT_MS",
    30_000,
  ))

  // Parse performance config
  use request_timeout <- result.try(get_env_int("REQUEST_TIMEOUT_MS", 60_000))
  use connection_timeout <- result.try(get_env_int(
    "CONNECTION_TIMEOUT_MS",
    10_000,
  ))
  use max_concurrent <- result.try(get_env_int("MAX_CONCURRENT_REQUESTS", 100))
  use rate_limit <- result.try(get_env_int("RATE_LIMIT_REQUESTS", 100))

  // Build server config
  let server =
    ServerConfig(
      port: server_port,
      cors_allowed_origins: get_env_list("CORS_ALLOWED_ORIGINS", [
        "http://localhost:3000",
      ]),
    )

  // Build Tandoor config
  let tandoor =
    TandoorConfig(
      base_url: get_env_or("TANDOOR_BASE_URL", "http://localhost:8000"),
      api_token: get_env_optional("TANDOOR_API_TOKEN"),
      connect_timeout_ms: tandoor_connect_timeout,
      request_timeout_ms: tandoor_request_timeout,
    )

  // Build FatSecret config (optional)
  let fatsecret_config = case
    envoy.get("FATSECRET_CONSUMER_KEY"),
    envoy.get("FATSECRET_CONSUMER_SECRET")
  {
    Ok(key), Ok(secret) ->
      Some(FatSecretConfig(consumer_key: key, consumer_secret: secret))
    _, _ -> None
  }

  // Build external services config
  let external_services =
    ExternalServicesConfig(
      fatsecret: fatsecret_config,
      todoist_api_key: get_env_optional("TODOIST_API_KEY"),
      usda_api_key: get_env_optional("USDA_API_KEY"),
      openai_api_key: get_env_optional("OPENAI_API_KEY"),
      openai_model: get_env_or("OPENAI_MODEL", "gpt-4o"),
    )

  // Build secrets config
  let secrets =
    SecretsConfig(
      oauth_encryption_key: case envoy.get("OAUTH_ENCRYPTION_KEY") {
        Ok(key) -> Some(key)
        Error(_) -> None
      },
      jwt_secret: case envoy.get("JWT_SECRET") {
        Ok(secret) -> Some(secret)
        Error(_) -> None
      },
      database_password: database.password,
      tandoor_token: tandoor.api_token,
    )

  // Build logging config
  let logging =
    LoggingConfig(
      level: get_env_or("LOG_LEVEL", "info") |> parse_log_level,
      debug_mode: get_env_bool("DEBUG_MODE", False),
    )

  // Build performance config
  let performance =
    PerformanceConfig(
      request_timeout_ms: request_timeout,
      connection_timeout_ms: connection_timeout,
      max_concurrent_requests: max_concurrent,
      rate_limit_requests: rate_limit,
    )

  Ok(Config(
    environment: environment,
    database: database,
    server: server,
    tandoor: tandoor,
    external_services: external_services,
    secrets: secrets,
    logging: logging,
    performance: performance,
  ))
}

// ============================================================================
// VALIDATION
// ============================================================================

/// Validate configuration
///
/// Checks that all required settings are present and valid.
/// Returns Ok(Nil) if valid, or Error with list of validation errors.
pub fn validate(config: Config) -> Result(Nil, ConfigError) {
  let errors = []

  // Validate database config
  let errors = case database.validate(config.database) {
    Ok(_) -> errors
    Error(db_errors) -> list.append(db_errors, errors)
  }

  // Validate production requirements
  let errors = case config.environment {
    Production -> {
      let errors = case config.secrets.database_password {
        "" -> ["DATABASE_PASSWORD is required in production", ..errors]
        _ -> errors
      }

      let errors = case config.secrets.tandoor_token {
        "" -> ["TANDOOR_API_TOKEN is required in production", ..errors]
        _ -> errors
      }

      errors
    }
    _ -> errors
  }

  // Validate FatSecret OAuth encryption key (if FatSecret enabled)
  let errors = case config.external_services.fatsecret {
    Some(_) ->
      case config.secrets.oauth_encryption_key {
        Some(key) ->
          case string.length(key) {
            len if len < 32 -> [
              "OAUTH_ENCRYPTION_KEY must be at least 32 characters (256 bits in hex)",
              ..errors
            ]
            _ -> errors
          }
        None -> [
          "OAUTH_ENCRYPTION_KEY is required when FatSecret is configured",
          ..errors
        ]
      }
    None -> errors
  }

  // Validate performance limits
  let errors = case config.performance.max_concurrent_requests {
    max if max < 1 || max > 1000 -> [
      "MAX_CONCURRENT_REQUESTS must be between 1 and 1000",
      ..errors
    ]
    _ -> errors
  }

  case errors {
    [] -> Ok(Nil)
    _ -> Error(ValidationError(errors: list.reverse(errors)))
  }
}

// ============================================================================
// FEATURE FLAGS
// ============================================================================

/// Check if a feature is enabled
pub fn is_feature_enabled(config: Config, feature: Feature) -> Bool {
  case feature {
    FeatureFatSecret ->
      case config.external_services.fatsecret {
        Some(_) -> True
        None -> False
      }
    FeatureTandoor -> config.tandoor.api_token != ""
    FeatureOpenAI -> config.external_services.openai_api_key != ""
    FeatureUSDA -> config.external_services.usda_api_key != ""
    FeatureTodoist -> config.external_services.todoist_api_key != ""
    FeatureHealthCheck -> get_env_bool("ENABLE_HEALTH_CHECK", True)
    FeatureRateLimiting -> config.performance.rate_limit_requests > 0
    FeatureCORS -> config.server.cors_allowed_origins != []
  }
}

// ============================================================================
// PRODUCTION READINESS
// ============================================================================

/// Check if the configuration is valid for production use
///
/// Returns True if all required production settings are configured
pub fn is_production_ready(config: Config) -> Bool {
  config.environment == Production
  && config.tandoor.api_token != ""
  && config.database.password != ""
  && {
    case config.secrets.jwt_secret {
      Some(secret) -> secret != ""
      None -> False
    }
  }
}

// ============================================================================
// ACCESSORS
// ============================================================================

/// Get the database connection URL
///
/// Builds a PostgreSQL connection URL from the config
pub fn database_url(config: Config) -> String {
  database.database_url(config.database)
}

/// Get environment
pub fn get_environment(config: Config) -> Environment {
  config.environment
}

/// Get database config
pub fn get_database_config(config: Config) -> DatabaseConfig {
  config.database
}

/// Get logging config
pub fn get_logging_config(config: Config) -> LoggingConfig {
  config.logging
}

/// Get performance config
pub fn get_performance_config(config: Config) -> PerformanceConfig {
  config.performance
}

/// Get secrets config
pub fn get_secrets_config(config: Config) -> SecretsConfig {
  config.secrets
}

/// Check if Tandoor integration is configured
pub fn has_tandoor_integration(config: Config) -> Bool {
  config.tandoor.api_token != ""
}

/// Check if FatSecret integration is configured
pub fn has_fatsecret_integration(config: Config) -> Bool {
  case config.external_services.fatsecret {
    Some(_) -> True
    None -> False
  }
}

/// Check if OpenAI integration is configured
pub fn has_openai_integration(config: Config) -> Bool {
  config.external_services.openai_api_key != ""
}

/// Check if USDA integration is configured
pub fn has_usda_integration(config: Config) -> Bool {
  config.external_services.usda_api_key != ""
}

// ============================================================================
// ERROR FORMATTING
// ============================================================================

/// Format configuration error for display
pub fn format_error(error: ConfigError) -> String {
  case error {
    MissingEnvVar(name) -> "Missing required environment variable: " <> name
    InvalidEnvVar(name, value, expected) ->
      "Invalid value for "
      <> name
      <> ": '"
      <> value
      <> "' (expected: "
      <> expected
      <> ")"
    ValidationError(errors) ->
      "Configuration validation failed:\n  - " <> string.join(errors, "\n  - ")
  }
}
