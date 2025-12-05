/// Test database setup and fixtures
/// Provides utilities to create test databases with migrations pre-applied
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/string
import pog
import simplifile

// =============================================================================
// Configuration
// =============================================================================

const test_db_name = "meal_planner_test"

/// Create a test database configuration
pub fn test_db_config() -> pog.Config {
  let pool_name = process.new_name(prefix: "test_pool")
  pog.default_config(pool_name)
  |> pog.host("localhost")
  |> pog.port(5432)
  |> pog.database(test_db_name)
  |> pog.user("postgres")
  |> pog.password(Some("postgres"))
  |> pog.pool_size(5)
}

/// Create postgres database config (for setup/teardown)
fn postgres_db_config() -> pog.Config {
  let pool_name = process.new_name(prefix: "setup_pool")
  pog.default_config(pool_name)
  |> pog.host("localhost")
  |> pog.port(5432)
  |> pog.database("postgres")
  |> pog.user("postgres")
  |> pog.password(Some("postgres"))
  |> pog.pool_size(1)
}

// =============================================================================
// Database Setup
// =============================================================================

/// Create test database
fn create_test_database() -> Result(Nil, String) {
  case pog.start(postgres_db_config()) {
    Error(_) -> Error("Cannot connect to PostgreSQL")
    Ok(started) -> {
      let db = started.data

      // Drop existing test database
      let drop_query =
        pog.query("DROP DATABASE IF EXISTS " <> test_db_name <> ";")
      let _ = pog.execute(drop_query, db)

      // Create fresh test database
      let create_query = pog.query("CREATE DATABASE " <> test_db_name <> ";")
      let result = case pog.execute(create_query, db) {
        Ok(_) -> Ok(Nil)
        Error(_) -> Error("Failed to create test database")
      }

      // Cleanup pool
      process.kill(started.pid)
      result
    }
  }
}

/// Format pog error for display
fn format_pog_error(e: pog.QueryError) -> String {
  case e {
    pog.ConstraintViolated(msg, _, _) -> "Constraint violated: " <> msg
    pog.PostgresqlError(code, _, msg) ->
      "PostgreSQL error " <> code <> ": " <> msg
    pog.UnexpectedArgumentCount(_, _) -> "Unexpected argument count"
    pog.UnexpectedArgumentType(_, _) -> "Unexpected argument type"
    pog.UnexpectedResultType(_) -> "Unexpected result type"
    pog.QueryTimeout -> "Query timeout"
    pog.ConnectionUnavailable -> "Connection unavailable"
  }
}

/// Run migration SQL file
fn run_migration(db: pog.Connection, file_path: String) -> Result(Nil, String) {
  case simplifile.read(file_path) {
    Error(_) -> Error("Cannot read migration file: " <> file_path)
    Ok(content) -> {
      // Split by semicolon and execute each statement
      let statements =
        content
        |> string.split(";")
        |> list.filter(fn(s) { string.trim(s) != "" })

      list.try_each(statements, fn(sql) {
        let trimmed = string.trim(sql)
        case trimmed {
          "" -> Ok(Nil)
          _ -> {
            let query = pog.query(trimmed)
            case pog.execute(query, db) {
              Ok(_) -> Ok(Nil)
              Error(e) -> Error("Migration failed: " <> format_pog_error(e))
            }
          }
        }
      })
    }
  }
}

/// Run all migrations in order
fn run_all_migrations(db: pog.Connection) -> Result(Nil, String) {
  let migrations = [
    "migrations_pg/001_schema_migrations.sql",
    "migrations_pg/002_usda_tables.sql",
    "migrations_pg/003_app_tables.sql",
    "migrations_pg/005_add_micronutrients_to_food_logs.sql",
    "migrations_pg/006_add_source_tracking.sql",
    "migrations_pg/009_auto_meal_planner.sql",
  ]

  list.try_each(migrations, fn(migration_path) {
    run_migration(db, migration_path)
  })
}

// =============================================================================
// Public API
// =============================================================================

/// Set up a test database with all migrations applied
/// This should be called once at the start of a test suite
/// Also cleans up orphan test databases from previous failed runs
pub fn setup_once() -> Result(Nil, String) {
  // Clean up any orphan test databases from previous failed runs
  let _ = cleanup_orphan_test_databases()

  // Create fresh test database
  case create_test_database() {
    Error(e) -> Error("Failed to create database: " <> e)
    Ok(_) -> {
      // Connect to test database
      case pog.start(test_db_config()) {
        Error(_) -> Error("Failed to connect to test database")
        Ok(started) -> {
          let db = started.data

          // Run all migrations
          case run_all_migrations(db) {
            Error(e) -> Error("Failed to run migrations: " <> e)
            Ok(_) -> Ok(Nil)
          }
        }
      }
    }
  }
}

/// Set up a test database with all migrations applied
/// Returns a connection to the test database
pub fn setup() -> Result(pog.Connection, String) {
  get_connection()
}

/// Clean up test database by dropping it
pub fn teardown() -> Result(Nil, String) {
  case pog.start(postgres_db_config()) {
    Error(_) -> Error("Cannot connect to PostgreSQL")
    Ok(started) -> {
      let db = started.data
      let query = pog.query("DROP DATABASE IF EXISTS " <> test_db_name <> ";")
      let result = case pog.execute(query, db) {
        Ok(_) -> Ok(Nil)
        Error(_) -> Error("Failed to drop test database")
      }

      // Cleanup pool
      process.kill(started.pid)
      result
    }
  }
}

/// Get a test database connection (assumes setup() has been called)
pub fn get_connection() -> Result(pog.Connection, String) {
  case pog.start(test_db_config()) {
    Error(_) ->
      Error(
        "Failed to connect to test database. Ensure PostgreSQL is running and test database exists.",
      )
    Ok(started) -> Ok(started.data)
  }
}

// =============================================================================
// Orphan Database Cleanup
// =============================================================================

/// Clean up all orphaned test databases (test_meal_planner_*)
/// This should be called at the start of test runs to clean up from failed runs
pub fn cleanup_orphan_test_databases() -> Result(Int, String) {
  case pog.start(postgres_db_config()) {
    Error(_) -> Error("Cannot connect to PostgreSQL")
    Ok(started) -> {
      let db = started.data

      // First, terminate connections to test databases
      let terminate_query =
        pog.query(
          "SELECT pg_terminate_backend(pid)
           FROM pg_stat_activity
           WHERE datname LIKE 'test_meal_planner_%'
           AND pid <> pg_backend_pid()",
        )
      let _ = pog.execute(terminate_query, db)

      // Get list of test databases to drop
      let list_query =
        pog.query(
          "SELECT datname FROM pg_database
           WHERE datname LIKE 'test_meal_planner_%'",
        )
        |> pog.returning(decode.at([0], decode.string))

      let result = case pog.execute(list_query, db) {
        Error(e) ->
          Error("Failed to list test databases: " <> format_pog_error(e))
        Ok(pog.Returned(_, db_names)) -> {
          // Drop each database
          let dropped =
            list.filter_map(db_names, fn(db_name) {
              let drop_query =
                pog.query("DROP DATABASE IF EXISTS " <> db_name <> ";")
              case pog.execute(drop_query, db) {
                Ok(_) -> Ok(db_name)
                Error(_) -> Error(Nil)
              }
            })

          let count = list.length(dropped)
          case count {
            0 -> Ok(0)
            n -> {
              io.println(
                "Cleaned up " <> int.to_string(n) <> " orphan test database(s)",
              )
              Ok(n)
            }
          }
        }
      }

      // Cleanup pool
      process.kill(started.pid)
      result
    }
  }
}
