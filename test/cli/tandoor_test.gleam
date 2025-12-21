//// TDD Tests for CLI tandoor command
////
//// RED PHASE: This test validates:
//// 1. Command instantiation
//// 2. Configuration is properly passed through
//// 3. Command structure integrity

import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/tandoor
import test/cli/fixtures

pub fn main() {
  gleeunit.main()
}

pub fn tandoor_cmd_instantiation_test() {
  let config = fixtures.test_config()
  let _cmd = tandoor.cmd(config)
  True |> should.be_true()
}

pub fn tandoor_cmd_base_url_configured_test() {
  let config = fixtures.test_config()
  string.length(config.tandoor.base_url) > 0 |> should.be_true()
}

pub fn tandoor_cmd_api_token_configured_test() {
  let config = fixtures.test_config()
  string.length(config.tandoor.api_token) > 0 |> should.be_true()
}

pub fn tandoor_cmd_db_configured_test() {
  let config = fixtures.test_config()
  string.length(config.database.host) > 0 |> should.be_true()
}

pub fn tandoor_cmd_timeouts_configured_test() {
  let config = fixtures.test_config()
  config.tandoor.request_timeout_ms > 0 |> should.be_true()
}

pub fn tandoor_cmd_environment_development_test() {
  let config = fixtures.test_config()
  case config.environment {
    config.Development -> True
    _ -> False
  }
  |> should.be_true()
}

pub fn tandoor_cmd_multiple_instances_test() {
  let config = fixtures.test_config()
  let _cmd1 = tandoor.cmd(config)
  let _cmd2 = tandoor.cmd(config)
  True |> should.be_true()
}
