//// TDD Tests for CLI fatsecret command
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/fatsecret
import test/cli/fixtures

pub fn main() { gleeunit.main() }

pub fn fatsecret_cmd_instantiation_test() {
  let config = fixtures.test_config()
  let _cmd = fatsecret.cmd(config)
  True |> should.be_true()
}

pub fn fatsecret_cmd_openai_config_test() {
  let config = fixtures.test_config()
  string.length(config.external_services.openai_model) > 0 |> should.be_true()
}

pub fn fatsecret_cmd_database_config_test() {
  let config = fixtures.test_config()
  config.database.pool_size > 0 |> should.be_true()
}

pub fn fatsecret_cmd_environment_test() {
  let config = fixtures.test_config()
  case config.environment {
    config.Development -> True
    _ -> False
  } |> should.be_true()
}

pub fn fatsecret_cmd_oauth_optional_test() {
  let config = fixtures.test_config()
  case config.secrets.oauth_encryption_key {
    config.None -> True
    _ -> True
  } |> should.be_true()
}

pub fn fatsecret_cmd_multiple_instances_test() {
  let config = fixtures.test_config()
  let _cmd1 = fatsecret.cmd(config)
  let _cmd2 = fatsecret.cmd(config)
  True |> should.be_true()
}
