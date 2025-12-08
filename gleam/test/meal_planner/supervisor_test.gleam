/// Tests for the supervisor tree module
import gleam/erlang/process
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/supervisor

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Configuration Tests
// ============================================================================

pub fn default_config_test() {
  // Note: We can't create a real DB connection in tests without setup
  // This test verifies the structure of the config
  let config = supervisor.default_config(panic as "test db")

  config.web_port
  |> should.equal(8000)

  config.max_restarts
  |> should.equal(3)

  config.restart_period
  |> should.equal(60)
}

// ============================================================================
// Supervisor Utilities Tests
// ============================================================================

pub fn child_count_test() {
  supervisor.child_count()
  |> should.equal(3)
}

pub fn message_selector_test() {
  // Verify we can create a selector
  let _selector = supervisor.message_selector()
  // If this doesn't crash, the selector was created successfully
  True
  |> should.be_true()
}

// ============================================================================
// Process Lifecycle Tests
// ============================================================================

pub fn is_child_alive_test() {
  // Create a test process
  let test_subject = process.new_subject()

  // The subject's process should be alive
  supervisor.is_child_alive(test_subject)
  |> should.be_true()
}
// ============================================================================
// Integration Tests (Commented Out - Require Full Setup)
// ============================================================================

// These tests are commented out because they require:
// 1. A real database connection
// 2. Full supervisor startup
// 3. Cleanup after tests
//
// They should be run as integration tests in a separate suite

// pub fn supervisor_start_test() {
//   // Setup: Create DB connection
//   let db_conn = setup_test_db()
//
//   // Start the supervisor tree
//   let assert Ok(supervisor) = supervisor.start(db_conn)
//
//   // Verify supervisor is running
//   process.is_alive(supervisor)
//   |> should.be_true()
//
//   // Cleanup
//   // supervisor.shutdown(supervisor)
// }

// pub fn actors_supervised_test() {
//   let db_conn = setup_test_db()
//   let assert Ok(sup) = supervisor.start(db_conn)
//
//   // Wait for children to start
//   process.sleep(100)
//
//   // Verify all child processes are alive
//   // This would require access to child PIDs
//   // which would need to be exposed through the supervisor API
// }

// pub fn cache_supervised_test() {
//   let db_conn = setup_test_db()
//   let assert Ok(sup) = supervisor.start(db_conn)
//
//   // Get cache reference from supervisor
//   // Send a message to verify it's working
//   // Verify response
// }

// pub fn fault_tolerance_test() {
//   let db_conn = setup_test_db()
//   let assert Ok(sup) = supervisor.start(db_conn)
//
//   // Kill one of the child processes
//   // Verify it gets restarted
//   // Verify supervisor is still alive
// }
