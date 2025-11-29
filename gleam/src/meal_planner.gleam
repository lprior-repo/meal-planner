/// Meal Planner - Weekly meal planning with nutritional tracking
///
/// This module provides the main entry point for the meal planner application.
/// It handles CLI argument parsing and dispatches to the appropriate commands.

import gleam/io
import glint

/// Application entry point
pub fn main() {
  glint.new()
  |> glint.with_name("meal-planner")
  |> glint.pretty_help(glint.default_pretty_help())
  |> glint.add(at: [], do: default_command())
  |> glint.run(start_arguments())
}

/// Get command line arguments (Erlang specific)
@external(erlang, "init", "get_plain_arguments")
fn start_arguments() -> List(String)

/// Default command - sends weekly meal plan email
fn default_command() -> glint.Command(Nil) {
  use <- glint.command_help("Generate and send weekly meal plan")
  use _named, _args, _flags <- glint.command()

  io.println("Meal Planner v1.0.0")
  io.println("Run with --help for usage information")
  Nil
}
