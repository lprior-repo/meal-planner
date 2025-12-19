/// Plan CLI domain - handles meal plan generation and management
///
/// This module provides CLI commands for:
/// - Generating meal plans
/// - Regenerating meal plans
/// - Syncing plans with Tandoor
/// - Viewing plan status
import glint
import gleam/int
import gleam/io
import gleam/result
import meal_planner/config.{type Config}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Plan domain command for Glint CLI
pub fn cmd(_config: Config) -> glint.Command(Nil) {
  use <- glint.command_help("Generate and manage meal plans")
  use days <- glint.flag(
    glint.int_flag("days")
    |> glint.flag_help("Number of days to generate plan for")
    |> glint.flag_default(7)
  )
  use date <- glint.flag(
    glint.string_flag("date")
    |> glint.flag_help("Start date for meal plan (YYYY-MM-DD)")
  )
  use named, unnamed, flags <- glint.command()

  case unnamed {
    ["generate"] -> {
      let days_val = days(flags) |> result.unwrap(7)
      io.println("Generating plan for " <> int.to_string(days_val) <> " days...")
      Ok(Nil)
    }
    ["regenerate"] -> {
      let days_val = days(flags) |> result.unwrap(7)
      let start_date = date(flags) |> result.unwrap("2025-12-19")
      io.println(
        "Regenerating from " <> start_date <> " for " <> int.to_string(days_val)
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
