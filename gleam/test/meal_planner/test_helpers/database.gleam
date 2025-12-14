/// Database test helpers for integration tests
///
/// Provides:
/// - Test database connection management
/// - Transaction helpers
/// - Database cleanup utilities
import envoy
import gleam/erlang/process
import gleam/int
import gleam/option.{Some}
import gleam/otp/actor
import gleam/result
import pog

/// Get a test database connection
///
/// Uses environment variables or defaults for test database.
/// Expects: DATABASE_URL or individual DB_* variables
pub fn get_test_connection() -> pog.Connection {
  let pool_name = process.new_name(prefix: "test_db")
  let config = case envoy.get("DATABASE_URL") {
    Ok(url) ->
      pog.url_config(pool_name, url)
      |> result.unwrap(pog.default_config(pool_name: pool_name))
    Error(_) -> {
      pog.default_config(pool_name: pool_name)
      |> pog.host(envoy.get("DB_HOST") |> result.unwrap("localhost"))
      |> pog.port(
        envoy.get("DB_PORT")
        |> result.try(int.parse)
        |> result.unwrap(5432),
      )
      |> pog.database(envoy.get("DB_NAME") |> result.unwrap("meal_planner"))
      |> pog.user(envoy.get("DB_USER") |> result.unwrap("postgres"))
      |> pog.password(
        envoy.get("DB_PASSWORD")
        |> result.map(Some)
        |> result.unwrap(Some("postgres")),
      )
    }
  }

  case pog.start(config) {
    Ok(actor.Started(_pid, conn)) -> conn
    Error(_) -> panic as "Failed to start test database connection"
  }
}

/// Run a function within a database transaction that auto-rolls back
///
/// This is perfect for integration tests - all changes are isolated
/// and automatically cleaned up.
///
/// Example:
/// ```gleam
/// pub fn my_test() {
///   use conn <- with_test_transaction
///
///   // Do test operations with conn
///   // Changes will be rolled back automatically
/// }
/// ```
pub fn with_test_transaction(test_fn: fn(pog.Connection) -> a) -> a {
  let conn = get_test_connection()

  // Start transaction
  let _ =
    pog.query("BEGIN")
    |> pog.execute(conn)

  // Run test
  let result = test_fn(conn)

  // Rollback transaction (cleanup)
  let _ =
    pog.query("ROLLBACK")
    |> pog.execute(conn)

  // Note: pog 4.x uses connection pools that are managed automatically
  // No explicit disconnect needed for test connections

  result
}
