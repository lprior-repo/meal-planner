/// Tandoor CLI domain - handles recipe synchronization
///
/// This module provides CLI commands for:
/// - Syncing recipes from Tandoor
/// - Listing recipe categories
/// - Updating recipe metadata
import gleam/int
import gleam/io
import gleam/result
import glint
import meal_planner/config.{type Config}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Tandoor domain command for Glint CLI
pub fn cmd(_config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("Manage recipes and categories from Tandoor")
  use limit <- glint.flag(
    glint.int_flag("limit")
    |> glint.flag_help("Limit number of results")
    |> glint.flag_default(50),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["sync"] -> {
      io.println("Syncing recipes from Tandoor...")
      Ok(Nil)
    }
    ["categories"] -> {
      let limit_val = limit(flags) |> result.unwrap(50)
      io.println(
        "Fetching recipe categories (limit: " <> int.to_string(limit_val) <> ")",
      )
      Ok(Nil)
    }
    ["update"] -> {
      io.println("Updating recipe metadata in Tandoor...")
      Ok(Nil)
    }
    _ -> {
      io.println("Tandoor commands:")
      io.println("  mp tandoor sync")
      io.println("  mp tandoor categories --limit 100")
      io.println("  mp tandoor update")
      Ok(Nil)
    }
  }
}
