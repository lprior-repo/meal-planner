/// Test database helper - manages PostgreSQL lifecycle for tests
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/otp/actor
import gleam/string
import meal_planner/storage
import pog
import simplifile

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
       name TEXT NOT NULL,
       applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
     )",
    )

  case pog.execute(schema_query, conn) {
    Ok(_) -> {
      // Get list of migration files
      let migration_dir = "migrations"
      case simplifile.read_directory(migration_dir) {
        Ok(files) -> {
          // Filter and sort migration files (001_*.sql, 002_*.sql, etc.)
          let migration_files =
            files
            |> list.filter(fn(f) { string.ends_with(f, ".sql") })
            |> list.sort(string.compare)

          // Execute each migration in order
          execute_migrations(conn, migration_dir, migration_files)
        }
        Error(_) ->
          Error(
            "Failed to read migrations directory: " <> migration_dir
            <> ". Ensure you run tests from the gleam directory.",
          )
      }
    }
    Error(err) ->
      Error("Failed to create schema_migrations: " <> format_error(err))
  }
}

/// Execute migration files in order
fn execute_migrations(
  conn: pog.Connection,
  dir: String,
  files: List(String),
) -> Result(Nil, String) {
  case files {
    [] -> Ok(Nil)
    [file, ..rest] -> {
      case execute_migration_file(conn, dir, file) {
        Ok(_) -> execute_migrations(conn, dir, rest)
        Error(e) -> Error(e)
      }
    }
  }
}

/// Execute a single migration file
fn execute_migration_file(
  conn: pog.Connection,
  dir: String,
  filename: String,
) -> Result(Nil, String) {
  // Extract version number from filename (e.g., "001_schema_migrations.sql" -> 1)
  let version = parse_migration_version(filename)

  // Check if migration already applied
  case is_migration_applied(conn, version) {
    Ok(True) -> {
      // Migration already applied, skip
      Ok(Nil)
    }
    Ok(False) -> {
      // Read migration file
      let filepath = dir <> "/" <> filename
      case simplifile.read(filepath) {
        Ok(sql_content) -> {
          // Execute the SQL
          case execute_sql_script(conn, sql_content) {
            Ok(_) -> {
              // Record migration as applied
              record_migration(conn, version, filename)
            }
            Error(e) ->
              Error(
                "Failed to execute migration " <> filename <> ": " <> e,
              )
          }
        }
        Error(_) -> Error("Failed to read migration file: " <> filepath)
      }
    }
    Error(e) ->
      Error("Failed to check migration status for " <> filename <> ": " <> e)
  }
}

/// Parse version number from migration filename
fn parse_migration_version(filename: String) -> Int {
  // Extract first 3 digits (e.g., "001_schema.sql" -> 1)
  case string.split(filename, "_") {
    [version_str, ..] ->
      case int.parse(version_str) {
        Ok(v) -> v
        Error(_) -> 0
      }
    _ -> 0
  }
}

/// Check if a migration version has been applied
fn is_migration_applied(conn: pog.Connection, version: Int) -> Result(Bool, String) {
  let query =
    pog.query("SELECT COUNT(*) as count FROM schema_migrations WHERE version = $1")
    |> pog.parameter(pog.int(version))

  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(count)
  }

  case pog.returning(query, decoder) |> pog.execute(conn) {
    Ok(pog.Returned(_, [count])) -> Ok(count > 0)
    Ok(_) -> Ok(False)
    Error(e) -> Error(format_error(e))
  }
}

/// Record a migration as applied
fn record_migration(
  conn: pog.Connection,
  version: Int,
  name: String,
) -> Result(Nil, String) {
  let query =
    pog.query(
      "INSERT INTO schema_migrations (version, name) VALUES ($1, $2) ON CONFLICT (version) DO NOTHING",
    )
    |> pog.parameter(pog.int(version))
    |> pog.parameter(pog.text(name))

  case pog.execute(query, conn) {
    Ok(_) -> Ok(Nil)
    Error(e) -> Error(format_error(e))
  }
}

/// Execute a SQL script (may contain multiple statements)
fn execute_sql_script(conn: pog.Connection, sql: String) -> Result(Nil, String) {
  // Split by semicolon to handle multiple statements
  // Filter out empty statements and comments
  let statements =
    string.split(sql, ";")
    |> list.map(string.trim)
    |> list.filter(fn(s) {
      !string.is_empty(s) && !string.starts_with(s, "--")
    })

  execute_statements(conn, statements)
}

/// Execute multiple SQL statements
fn execute_statements(
  conn: pog.Connection,
  statements: List(String),
) -> Result(Nil, String) {
  case statements {
    [] -> Ok(Nil)
    [stmt, ..rest] -> {
      case pog.execute(pog.query(stmt), conn) {
        Ok(_) -> execute_statements(conn, rest)
        Error(e) ->
          Error("Failed to execute statement: " <> format_error(e))
      }
    }
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
