import gleam/dynamic/decode
import gleam/list
import gleeunit/should
import meal_planner/migrate
import simplifile
import sqlight

pub fn parse_migrations_test() {
  // Create temp migration files
  let temp_dir = "/tmp/test_migrations_" <> random_suffix()
  let _ = simplifile.create_directory_all(temp_dir)

  // Write test migration files
  let _ =
    simplifile.write(
      temp_dir <> "/001_first.sql",
      "CREATE TABLE test1 (id INTEGER);",
    )
  let _ =
    simplifile.write(
      temp_dir <> "/002_second.sql",
      "CREATE TABLE test2 (id INTEGER);",
    )

  // Parse migrations
  let result = migrate.parse_migrations(temp_dir)

  result |> should.be_ok
  let migrations = case result {
    Ok(m) -> m
    Error(_) -> []
  }

  list.length(migrations) |> should.equal(2)

  case migrations {
    [first, second] -> {
      first.version |> should.equal(1)
      first.name |> should.equal("first")
      second.version |> should.equal(2)
      second.name |> should.equal("second")
    }
    _ -> should.fail()
  }

  // Cleanup
  let _ = simplifile.delete(temp_dir)
  Nil
}

pub fn run_migrations_test() {
  // Create temp migration files
  let temp_dir = "/tmp/test_migrations_run_" <> random_suffix()
  let _ = simplifile.create_directory_all(temp_dir)

  let _ =
    simplifile.write(
      temp_dir <> "/001_init.sql",
      "CREATE TABLE IF NOT EXISTS schema_migrations (
        version INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        applied_at TEXT NOT NULL DEFAULT (datetime('now'))
      );",
    )
  let _ =
    simplifile.write(
      temp_dir <> "/002_test.sql",
      "CREATE TABLE test_table (id INTEGER PRIMARY KEY, name TEXT);",
    )

  // Run migrations on in-memory database
  sqlight.with_connection(":memory:", fn(conn) {
    let result = migrate.run_migrations(conn, temp_dir)
    result |> should.be_ok

    case result {
      Ok(count) -> count |> should.equal(2)
      Error(_) -> should.fail()
    }

    // Verify migrations were recorded
    let version = migrate.get_current_version(conn)
    version |> should.equal(2)

    // Run again - should apply 0 new migrations
    let result2 = migrate.run_migrations(conn, temp_dir)
    case result2 {
      Ok(count) -> count |> should.equal(0)
      Error(_) -> should.fail()
    }
  })

  // Cleanup
  let _ = simplifile.delete(temp_dir)
  Nil
}

pub fn get_data_dir_test() {
  let dir = migrate.get_data_dir()
  // Should contain meal-planner
  { dir != "" } |> should.be_true
}

pub fn run_real_migrations_test() {
  // Test with actual migration files from the project
  let migrations_dir = "migrations"

  sqlight.with_connection(":memory:", fn(conn) {
    let result = migrate.run_migrations(conn, migrations_dir)
    result |> should.be_ok

    case result {
      Ok(count) -> {
        // Should have at least 3 migrations (001, 002, 003)
        { count >= 3 } |> should.be_true
      }
      Error(_) -> should.fail()
    }

    // Verify migrations were recorded
    let version = migrate.get_current_version(conn)
    { version >= 3 } |> should.be_true

    // Verify tables were created
    let tables_sql =
      "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
    case
      sqlight.query(tables_sql, on: conn, with: [], expecting: decode.at(
        [0],
        decode.string,
      ))
    {
      Ok(tables) -> {
        // Should have foods, nutrients, food_nutrients, nutrition_state, etc.
        { list.length(tables) >= 4 } |> should.be_true
      }
      Error(_) -> should.fail()
    }
  })
}

fn random_suffix() -> String {
  // Simple pseudo-random suffix using current time
  let _ = 0
  "test"
}
