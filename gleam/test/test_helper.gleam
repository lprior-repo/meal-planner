/// Global test setup - run once before all tests
/// This ensures the test database is created and migrated
import gleam/erlang/process
import gleam/list
import gleam/option.{Some}
import gleam/string
import pog
import simplifile

const test_db_name = "meal_planner_test"

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

fn test_db_config() -> pog.Config {
  let pool_name = process.new_name(prefix: "test_pool")
  pog.default_config(pool_name)
  |> pog.host("localhost")
  |> pog.port(5432)
  |> pog.database(test_db_name)
  |> pog.user("postgres")
  |> pog.password(Some("postgres"))
  |> pog.pool_size(5)
}

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
    _ -> "Unknown database error"
  }
}

fn run_migration(db: pog.Connection, file_path: String) -> Result(Nil, String) {
  case simplifile.read(file_path) {
    Error(_) -> Error("Cannot read migration file: " <> file_path)
    Ok(content) -> {
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

fn run_all_migrations(db: pog.Connection) -> Result(Nil, String) {
  let migrations = [
    "migrations_pg/001_schema_migrations.sql",
    "migrations_pg/002_usda_tables.sql",
    "migrations_pg/003_app_tables.sql",
    "migrations_pg/005_add_micronutrients_to_food_logs.sql",
    "migrations_pg/006_add_source_tracking.sql",
    // Skip 009 - requires users table which doesn't exist yet
  // "migrations_pg/009_auto_meal_planner.sql",
  ]

  list.try_each(migrations, fn(migration_path) {
    run_migration(db, migration_path)
  })
}

/// Initialize test database once
/// This is called automatically by gleeunit before running tests
///
/// NOTE: This assumes the test database already exists and has migrations run.
/// To set up the test database manually:
///   psql -U postgres -h localhost -c "DROP DATABASE IF EXISTS meal_planner_test;"
///   psql -U postgres -h localhost -c "CREATE DATABASE meal_planner_test;"
///   psql -U postgres -h localhost -d meal_planner_test -f migrations_pg/001_schema_migrations.sql
///   psql -U postgres -h localhost -d meal_planner_test -f migrations_pg/002_usda_tables.sql
///   psql -U postgres -h localhost -d meal_planner_test -f migrations_pg/003_app_tables.sql
///   psql -U postgres -h localhost -d meal_planner_test -f migrations_pg/005_add_micronutrients_to_food_logs.sql
///   psql -U postgres -h localhost -d meal_planner_test -f migrations_pg/006_add_source_tracking.sql
pub fn setup() {
  // Test database should already exist with migrations run
  // This is just a placeholder for future setup logic
  Nil
}

/// Get a connection to the test database
/// This assumes setup() has already been called
pub fn get_test_db() -> pog.Connection {
  let assert Ok(started) = pog.start(test_db_config())
  started.data
}
