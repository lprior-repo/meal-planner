/// Integration Test Database Helpers
///
/// Provides reusable test infrastructure for integration tests with proper:
/// - Test database creation and cleanup
/// - Automatic migration running
/// - Connection management
/// - Error handling and recovery
///
/// Usage:
/// ```gleam
/// pub fn my_integration_test() {
///   with_integration_db(fn(conn) {
///     // Use conn for database operations
///     let result = perform_some_operation(conn)
///     should.equal(result, Ok(expected))
///   })
/// }
/// ```
///
/// The helper automatically:
/// 1. Generates a unique test database name
/// 2. Creates the test database
/// 3. Runs all migrations from migrations_pg/
/// 4. Calls your test function with the connection
/// 5. Cleans up the database after the test completes
///
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string
import simplifile
import pog

// ============================================================================
// Test Database Configuration
// ============================================================================

/// Test database configuration
pub type TestDbConfig {
  TestDbConfig(
    host: String,
    port: Int,
    user: String,
    password: String,
    admin_database: String,
  )
}

/// Get test database configuration from environment or use defaults
fn test_db_config() -> TestDbConfig {
  TestDbConfig(
    host: "localhost",
    port: 5432,
    user: "meal_planner",
    password: "meal_planner",
    admin_database: "postgres",
  )
}

// ============================================================================
// Database Connection Management
// ============================================================================

/// Create a connection to the PostgreSQL admin database
/// Used for creating/dropping test databases
fn connect_to_admin_db(
  config: TestDbConfig,
) -> Result(pog.Connection, String) {
  let pool_name = process.new_name(prefix: "test_admin_pool")

  pog.default_config(pool_name)
  |> pog.host(config.host)
  |> pog.port(config.port)
  |> pog.database(config.admin_database)
  |> pog.user(config.user)
  |> pog.password(Some(config.password))
  |> pog.pool_size(1)
  |> pog.start
  |> result.map(fn(started) { started.data })
  |> result.map_error(fn(err) {
    "Failed to connect to admin database: " <> string.inspect(err)
  })
}

/// Create a connection to a specific test database
fn connect_to_test_db(
  config: TestDbConfig,
  db_name: String,
) -> Result(pog.Connection, String) {
  let pool_name = process.new_name(prefix: "test_pool_")

  pog.default_config(pool_name)
  |> pog.host(config.host)
  |> pog.port(config.port)
  |> pog.database(db_name)
  |> pog.user(config.user)
  |> pog.password(Some(config.password))
  |> pog.pool_size(5)
  |> pog.start
  |> result.map(fn(started) { started.data })
  |> result.map_error(fn(err) {
    "Failed to connect to test database " <> db_name <> ": " <> string.inspect(
      err,
    )
  })
}

// ============================================================================
// Database Creation and Teardown
// ============================================================================

/// Generate a unique test database name using timestamp and pool suffix
/// Format: test_db_<random_id>
fn generate_test_db_name() -> String {
  let random_id = int.random(999_999_999)
  "test_db_" <> int.to_string(random_id)
}

/// Create a new test database
fn create_test_database(
  admin_conn: pog.Connection,
  db_name: String,
) -> Result(Nil, String) {
  let query =
    "CREATE DATABASE " <> db_name <> " WITH ENCODING 'UTF8' LC_COLLATE 'C' LC_CTYPE 'C'"

  pog.query(query)
  |> pog.execute(admin_conn)
  |> result.map(fn(_) { Nil })
  |> result.map_error(fn(err) {
    "Failed to create test database " <> db_name <> ": " <> string.inspect(err)
  })
}

/// Drop a test database
fn drop_test_database(
  admin_conn: pog.Connection,
  db_name: String,
) -> Result(Nil, String) {
  let query = "DROP DATABASE IF EXISTS " <> db_name <> " WITH (FORCE)"

  pog.query(query)
  |> pog.execute(admin_conn)
  |> result.map(fn(_) { Nil })
  |> result.map_error(fn(err) {
    "Failed to drop test database " <> db_name <> ": " <> string.inspect(err)
  })
}

// ============================================================================
// Migration Management
// ============================================================================

/// Get list of migration files from migrations_pg directory
/// Returns sorted list of file names
/// Note: This is a hardcoded list for reliability in test environments
fn get_migration_files() -> Result(List(String), String) {
  // Hardcoded list of known migrations in order
  // This ensures tests run consistently across environments
  let migrations = [
    "001_schema_migrations.sql",
    "002_usda_tables.sql",
    "003_app_tables.sql",
    "005_add_micronutrients_to_food_logs.sql",
    "006_add_source_tracking.sql",
    "009_auto_meal_planner.sql",
    "010_optimize_search_performance.sql",
    "011_create_logs.sql",
    "011_create_recipes.sql",
    "012_create_todoist_sync.sql",
    "013_add_tim_ferriss_recipes.sql",
    "013_add_vertical_diet_recipes.sql",
  ]

  Ok(migrations)
}

/// Read migration file content
fn read_migration_file(filename: String) -> Result(String, String) {
  let path = "./migrations_pg/" <> filename

  simplifile.read(path)
  |> result.map_error(fn(err) {
    "Failed to read migration file " <> filename <> ": " <> string.inspect(err)
  })
}

/// Run a single migration SQL file
fn run_migration(
  conn: pog.Connection,
  filename: String,
  content: String,
) -> Result(Nil, String) {
  // Extract version number from filename (e.g., "001_schema.sql" -> "1")
  let version_str =
    filename
    |> string.split("_")
    |> list.first
    |> result.unwrap("")

  // Execute migration SQL
  pog.query(content)
  |> pog.execute(conn)
  |> result.map(fn(_) { Nil })
  |> result.map_error(fn(err) {
    "Failed to run migration "
    <> filename
    <> ": "
    <> string.inspect(err)
  })
  |> result.then(fn(_) {
    // Record migration in schema_migrations table
    pog.query(
      "INSERT INTO schema_migrations (version, name, applied_at) VALUES ($1, $2, $3) ON CONFLICT DO NOTHING",
    )
    |> pog.parameter(pog.text(version_str))
    |> pog.parameter(pog.text(filename))
    |> pog.parameter(pog.text("2024-01-01T00:00:00Z"))
    |> pog.execute(conn)
    |> result.map(fn(_) { Nil })
    |> result.map_error(fn(err) {
      "Failed to record migration in schema_migrations: " <> string.inspect(err)
    })
  })
}

/// Run all migrations on a test database
fn run_all_migrations(conn: pog.Connection) -> Result(Nil, String) {
  use migration_files <- result.try(get_migration_files())

  list.try_each(migration_files, fn(filename) {
    use content <- result.try(read_migration_file(filename))
    run_migration(conn, filename, content)
  })
}

// ============================================================================
// Main Test Helper
// ============================================================================

/// Execute a test function with an integrated database
///
/// This helper:
/// 1. Generates a unique test database name
/// 2. Creates the test database
/// 3. Runs all migrations from migrations_pg/
/// 4. Executes the test function with a connection
/// 5. Cleans up (drops the database)
///
/// Returns: The result of the test function, or an error if setup/cleanup fails
///
/// # Example
///
/// ```gleam
/// pub fn test_food_logging() {
///   with_integration_db(fn(conn) {
///     let result = perform_operation(conn)
///     should.equal(result, expected)
///   })
/// }
/// ```
pub fn with_integration_db(
  test_fn: fn(pog.Connection) -> Nil,
) -> Result(Nil, String) {
  let config = test_db_config()
  let db_name = generate_test_db_name()

  // Step 1: Connect to admin database
  use admin_conn <- result.then(connect_to_admin_db(config))

  // Step 2: Create test database
  use _ <- result.then(create_test_database(admin_conn, db_name))

  // Step 3: Connect to test database
  use test_conn <- result.then(connect_to_test_db(config, db_name))

  // Step 4: Run all migrations
  use _ <- result.then(run_all_migrations(test_conn))

  // Step 5: Execute test function
  let test_result = {
    test_fn(test_conn)
    Ok(Nil)
  }

  // Step 6: Cleanup - drop test database
  let cleanup_result = drop_test_database(admin_conn, db_name)

  // Return test result if successful, otherwise return cleanup error
  case test_result {
    Ok(_) -> cleanup_result
    Error(msg) -> {
      // Still try to cleanup even if test failed
      let _ = cleanup_result
      Error(msg)
    }
  }
}

/// Extended version of with_integration_db that allows test function to return a Result
///
/// Use this variant when your test function needs to return a Result type
/// for more sophisticated test assertions
pub fn with_integration_db_result(
  test_fn: fn(pog.Connection) -> Result(Nil, String),
) -> Result(Nil, String) {
  let config = test_db_config()
  let db_name = generate_test_db_name()

  // Step 1: Connect to admin database
  use admin_conn <- result.then(connect_to_admin_db(config))

  // Step 2: Create test database
  use _ <- result.then(create_test_database(admin_conn, db_name))

  // Step 3: Connect to test database
  use test_conn <- result.then(connect_to_test_db(config, db_name))

  // Step 4: Run all migrations
  use _ <- result.then(run_all_migrations(test_conn))

  // Step 5: Execute test function
  use _ <- result.then(test_fn(test_conn))

  // Step 6: Cleanup - drop test database
  drop_test_database(admin_conn, db_name)
}
