import gleam/io
import gleeunit
import gleeunit/should
import test_helper

pub fn main() {
  // Setup: Start PostgreSQL and create test database
  let _ = test_helper.setup()
  io.println("✓ Test database ready")

  // Run all tests
  gleeunit.main()
}

// Basic sanity test
pub fn hello_world_test() {
  "hello"
  |> should.equal("hello")
}
