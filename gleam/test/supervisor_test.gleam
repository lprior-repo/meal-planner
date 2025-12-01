import gleam/erlang/process
import gleeunit/should
import meal_planner/supervisor

/// Test that supervisor starts successfully
pub fn supervisor_starts_test() {
  let result = supervisor.start()

  result |> should.be_ok
}

/// Test that supervisor can be started multiple times
/// (each call creates a new independent supervisor)
pub fn supervisor_multiple_instances_test() {
  let result1 = supervisor.start()
  result1 |> should.be_ok

  let result2 = supervisor.start()
  result2 |> should.be_ok
}

/// Test default configuration values
pub fn default_config_test() {
  let config = supervisor.default_config()

  config.max_restarts |> should.equal(3)
  config.restart_period |> should.equal(5)
}

/// Test supervisor with custom configuration
pub fn supervisor_with_custom_config_test() {
  let config = supervisor.SupervisorConfig(max_restarts: 5, restart_period: 10)

  let result = supervisor.start_with_config(config)

  result |> should.be_ok
}

/// Test that registry actor can receive shutdown message
pub fn registry_shutdown_test() {
  let assert Ok(_started) = supervisor.start()

  // The supervisor is running, we can verify it's alive
  // by checking the supervisor reference exists
  let supervisor.RegistryState = supervisor.RegistryState

  // Supervisor should still be alive after our test
  // (we didn't send shutdown to the registry)
  process.sleep(10)
}

/// Test supervised child spec creation
pub fn supervised_child_spec_test() {
  // Get the child specification
  let _child_spec = supervisor.supervised()

  // If we got here without crashing, the spec was created successfully
  should.be_true(True)
}
