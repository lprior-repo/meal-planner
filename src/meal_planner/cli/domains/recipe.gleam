/// Recipe CLI domain - handles recipe management and FatSecret integration
///
/// This module provides CLI commands for:
/// - Searching for recipes
/// - Listing recipes
/// - Adding new recipes
/// - Viewing recipe details
import gleam/float
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import glint
import meal_planner/config.{type Config}
import meal_planner/tandoor/client.{type ClientConfig, BearerAuth, ClientConfig}
import meal_planner/tandoor/recipe

// ============================================================================
// Helper Functions
// ============================================================================

/// Create Tandoor client config from app config
fn create_tandoor_config(config: Config) -> ClientConfig {
  ClientConfig(
    base_url: config.tandoor.base_url,
    auth: BearerAuth(token: config.tandoor.api_token),
    timeout_ms: config.tandoor.request_timeout_ms,
    retry_on_transient: True,
    max_retries: 3,
  )
}

/// Format recipe detail for display
fn format_recipe_detail(recipe_detail: recipe.RecipeDetail) -> String {
  let description = case recipe_detail.description {
    Some(desc) -> "\nDescription: " <> desc
    None -> ""
  }

  let source_url = case recipe_detail.source_url {
    Some(url) -> "\nSource: " <> url
    None -> ""
  }

  let nutrition = case recipe_detail.nutrition {
    Some(n) -> {
      "\n\nNutrition (per serving):"
      <> "\n  Calories: "
      <> format_float(n.calories)
      <> "\n  Protein: "
      <> format_float(n.proteins)
      <> "g"
      <> "\n  Carbs: "
      <> format_float(n.carbohydrates)
      <> "g"
      <> "\n  Fat: "
      <> format_float(n.fats)
      <> "g"
    }
    None -> ""
  }

  let keywords = case recipe_detail.keywords {
    [] -> ""
    keywords -> {
      let keyword_names =
        keywords
        |> list.map(fn(k) { k.name })
        |> string.join(", ")
      "\nTags: " <> keyword_names
    }
  }

  let steps = case recipe_detail.steps {
    [] -> ""
    steps -> {
      "\n\nSteps:\n"
      <> {
        steps
        |> list.index_map(fn(step, idx) {
          let step_name = case step.name {
            "" -> ""
            name -> name <> ": "
          }
          int.to_string(idx + 1) <> ". " <> step_name <> step.instruction
        })
        |> string.join("\n")
      }
    }
  }

  "Recipe: "
  <> recipe_detail.name
  <> description
  <> "\nServings: "
  <> int.to_string(recipe_detail.servings)
  <> source_url
  <> keywords
  <> nutrition
  <> steps
}

/// Format optional float for display
fn format_float(value: Float) -> String {
  // Round to 1 decimal place
  let rounded = { value *. 10.0 } |> float.truncate |> int.to_float
  let result = rounded /. 10.0
  string.inspect(result)
}

/// Get recipe detail by ID
pub fn detail_handler(config: Config, recipe_id: Int) -> Result(Nil, Nil) {
  let tandoor_config = create_tandoor_config(config)

  case recipe.get_recipe(tandoor_config, recipe_id: recipe_id) {
    Ok(recipe_detail) -> {
      io.println(format_recipe_detail(recipe_detail))
      Ok(Nil)
    }
    Error(client.NotFoundError(_)) -> {
      io.println(
        "Error: Recipe not found (ID: " <> int.to_string(recipe_id) <> ")",
      )
      Error(Nil)
    }
    Error(err) -> {
      io.println("Error fetching recipe: " <> string.inspect(err))
      Error(Nil)
    }
  }
}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Recipe domain command for Glint CLI
pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("Manage recipes from Tandoor and FatSecret")
  use query <- glint.flag(
    glint.string_flag("query")
    |> glint.flag_help("Search query for recipes"),
  )
  use id <- glint.flag(
    glint.int_flag("id")
    |> glint.flag_help("Recipe ID for details"),
  )
  use _named, unnamed, flags <- glint.command()

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
        ["detail", id_str] -> {
          // Parse recipe ID from string
          case int.parse(id_str) {
            Ok(recipe_id) -> detail_handler(config, recipe_id)
            Error(_) -> {
              io.println(
                "Error: Invalid recipe ID. Expected a number, got: " <> id_str,
              )
              Error(Nil)
            }
          }
        }
        ["list"] -> {
          io.println("Recipes: (list command)")
          Ok(Nil)
        }
        _ -> {
          io.println("Recipe commands:")
          io.println("  mp recipe list")
          io.println("  mp recipe detail <recipe-id>")
          io.println("  mp recipe --query \"<search>\"")
          io.println("  mp recipe --id <recipe-id>")
          Ok(Nil)
        }
      }
    }
  }
}
