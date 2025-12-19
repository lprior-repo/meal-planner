/// CLI commands module
///
/// Glint-based command routing for the unified CLI+TUI application.
/// Routes to domain-specific command handlers based on subcommand.
import glint
import gleam/io
import meal_planner/config.{type Config}
import meal_planner/cli/domains/recipe
import meal_planner/cli/domains/plan
import meal_planner/cli/domains/nutrition
import meal_planner/cli/domains/scheduler
import meal_planner/cli/domains/web

/// Main CLI entry point - routes commands to appropriate domain handlers
pub fn run(config: Config, args: List(String)) -> Nil {
  // Build the Glint app with all domain subcommands
  let app =
    glint.new()
    |> glint.with_name("mp")
    |> glint.global_help("Meal Planner - CLI and TUI for meal planning")
    |> glint.add(at: ["recipe"], do: recipe.cmd(config))
    |> glint.add(at: ["plan"], do: plan.cmd(config))
    |> glint.add(at: ["nutrition"], do: nutrition.cmd(config))
    |> glint.add(at: ["scheduler"], do: scheduler.cmd(config))
    |> glint.add(at: ["web"], do: web.cmd(config))

  // Execute the Glint app with provided arguments
  let result = glint.run(app, args)

  case result {
    Ok(_) -> Nil
    Error(err) -> {
      io.println("Error: " <> glint.error_to_string(err))
    }
  }
}
