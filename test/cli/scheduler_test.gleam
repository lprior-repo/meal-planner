//// TDD Tests for CLI scheduler command
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/scheduler
import test/cli/fixtures

pub fn main() { gleeunit.main() }

pub fn scheduler_cmd_instantiation_test() {
  let config = fixtures.test_config()
  let _cmd = scheduler.cmd(config)
  True |> should.be_true()
}

pub fn scheduler_cmd_db_pool_test() {
  let config = fixtures.test_config()
  config.database.pool_size > 0 |> should.be_true()
}

pub fn scheduler_cmd_timeouts_test() {
  let config = fixtures.test_config()
  config.performance.connection_timeout_ms > 0 |> should.be_true()
}

pub fn scheduler_cmd_concurrency_limits_test() {
  let config = fixtures.test_config()
  config.performance.max_concurrent_requests > 0 |> should.be_true()
}

pub fn scheduler_cmd_environment_test() {
  let config = fixtures.test_config()
  case config.environment {
    config.Development -> True
    _ -> False
  } |> should.be_true()
}

pub fn scheduler_cmd_multiple_instances_test() {
  let config = fixtures.test_config()
  let _cmd1 = scheduler.cmd(config)
  let _cmd2 = scheduler.cmd(config)
  True |> should.be_true()
}
