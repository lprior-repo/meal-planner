/// Recipe CLI domain - handles recipe management and FatSecret integration
///
/// This module provides CLI commands for:
/// - Searching for recipes (mp recipe search <QUERY>)
/// - Listing recipes (mp recipe list)
/// - Viewing recipe details (mp recipe detail <ID>)
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import glint
import meal_planner/config.{type Config}
import meal_planner/tandoor/client.{type ClientConfig, BearerAuth, ClientConfig}
import meal_planner/tandoor/recipe

// ============================================================================
// Public API - Test-facing Functions
// ============================================================================

/// Search for recipes by query string
///
/// Searches the Tandoor API for recipes matching the query.
/// Filters results by name and description (case-insensitive).
///
/// Returns formatted output string on success, error message on failure.
pub fn search_recipes(
  config: Config,
  query query: String,
  limit limit: Option(Int),
) -> Result(String, String) {
  // Validate query
  case query {
    "" -> Error("Error: Search query is required")
    _ -> {
      let tandoor_config = create_tandoor_config(config)
      let search_limit = option.unwrap(limit, 20)

      // Call Tandoor API
      case recipe.list_recipes(tandoor_config, Some(search_limit), Some(0)) {
        Ok(response) -> {
          // Filter results by query (case-insensitive)
          let query_lower = string.lowercase(query)
          let filtered_results =
            response.results
            |> list.filter(fn(r) {
              let name_match =
                r.name
                |> string.lowercase
                |> string.contains(query_lower)

              let description_match = case r.description {
                Some(desc) ->
                  desc
                  |> string.lowercase
                  |> string.contains(query_lower)
                None -> False
              }

              name_match || description_match
            })

          // Format and return results
          Ok(format_recipe_search_results(filtered_results, query: query))
        }
        Error(err) -> Error("Error searching recipes: " <> string.inspect(err))
      }
    }
  }
}

/// Format recipe search results for display
///
/// Formats a list of recipes into a readable string output.
/// Shows count, query, and each recipe's ID, name, and description.
pub fn format_recipe_search_results(
  recipes: List(recipe.Recipe),
  query query: String,
) -> String {
  case recipes {
    [] -> "No recipes found matching '" <> query <> "'"
    results -> {
      let count = list.length(results)
      let header =
        "Found "
        <> int.to_string(count)
        <> " recipe(s) matching '"
        <> query
        <> "':\n"

      let recipe_lines =
        results
        |> list.map(fn(r) {
          let description = case r.description {
            Some(desc) -> {
              // Truncate description to 80 chars
              let truncated = case string.length(desc) > 80 {
                True -> string.slice(desc, 0, 77) <> "..."
                False -> desc
              }
              "\n  " <> truncated
            }
            None -> ""
          }

          "[" <> int.to_string(r.id) <> "] " <> r.name <> description
        })
        |> string.join("\n\n")

      header <> "\n" <> recipe_lines
    }
  }
}

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

/// Handle search command (for CLI routing)
fn search_handler(
  config: Config,
  query: String,
  limit: Option(Int),
) -> Result(Nil, Nil) {
  case search_recipes(config, query: query, limit: limit) {
    Ok(output) -> {
      io.println(output)
      Ok(Nil)
    }
    Error(err) -> {
      io.println(err)
      Error(Nil)
    }
  }
}

/// List recipes with pagination and search
pub fn list_handler(
  config: Config,
  limit: Option(Int),
  offset: Option(Int),
  _search: Option(String),
) -> Result(Nil, Nil) {
  let tandoor_config = create_tandoor_config(config)

  // Call Tandoor API to list recipes
  case recipe.list_recipes(tandoor_config, limit: limit, offset: offset) {
    Ok(response) -> {
      // Display results
      io.println(
        "\nRecipes (showing "
        <> int.to_string(list.length(response.results))
        <> " of "
        <> int.to_string(response.count)
        <> "):",
      )
      io.println(
        "─────────────────────────────────────────────────────────────────────",
      )

      response.results
      |> list.each(fn(r) {
        let description = case r.description {
          Some(desc) -> " - " <> desc
          None -> ""
        }
        io.println(
          "  [" <> int.to_string(r.id) <> "] " <> r.name <> description,
        )
      })

      io.println(
        "─────────────────────────────────────────────────────────────────────",
      )

      // Show pagination info
      case response.next {
        Some(_) ->
          io.println("(More results available - use --offset to see next page)")
        None -> io.println("(End of results)")
      }

      Ok(Nil)
    }
    Error(err) -> {
      io.println("Error listing recipes: " <> string.inspect(err))
      Error(Nil)
    }
  }
}

// ============================================================================
// Glint Command Handler
// ============================================================================

/// Recipe domain command for Glint CLI
pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("Manage recipes from Tandoor")
  use limit <- glint.flag(
    glint.int_flag("limit")
    |> glint.flag_default(20)
    |> glint.flag_help("Maximum number of results"),
  )
  use _named, unnamed, flags <- glint.command()

  case unnamed {
    ["search", query] -> {
      // mp recipe search <QUERY> [--limit N]
      let limit_opt = case limit(flags) {
        Ok(l) -> Some(l)
        Error(_) -> None
      }
      search_handler(config, query, limit_opt)
    }
    ["search", ..rest] -> {
      // mp recipe search <MULTI WORD QUERY>
      let query = string.join(rest, " ")
      let limit_opt = case limit(flags) {
        Ok(l) -> Some(l)
        Error(_) -> None
      }
      search_handler(config, query, limit_opt)
    }
    ["search"] -> {
      // mp recipe search (no query)
      io.println("Error: Search query is required")
      io.println("")
      io.println("Usage: mp recipe search <QUERY> [--limit N]")
      io.println("")
      io.println("Examples:")
      io.println("  mp recipe search chicken")
      io.println("  mp recipe search 'pasta carbonara' --limit 5")
      Error(Nil)
    }
    ["detail", id_str] -> {
      // mp recipe detail <ID>
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
      // mp recipe list (placeholder)
      io.println("Recipes: (list command)")
      Ok(Nil)
    }
    _ -> {
      // Show help
      io.println("Recipe commands:")
      io.println("")
      io.println("  mp recipe search <QUERY> [--limit N]")
      io.println("    Search for recipes by name or description")
      io.println("")
      io.println("  mp recipe list [--limit N]")
      io.println("    List all recipes")
      io.println("")
      io.println("  mp recipe detail <ID>")
      io.println("    Show full recipe details")
      io.println("")
      io.println("Examples:")
      io.println("  mp recipe search chicken")
      io.println("  mp recipe search 'pasta carbonara' --limit 5")
      io.println("  mp recipe detail 42")
      Ok(Nil)
    }
  }
}
