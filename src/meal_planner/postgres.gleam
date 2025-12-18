/// PostgreSQL connection module
/// Provides connection pooling and configuration for PostgreSQL database
///
/// Usage:
///   let assert Ok(config) = postgres.config_from_env()
///   let assert Ok(db) = postgres.connect(config)
///
import envoy
import gleam/erlang/process
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import pog

/// Database configuration
pub type Config {
  Config(
    host: String,
    port: Int,
    database: String,
    user: String,
    password: Option(String),
    pool_size: Int,
  )
}

/// Configuration errors
pub type ConfigError {
  MissingEnvVar(String)
  ParseError(field: String, value: String)
}

/// Connection errors
pub type ConnectionError {
  InitTimeout
  InitFailed(String)
  InitExited(String)
  InvalidConfig(String)
}

/// Default configuration for development
pub fn default_config() -> Config {
  Config(
    host: "localhost",
    port: 5432,
    database: "meal_planner",
    user: "postgres",
    password: Some("postgres"),
    pool_size: 10,
  )
}

/// Get environment variable or return error
fn get_env_or_error(var_name: String) -> Result(String, ConfigError) {
  envoy.get(var_name)
  |> result.map_error(fn(_) { MissingEnvVar(var_name) })
}

/// Parse integer or return error with context
fn parse_int_or_error(
  value: String,
  field_name: String,
) -> Result(Int, ConfigError) {
  int.parse(value)
  |> result.map_error(fn(_) { ParseError(field: field_name, value: value) })
}

/// Create configuration from environment variables
/// Returns error if required variables are missing or invalid
///
/// Required environment variables:
/// - DATABASE_HOST
/// - DATABASE_PORT
/// - DATABASE_NAME
/// - DATABASE_USER
/// - DATABASE_POOL_SIZE
///
/// Optional environment variables:
/// - DATABASE_PASSWORD
pub fn config_from_env() -> Result(Config, ConfigError) {
  use host <- result.try(get_env_or_error("DATABASE_HOST"))
  use port_str <- result.try(get_env_or_error("DATABASE_PORT"))
  use port <- result.try(parse_int_or_error(port_str, "DATABASE_PORT"))
  use database <- result.try(get_env_or_error("DATABASE_NAME"))
  use user <- result.try(get_env_or_error("DATABASE_USER"))
  use pool_size_str <- result.try(get_env_or_error("DATABASE_POOL_SIZE"))
  use pool_size <- result.try(parse_int_or_error(
    pool_size_str,
    "DATABASE_POOL_SIZE",
  ))

  let password = case envoy.get("DATABASE_PASSWORD") {
    Ok(pw) -> Some(pw)
    Error(_) -> None
  }

  Ok(Config(
    host: host,
    port: port,
    database: database,
    user: user,
    password: password,
    pool_size: pool_size,
  ))
}

/// Convert Config to pog.Config
fn to_pog_config(config: Config) -> pog.Config {
  let pool_name = process.new_name(prefix: "meal_planner_db")
  let base =
    pog.default_config(pool_name: pool_name)
    |> pog.host(config.host)
    |> pog.port(config.port)
    |> pog.database(config.database)
    |> pog.user(config.user)
    |> pog.pool_size(config.pool_size)

  case config.password {
    Some(pw) -> pog.password(base, Some(pw))
    None -> base
  }
}

/// Start PostgreSQL connection pool
/// Returns a connection on success or ConnectionError on failure
///
/// Example:
///   let config = postgres.default_config()
///   let assert Ok(db) = postgres.connect(config)
pub fn connect(config: Config) -> Result(pog.Connection, ConnectionError) {
  // Validate configuration
  case validate_config(config) {
    Error(e) -> Error(InvalidConfig(e))
    Ok(_) -> {
      let pog_config = to_pog_config(config)
      case pog.start(pog_config) {
        Ok(started) -> {
          let actor.Started(_pid, conn) = started
          Ok(conn)
        }
        Error(actor.InitTimeout) -> Error(InitTimeout)
        Error(actor.InitFailed(reason)) -> Error(InitFailed(reason))
        Error(actor.InitExited(reason)) ->
          Error(InitExited(string.inspect(reason)))
      }
    }
  }
}

/// Validate configuration before attempting connection
fn validate_config(config: Config) -> Result(Nil, String) {
  case config.host {
    "" -> Error("Host cannot be empty")
    _ ->
      case config.database {
        "" -> Error("Database name cannot be empty")
        _ ->
          case config.user {
            "" -> Error("User cannot be empty")
            _ ->
              case config.pool_size {
                n if n < 1 -> Error("Pool size must be at least 1")
                n if n > 100 -> Error("Pool size cannot exceed 100")
                _ -> Ok(Nil)
              }
          }
      }
  }
}

/// Format ConnectionError for display
pub fn format_error(error: ConnectionError) -> String {
  case error {
    InitTimeout -> "Database connection timeout"
    InitFailed(reason) -> "Database connection failed: " <> reason
    InitExited(reason) -> "Database process exited: " <> reason
    InvalidConfig(reason) -> "Invalid configuration: " <> reason
  }
}

/// Create a connection for a specific database (used for setup)
/// Useful for connecting to 'postgres' database to create other databases
pub fn connect_to_database(
  host: String,
  port: Int,
  database: String,
  user: String,
  password: Option(String),
) -> Result(pog.Connection, ConnectionError) {
  let config =
    Config(
      host: host,
      port: port,
      database: database,
      user: user,
      password: password,
      pool_size: 1,
    )
  connect(config)
}
