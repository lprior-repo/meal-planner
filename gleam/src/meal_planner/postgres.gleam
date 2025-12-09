/// PostgreSQL connection module
/// Provides connection pooling and configuration for PostgreSQL database
///
/// Usage:
///   let config = postgres.config_from_env()
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

/// Create configuration from environment variables
/// Falls back to defaults if variables not set
///
/// Environment variables:
/// - DATABASE_HOST (default: localhost)
/// - DATABASE_PORT (default: 5432)
/// - DATABASE_NAME (default: meal_planner)
/// - DATABASE_USER (default: postgres)
/// - DATABASE_PASSWORD (optional)
/// - DATABASE_POOL_SIZE (default: 10)
pub fn config_from_env() -> Config {
  let host = result.unwrap(envoy.get("DATABASE_HOST"), "localhost")
  let port =
    envoy.get("DATABASE_PORT")
    |> result.try(int.parse)
    |> result.unwrap(5432)
  let database = result.unwrap(envoy.get("DATABASE_NAME"), "meal_planner")
  let user = result.unwrap(envoy.get("DATABASE_USER"), "postgres")
  let password = case envoy.get("DATABASE_PASSWORD") {
    Ok(pw) -> Some(pw)
    Error(_) -> None
  }
  let pool_size =
    envoy.get("DATABASE_POOL_SIZE")
    |> result.try(int.parse)
    |> result.unwrap(10)

  Config(
    host: host,
    port: port,
    database: database,
    user: user,
    password: password,
    pool_size: pool_size,
  )
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
