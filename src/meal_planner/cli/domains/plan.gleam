/// Plan CLI domain - handles meal plan generation and management
///
/// This module provides CLI commands for:
/// - Generating meal plans
/// - Regenerating meal plans
/// - Syncing plans with Tandoor
/// - Viewing plan status
import gleam/int
import gleam/io
import gleam/option.{None}
import gleam/result
import glint
import meal_planner/config.{type Config}
import meal_planner/meal_sync.{MealSelection}
import meal_planner/orchestrator
import meal_planner/tandoor/client.{ClientConfig, SessionAuth}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Plan domain command for Glint CLI
pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("Generate and manage meal plans")
  use days <- glint.flag(
    glint.int_flag("days")
    |> glint.flag_help("Number of days to generate plan for")
    |> glint.flag_default(7),
  )
  use date <- glint.flag(
    glint.string_flag("date")
    |> glint.flag_help("Start date for meal plan (YYYY-MM-DD)"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["generate"] -> {
      let days_val = days(flags) |> result.unwrap(7)
      io.println(
        "Generating plan for " <> int.to_string(days_val) <> " days...",
      )

      // Create Tandoor client config from app config
      let tandoor_config = create_tandoor_config(config)

      // Create default meal selections (hardcoded for MVP)
      let meal_selections = create_default_meal_selections()

      // Call orchestrator to generate meal plan
      case orchestrator.plan_meals(tandoor_config, meal_selections) {
        Ok(plan) -> {
          io.println("\n" <> orchestrator.format_meal_plan(plan))
          Ok(Nil)
        }
        Error(err) -> {
          io.println("Error generating meal plan: " <> err)
          Error(Nil)
        }
      }
    }
    ["regenerate"] -> {
      let days_val = days(flags) |> result.unwrap(7)
      let start_date = date(flags) |> result.unwrap("2025-12-19")
      io.println(
        "Regenerating from "
        <> start_date
        <> " for "
        <> int.to_string(days_val)
        <> " days...",
      )
      Ok(Nil)
    }
    ["sync"] -> {
      io.println("Syncing meal plan with Tandoor...")
      Ok(Nil)
    }
    _ -> {
      io.println("Plan commands:")
      io.println("  mp plan generate --days 7")
      io.println("  mp plan regenerate --date 2025-12-19 --days 7")
      io.println("  mp plan sync")
      Ok(Nil)
    }
  }
}
