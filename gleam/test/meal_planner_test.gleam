import gleam/io
import gleeunit
import gleeunit/should
import test_db

pub fn main() {
  // Setup: Start PostgreSQL and create test database
  case test_db.setup() {
    Ok(conn) -> {
      io.println("✓ Test database ready")

      // Run all tests
      gleeunit.main()

      // Teardown: Clean up test database
      case test_db.teardown(conn) {
        Ok(_) -> io.println("✓ Test database cleaned up")
        Error(e) -> io.println("⚠ Failed to cleanup test database: " <> e)
      }
    }
    Error(e) -> {
      io.println("✗ Failed to setup test database: " <> e)
      io.println("")
      io.println("To fix this:")
      io.println("  1. Start PostgreSQL: sudo systemctl start postgresql")
      io.println("  2. Or enable auto-start: sudo systemctl enable postgresql")
      io.println("")

      // Still run tests that don't need database
      gleeunit.main()
    }
  }
}

// Basic sanity test
pub fn hello_world_test() {
  "hello"
  |> should.equal("hello")
}
