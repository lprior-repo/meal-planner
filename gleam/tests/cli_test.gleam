//  CLI Module Tests
//  Tests for command line interface parsing and execution

import gleeunit
import gleeunit/should
import cli

pub fn main() {
  gleeunit.main()
}

pub fn parse_help_command_test() {
  cli.parse_args(["help"])
  |> should.equal(cli.Help)
}

pub fn parse_version_command_test() {
  cli.parse_args(["version"])
  |> should.equal(cli.Version)
}

pub fn parse_recipe_list_command_test() {
  cli.parse_args(["recipe", "list"])
  |> should.equal(cli.RecipeList)
}

pub fn parse_recipe_search_command_test() {
  cli.parse_args(["recipe", "search", "pasta"])
  |> should.equal(cli.RecipeSearch("pasta"))
}

pub fn parse_meal_plan_create_command_test() {
  cli.parse_args(["meal-plan", "create", "20088", "20094"])
  |> should.equal(cli.MealPlanCreate("20088", "20094"))
}

pub fn parse_unknown_command_test() {
  cli.parse_args(["invalid", "command"])
  |> should.equal(cli.Unknown("invalid command"))
}

pub fn execute_version_command_test() {
  cli.execute(cli.Version)
  |> should.equal(cli.Success("meal-planner v0.1.0"))
}

pub fn execute_help_command_returns_help_test() {
  case cli.execute(cli.Help) {
    cli.Help(_) -> True
    _ -> False
  }
  |> should.be_true()
}

pub fn format_success_result_test() {
  cli.format_result(cli.Success("Test message"))
  |> should.equal("Test message")
}

pub fn format_error_result_test() {
  cli.format_result(cli.Error("Something failed"))
  |> should.equal("Error: Something failed")
}
