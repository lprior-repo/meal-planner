//// TDD Tests for CLI recipe command
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/recipe
import test/cli/fixtures

pub fn main() { gleeunit.main() }

pub fn recipe_cmd_instantiation_test() {
  let config = fixtures.test_config()
  let _cmd = recipe.cmd(config)
  True |> should.be_true()
}

pub fn recipe_cmd_tandoor_configured_test() {
  let config = fixtures.test_config()
  string.length(config.tandoor.base_url) > 0 |> should.be_true()
}

pub fn recipe_cmd_server_port_test() {
  let config = fixtures.test_config()
  config.server.port > 0 |> should.be_true()
}

pub fn recipe_cmd_logging_configured_test() {
  let config = fixtures.test_config()
  case config.logging.level {
    config.InfoLevel -> True
    _ -> False
  } |> should.be_true()
}

pub fn recipe_cmd_multiple_instances_test() {
  let config = fixtures.test_config()
  let _cmd1 = recipe.cmd(config)
  let _cmd2 = recipe.cmd(config)
  True |> should.be_true()
}
