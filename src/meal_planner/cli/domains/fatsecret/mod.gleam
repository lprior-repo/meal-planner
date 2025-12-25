/// FatSecret CLI Domain - Command Registration
///
/// This module provides the main Glint command registration for FatSecret operations.
/// It delegates to specialized command modules for actual implementation.
import gleam/io
import glint
import meal_planner/cli/domains/fatsecret/commands/ingredients
import meal_planner/cli/domains/fatsecret/commands/search
import meal_planner/config.{type Config}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// FatSecret domain command for Glint CLI
pub fn cmd(app_config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("Search and manage foods from FatSecret")
  use query <- glint.flag(
    glint.string_flag("query")
    |> glint.flag_help("Food search query"),
  )
  use _id <- glint.flag(
    glint.int_flag("id")
    |> glint.flag_help("Recipe or food ID"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["search"] -> {
      case query(flags) {
        Ok(search_query) -> search.search_handler(app_config, search_query)
        Error(_) -> {
          io.println("Error: --query flag required for search")
          Error(Nil)
        }
      }
    }
    ["ingredients", query_arg] -> {
      // Search for foods/ingredients with the given query
      case ingredients.ingredients_search_handler(app_config, query_arg) {
        Ok(_) -> Ok(Nil)
        Error(err_msg) -> {
          io.println("Error: " <> err_msg)
          Error(Nil)
        }
      }
    }
    ["ingredients"] -> {
      io.println("Error: Search query required")
      io.println("Usage: mp fatsecret ingredients <query>")
      io.println("Example: mp fatsecret ingredients chicken")
      Error(Nil)
    }
    _ -> {
      io.println("FatSecret commands:")
      io.println("  mp fatsecret search --query \"<food>\"")
      io.println("  mp fatsecret ingredients <query>")
      Ok(Nil)
    }
  }
}
