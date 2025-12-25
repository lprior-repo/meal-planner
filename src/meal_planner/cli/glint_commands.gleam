/// CLI commands module
///
/// Glint-based command routing for the unified CLI+TUI application.
/// Routes to domain-specific command handlers based on subcommand.
import glint
import meal_planner/cli/domains/advisor
import meal_planner/cli/domains/diary/mod as diary
import meal_planner/cli/domains/fatsecret
import meal_planner/cli/domains/nutrition
import meal_planner/cli/domains/plan
import meal_planner/cli/domains/preferences
import meal_planner/cli/domains/recipe
import meal_planner/cli/domains/scheduler
import meal_planner/cli/domains/tandoor
import meal_planner/cli/domains/web
import meal_planner/config.{type Config}

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
    |> glint.add(at: ["fatsecret"], do: fatsecret.cmd(config))
    |> glint.add(at: ["tandoor"], do: tandoor.cmd(config))
    |> glint.add(at: ["web"], do: web.cmd(config))
    |> glint.add(at: ["diary"], do: diary.cmd(config))
    |> glint.add(at: ["preferences"], do: preferences.cmd(config))
    |> glint.add(at: ["advisor"], do: advisor.cmd(config))

  // Execute the Glint app with provided arguments
  let _ = glint.run(app, args)
  Nil
}
