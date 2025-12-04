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
    "migrations_pg/009_auto_meal_planner.sql",
  ]

  list.try_each(migrations, fn(migration_path) {
    run_migration(db, migration_path)
  })
}

/// Initialize test database once
/// This is called automatically by gleeunit before running tests
pub fn setup() {
  // Try to connect to postgres and recreate test database
  let assert Ok(started) = pog.start(postgres_db_config())
  let postgres_db = started.data

  // Drop and recreate test database
  let drop_query = pog.query("DROP DATABASE IF EXISTS " <> test_db_name <> ";")
  let _ = pog.execute(drop_query, postgres_db)

  let create_query = pog.query("CREATE DATABASE " <> test_db_name <> ";")
  let assert Ok(_) = pog.execute(create_query, postgres_db)

  // Connect to test database and run migrations
  let assert Ok(test_started) = pog.start(test_db_config())
  let test_db = test_started.data

  let assert Ok(_) = run_all_migrations(test_db)

  Nil
}

/// Get a connection to the test database
/// This assumes setup() has already been called
pub fn get_test_db() -> pog.Connection {
  let assert Ok(started) = pog.start(test_db_config())
  started.data
}
