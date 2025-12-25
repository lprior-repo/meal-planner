/// Diary CLI domain - main entry point and command registration
///
/// This module provides the main entry point for diary CLI commands.
/// It registers all diary subcommands with Glint and routes to appropriate handlers.
///
/// Available commands:
/// - view: Display food entries for a specific date
/// - delete: Remove a food entry from the diary
import gleam/io
import gleam/result
import glint
import meal_planner/cli/domains/diary/commands/delete
import meal_planner/cli/domains/diary/commands/view
import meal_planner/config.{type Config}

/// Diary domain command for Glint CLI
///
/// Registers all diary subcommands and handles routing to appropriate handlers.
pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("View and manage FatSecret food diary entries")
  use date <- glint.flag(
    glint.string_flag("date")
    |> glint.flag_help("Date for diary (YYYY-MM-DD or 'today')")
    |> glint.flag_default("today"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["view"] -> {
      let diary_date = date(flags) |> result.unwrap("today")
      view.view_handler(config, diary_date)
    }
    ["delete", entry_id] -> {
      delete.delete_handler(config, entry_id)
    }
    _ -> {
      io.println("Diary commands:")
      io.println("")
      io.println("  mp diary view [--date YYYY-MM-DD]")
      io.println(
        "    Display food entries for a specific date (default: today)",
      )
      io.println("")
      io.println("  mp diary delete <ENTRY_ID>")
      io.println("    Remove a food entry from the diary")
      io.println("")
      io.println("Examples:")
      io.println("  mp diary view")
      io.println("  mp diary view --date 2025-12-20")
      io.println("  mp diary delete 12345")
      Ok(Nil)
    }
  }
}
