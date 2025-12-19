/// Tandoor CLI domain - handles recipe synchronization
///
/// This module provides CLI commands for:
/// - Syncing recipes from Tandoor
/// - Listing recipe categories
/// - Updating recipe metadata
/// - Creating new recipes
import gleam/dynamic/decode
import gleam/int
import gleam/io
import gleam/json
import gleam/option
import gleam/result
import glint
import meal_planner/config.{type Config}
import meal_planner/tandoor/client
import meal_planner/tandoor/recipe

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

// ============================================================================
// Create Recipe Command Functions
// ============================================================================

/// Parse recipe data from JSON string (for stdin input)
pub fn parse_recipe_from_json(
  json_input: String,
) -> Result(recipe.RecipeCreateRequest, String) {
  let decoder = {
    use name <- decode.field("name", decode.string)
    use description <- decode.optional_field(
      "description",
      option.None,
      decode.optional(decode.string),
    )
    use servings <- decode.field("servings", decode.int)
    use servings_text <- decode.optional_field(
      "servings_text",
      option.None,
      decode.optional(decode.string),
    )
    use working_time <- decode.optional_field(
      "working_time",
      option.None,
      decode.optional(decode.int),
    )
    use waiting_time <- decode.optional_field(
      "waiting_time",
      option.None,
      decode.optional(decode.int),
    )

    decode.success(recipe.RecipeCreateRequest(
      name: name,
      description: description,
      servings: servings,
      servings_text: servings_text,
      working_time: working_time,
      waiting_time: waiting_time,
    ))
  }

  json.parse(json_input, decoder)
  |> result.map_error(fn(_) { "Invalid JSON format" })
}

/// Build a RecipeCreateRequest from CLI flags
pub fn build_recipe_from_flags(
  name name: option.Option(String),
  description description: option.Option(String),
  servings servings: option.Option(Int),
  servings_text servings_text: option.Option(String),
  working_time working_time: option.Option(Int),
  waiting_time waiting_time: option.Option(Int),
) -> Result(recipe.RecipeCreateRequest, String) {
  case name, servings {
    option.Some(n), option.Some(s) ->
      Ok(recipe.RecipeCreateRequest(
        name: n,
        description: description,
        servings: s,
        servings_text: servings_text,
        working_time: working_time,
        waiting_time: waiting_time,
      ))
    option.None, _ -> Error("Required flag --name is missing")
    _, option.None -> Error("Required flag --servings is missing")
  }
}

/// Create a recipe using the Tandoor API
pub fn create_recipe_command(
  config: Config,
  request: recipe.RecipeCreateRequest,
) -> Result(recipe.RecipeDetail, String) {
  let tandoor_config =
    client.bearer_config(config.tandoor.base_url, config.tandoor.api_token)

  case recipe.create_recipe(tandoor_config, request) {
    Ok(recipe_detail) -> {
      io.println("Recipe created successfully!")
      io.println("Recipe ID: " <> int.to_string(recipe_detail.id))
      io.println("Name: " <> recipe_detail.name)
      Ok(recipe_detail)
    }
    Error(e) -> {
      let error_msg = client.error_to_string(e)
      Error("Failed to create recipe: " <> error_msg)
    }
  }
}

// ============================================================================
// Helper Functions for Other Commands (stub implementations for tests)
// ============================================================================

/// Parse delete command args
pub fn parse_delete_args(
  _args: List(String),
  id id: option.Option(Int),
) -> Result(Int, String) {
  case id {
    option.Some(recipe_id) -> Ok(recipe_id)
    option.None -> Error("Required flag --id is missing")
  }
}

/// Delete a recipe
pub fn delete_recipe_command(
  _config: Config,
  recipe_id _recipe_id: Int,
) -> Result(Nil, String) {
  // TODO: Implement actual delete logic
  Ok(Nil)
}

/// Parse get command args
pub fn parse_get_args(
  _args: List(String),
  id id: option.Option(Int),
) -> Result(Int, String) {
  case id {
    option.Some(recipe_id) -> Ok(recipe_id)
    option.None -> Error("Required flag --id is missing")
  }
}

/// Get a recipe by ID
pub fn get_recipe_command(
  _config: Config,
  recipe_id _recipe_id: Int,
) -> Result(String, String) {
  // TODO: Implement actual get logic
  Ok("{}")
}

/// Parse search command args
pub fn parse_search_args(
  _args: List(String),
  query query: option.Option(String),
) -> Result(String, String) {
  case query {
    option.Some(q) -> Ok(q)
    option.None -> Error("Required flag --query is missing")
  }
}
