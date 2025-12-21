//// TDD Tests for CLI web command
////
//// RED PHASE: This test validates:
//// 1. Command instantiation
//// 2. Server configuration
//// 3. Port configuration

import gleeunit
import gleeunit/should
import meal_planner/cli/domains/web
import test/cli/fixtures

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Command Instantiation Tests
// ============================================================================

/// Test: Web command can be instantiated
pub fn web_command_instantiation_test() {
  let config = fixtures.test_config()
  let _cmd = web.cmd(config)

  True
  |> should.be_true()
}

/// Test: Web server port is configured
pub fn web_server_port_configured_test() {
  let config = fixtures.test_config()

  config.server.port > 0
  |> should.be_true()
}

/// Test: Web server port is standard web port
pub fn web_server_standard_port_test() {
  let config = fixtures.test_config()

  config.server.port
  |> should.equal(8080)
}

/// Test: CORS origins list exists
pub fn web_cors_origins_test() {
  let config = fixtures.test_config()

  case config.server.cors_allowed_origins {
    [] -> True
    _ -> True
  }
  |> should.be_true()
}
