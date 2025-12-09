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
import gleam/option.{type Option, Some}
import gleam/result
import gleam/string
import pog
import simplifile

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
// External Functions
// ============================================================================

/// Get current Unix timestamp
@external(erlang, "erlang", "system_time")
fn erlang_now() -> Int

/// Get random integer
@external(erlang, "rand", "uniform")
fn erlang_random(max: Int) -> Int

// ============================================================================
// Database Creation and Teardown
// ============================================================================

/// Generate a unique test database name
/// Format: test_db_<timestamp>_<random>
fn generate_test_db_name() -> String {
  let timestamp = int.to_string(erlang_now())
  let random = int.to_string(erlang_random(999_999))
  "test_db_" <> timestamp <> "_" <> random
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
fn get_migration_files() -> Result(List(String), String) {
  let migrations_dir = "./migrations_pg"

  simplifile.read_directory(migrations_dir)
  |> result.map(fn(files) {
    files
    |> list.filter(fn(file) { string.ends_with(file, ".sql") })
    |> list.sort(string.compare)
  })
  |> result.map_error(fn(err) {
    "Failed to read migrations directory: " <> string.inspect(err)
  })
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
}

/// Run all migrations on a test database
fn run_all_migrations(conn: pog.Connection) -> Result(Nil, String) {
  use migration_files <- result.then(get_migration_files())

  list.try_each(migration_files, fn(filename) {
    use content <- result.then(read_migration_file(filename))
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
