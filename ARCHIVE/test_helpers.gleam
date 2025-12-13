/// Test helpers for integration tests
///
/// This module provides utilities for setting up and tearing down test databases
/// and creating test data
///
import meal_planner/postgres
import pog

/// Setup a test database connection
pub fn setup_test_db() -> pog.Connection {
  let config =
    postgres.Config(
      host: "localhost",
      port: 5432,
      database: "meal_planner",
      user: "postgres",
      password: "",
      pool_size: 1,
      connection_timeout: 5000,
    )

  case postgres.connect(config) {
    Ok(conn) -> conn
    Error(_) -> panic as "Failed to connect to test database"
  }
}

/// Teardown test database (disconnect)
pub fn teardown_test_db(conn: pog.Connection) -> Nil {
  pog.disconnect(conn)
}
