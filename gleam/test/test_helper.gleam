/// Global test setup - run once before all tests
/// This ensures the test database is created and migrated
import gleam/erlang/process
import gleam/option.{Some}
import pog

const test_db_name = "meal_planner_test"

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
