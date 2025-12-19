/// Recipe CLI domain - handles recipe management and FatSecret integration
///
/// This module provides CLI commands for:
/// - Searching for recipes
/// - Listing recipes
/// - Adding new recipes
/// - Viewing recipe details
import glint
import gleam/int
import gleam/io
import gleam/result
import meal_planner/config.{type Config}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Recipe domain command for Glint CLI
pub fn cmd(_config: Config) -> glint.Command(Nil) {
  use <- glint.command_help("Manage recipes from Tandoor and FatSecret")
  use query <- glint.flag(
    glint.string_flag("query")
    |> glint.flag_help("Search query for recipes")
  )
  use id <- glint.flag(
    glint.int_flag("id")
    |> glint.flag_help("Recipe ID for details")
  )
  use named, unnamed, flags <- glint.command()

  case query(flags), id(flags) {
    Ok(q), _ -> {
      io.println("Searching for: " <> q)
      Ok(Nil)
    }
    _, Ok(recipe_id) -> {
      io.println("Fetching recipe ID: " <> int.to_string(recipe_id))
      Ok(Nil)
    }
    _, _ -> {
      case unnamed {
        ["list"] -> {
          io.println("Recipes: (list command)")
          Ok(Nil)
        }
        _ -> {
          io.println("Recipe commands:")
          io.println("  mp recipe list")
          io.println("  mp recipe --query \"<search>\"")
          io.println("  mp recipe --id <recipe-id>")
          Ok(Nil)
        }
      }
    }
  }
}
