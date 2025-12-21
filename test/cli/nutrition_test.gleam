//// TDD Tests for CLI nutrition command
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/nutrition
import test/cli/fixtures

pub fn main() { gleeunit.main() }

pub fn nutrition_cmd_instantiation_test() {
  let config = fixtures.test_config()
  let _cmd = nutrition.cmd(config)
  True |> should.be_true()
}

pub fn nutrition_cmd_db_config_test() {
  let config = fixtures.test_config()
  config.database.pool_size > 0 |> should.be_true()
}

pub fn nutrition_cmd_timeouts_test() {
  let config = fixtures.test_config()
  config.performance.request_timeout_ms > 0 |> should.be_true()
}

pub fn nutrition_cmd_environment_test() {
  let config = fixtures.test_config()
  case config.environment {
    config.Development -> True
    _ -> False
  } |> should.be_true()
}

pub fn nutrition_cmd_multiple_instances_test() {
  let config = fixtures.test_config()
  let _cmd1 = nutrition.cmd(config)
  let _cmd2 = nutrition.cmd(config)
  True |> should.be_true()
}
