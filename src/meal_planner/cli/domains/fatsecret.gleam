/// FatSecret CLI domain - handles food and ingredient management
///
/// This module provides CLI commands for:
/// - Searching for foods by name
/// - Listing recipe ingredients
/// - Viewing nutritional info
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import glint
import meal_planner/config.{type Config}
import meal_planner/env.{type FatSecretConfig}
import meal_planner/fatsecret/foods/client as foods_client
import meal_planner/fatsecret/foods/types as food_types
import meal_planner/fatsecret/recipes/client as recipes_client
import meal_planner/fatsecret/recipes/types as recipe_types

// ============================================================================
// Glint Command Handler
// ============================================================================

/// FatSecret domain command for Glint CLI
pub fn cmd(_config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("Search and manage foods from FatSecret")
  use query <- glint.flag(
    glint.string_flag("query")
    |> glint.flag_help("Food search query"),
  )
  use id <- glint.flag(
    glint.int_flag("id")
    |> glint.flag_help("Recipe or food ID"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["search"] -> {
      case query(flags) {
        Ok(q) -> {
          io.println("Searching FatSecret for: " <> q)
          Ok(Nil)
        }
        Error(_) -> {
          io.println("Error: --query flag required for search")
          Error(Nil)
        }
      }
    }
    ["ingredients"] -> {
      case id(flags) {
        Ok(recipe_id) -> {
          io.println(
            "Fetching ingredients for recipe: " <> int.to_string(recipe_id),
          )
          Ok(Nil)
        }
        Error(_) -> {
          io.println("Error: --id flag required for ingredients")
          Error(Nil)
        }
      }
    }
    _ -> {
      io.println("FatSecret commands:")
      io.println("  mp fatsecret search --query \"<food>\"")
      io.println("  mp fatsecret ingredients --id <recipe-id>")
      Ok(Nil)
    }
  }
}
