/// Diary CLI domain - handles FatSecret food diary management
///
/// This module provides CLI commands for:
/// - Viewing daily food logs
/// - Adding meals to diary
/// - Editing existing entries
/// - Deleting entries
/// - Viewing meal history
import gleam/io
import gleam/result
import glint
import meal_planner/config.{type Config}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Diary domain command for Glint CLI
pub fn cmd(_config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("View and manage FatSecret food diary entries")
  use date <- glint.flag(
    glint.string_flag("date")
    |> glint.flag_help("Date for diary (YYYY-MM-DD)")
    |> glint.flag_default("today"),
  )
  use _meal <- glint.flag(
    glint.string_flag("meal")
    |> glint.flag_help("Meal type (breakfast, lunch, dinner, snack)"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["view"] -> {
      let diary_date = date(flags) |> result.unwrap("today")
      io.println("Viewing diary for: " <> diary_date)
      io.println("(Diary view implementation pending)")
      Ok(Nil)
    }
    ["add"] -> {
      io.println("Adding entry to diary...")
      io.println("(Diary add implementation pending)")
      Ok(Nil)
    }
    ["edit"] -> {
      io.println("Editing diary entry...")
      io.println("(Diary edit implementation pending)")
      Ok(Nil)
    }
    ["delete"] -> {
      io.println("Deleting diary entry...")
      io.println("(Diary delete implementation pending)")
      Ok(Nil)
    }
    ["history"] -> {
      io.println("Viewing diary history...")
      io.println("(Diary history implementation pending)")
      Ok(Nil)
    }
    _ -> {
      io.println("Diary commands:")
      io.println("  mp diary view --date 2025-12-20")
      io.println("  mp diary add --meal breakfast")
      io.println("  mp diary edit --date 2025-12-20")
      io.println("  mp diary delete --date 2025-12-20")
      io.println("  mp diary history --days 7")
      Ok(Nil)
    }
  }
}
