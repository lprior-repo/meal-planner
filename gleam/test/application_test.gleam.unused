import gleam/otp/actor
import gleeunit/should
import meal_planner/application

/// Test that the OTP application starts successfully
pub fn application_starts_test() {
  // Start the application
  let result = application.start()

  // Should succeed
  result |> should.be_ok

  // Should return AppState with supervisor
  let assert Ok(state) = result
  let application.AppState(supervisor: _) = state
}

/// Test that application can be started multiple times
/// (idempotent database initialization)
pub fn application_starts_multiple_times_test() {
  // First start
  let result1 = application.start()
  result1 |> should.be_ok

  // Second start should also succeed
  // (database tables already exist, but CREATE IF NOT EXISTS is idempotent)
  let result2 = application.start()
  result2 |> should.be_ok
}

/// Test error formatting
pub fn format_database_error_test() {
  let error = application.DatabaseInitError("connection failed")
  let formatted = application.format_error(error)

  formatted
  |> should.equal("Database initialization failed: connection failed")
}

/// Test supervisor error formatting
pub fn format_supervisor_timeout_error_test() {
  let error = application.SupervisorStartError(actor.InitTimeout)
  let formatted = application.format_error(error)

  formatted
  |> should.equal("Supervisor initialization timed out")
}

/// Test supervisor init failed error formatting
pub fn format_supervisor_init_failed_error_test() {
  let error = application.SupervisorStartError(actor.InitFailed("bad config"))
  let formatted = application.format_error(error)

  formatted
  |> should.equal("Supervisor initialization failed: bad config")
}
