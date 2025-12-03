/// Test database helper - manages PostgreSQL lifecycle for tests
import gleam/erlang/process
import gleam/option.{Some}
import gleam/otp/actor
import gleam/string
import meal_planner/storage
import pog

/// Test database configuration
pub fn test_config() -> storage.DbConfig {
  storage.DbConfig(
    host: "localhost",
    port: 5432,
    database: "meal_planner_test",
    user: "postgres",
    password: Some("postgres"),
    pool_size: 5,
  )
}

/// Start PostgreSQL if not running and create test database
pub fn setup() -> Result(pog.Connection, String) {
  // Check if PostgreSQL is running by trying to connect to default database
  case try_connect_postgres() {
    Ok(_) -> {
      // PostgreSQL is running, create test database
      create_test_database()
    }
    Error(_) -> {
      // Try to start PostgreSQL
      case start_postgresql() {
        Ok(_) -> {
          // Wait a moment for PostgreSQL to start
          process.sleep(2000)
          create_test_database()
        }
        Error(e) -> Error("Failed to start PostgreSQL: " <> e)
      }
    }
  }
}

/// Try to connect to default postgres database
fn try_connect_postgres() -> Result(pog.Connection, String) {
  let pool_name = process.new_name(prefix: "test_pg_check")
  let config =
    pog.default_config(pool_name: pool_name)
    |> pog.host("localhost")
    |> pog.port(5432)
    |> pog.database("postgres")
    |> pog.user("postgres")
    |> pog.password(Some("postgres"))
    |> pog.pool_size(1)

  case pog.start(config) {
    Ok(started) -> {
      let actor.Started(_pid, conn) = started
      Ok(conn)
    }
    Error(_) -> Error("Cannot connect to PostgreSQL")
  }
}

/// Start PostgreSQL service using systemctl
fn start_postgresql() -> Result(Nil, String) {
  // Note: This requires the user to have passwordless sudo for systemctl start postgresql
  // Or PostgreSQL already configured to auto-start
  // For now, we'll just return an error with helpful message
  Error(
    "PostgreSQL is not running. Please start it with: sudo systemctl start postgresql",
  )
}

/// Create test database and run migrations
fn create_test_database() -> Result(pog.Connection, String) {
  // First connect to postgres database to create test database
  case try_connect_postgres() {
    Ok(postgres_conn) -> {
      // Drop and recreate test database for clean slate
      let drop_query = pog.query("DROP DATABASE IF EXISTS meal_planner_test")
      let create_query = pog.query("CREATE DATABASE meal_planner_test")

      case pog.execute(drop_query, postgres_conn) {
        Ok(_) -> {
          case pog.execute(create_query, postgres_conn) {
            Ok(_) -> {
              // Now connect to test database and run migrations
              let config = test_config()
              case storage.start_pool(config) {
                Ok(test_conn) -> {
                  case run_migrations(test_conn) {
                    Ok(_) -> Ok(test_conn)
                    Error(e) -> Error("Failed to run migrations: " <> e)
                  }
                }
                Error(e) -> Error("Failed to connect to test database: " <> e)
              }
            }
            Error(err) ->
              Error("Failed to create test database: " <> format_error(err))
          }
        }
        Error(err) ->
          Error("Failed to drop test database: " <> format_error(err))
      }
    }
    Error(e) -> Error(e)
  }
}

/// Run all migrations on test database
fn run_migrations(conn: pog.Connection) -> Result(Nil, String) {
  // Create schema_migrations table first
  let schema_query =
    pog.query(
      "CREATE TABLE IF NOT EXISTS schema_migrations (
       version INTEGER PRIMARY KEY,
       applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
     )",
    )

  case pog.execute(schema_query, conn) {
    Ok(_) -> {
      // In a real implementation, we would read and execute all migration files
      // For now, return Ok - migrations can be run manually or by init script
      Ok(Nil)
    }
    Error(err) ->
      Error("Failed to create schema_migrations: " <> format_error(err))
  }
}

/// Cleanup - drop test database
pub fn teardown(_conn: pog.Connection) -> Result(Nil, String) {
  // Note: pog connection pools don't need explicit disconnect
  // They are cleaned up automatically by the OTP supervision tree

  // Connect to postgres database to drop test database
  case try_connect_postgres() {
    Ok(postgres_conn) -> {
      let drop_query = pog.query("DROP DATABASE IF EXISTS meal_planner_test")
      case pog.execute(drop_query, postgres_conn) {
        Ok(_) -> Ok(Nil)
        Error(err) ->
          Error("Failed to drop test database: " <> format_error(err))
      }
    }
    Error(e) -> Error(e)
  }
}

/// Format pog query error for display
fn format_error(err: pog.QueryError) -> String {
  case err {
    pog.PostgresqlError(code, name, msg) ->
      "PostgreSQL error " <> code <> " (" <> name <> "): " <> msg
    pog.UnexpectedResultType(errors) ->
      "Decode errors: " <> string.inspect(errors)
    pog.UnexpectedArgumentCount(expected, got) ->
      "Expected "
      <> string.inspect(expected)
      <> " arguments, got "
      <> string.inspect(got)
    pog.UnexpectedArgumentType(expected, got) ->
      "Expected type " <> expected <> ", got " <> got
    pog.ConstraintViolated(msg, constraint, detail) ->
      "Constraint violation: " <> msg <> " (" <> constraint <> "): " <> detail
    pog.ConnectionUnavailable ->
      "Connection unavailable - database may not be running"
    pog.QueryTimeout -> "Database query timeout"
  }
}
