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
pub fn cmd(config: Config) -> glint.Command(Result(Nil, Nil)) {
  use <- glint.command_help("Manage recipes and categories from Tandoor")
  use limit <- glint.flag(
    glint.int_flag("limit")
    |> glint.flag_help("Limit number of results")
    |> glint.flag_default(50),
  )
  use id <- glint.flag(
    glint.int_flag("id") |> glint.flag_help("Recipe ID for delete command"),
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
    ["delete"] -> {
      let recipe_id_opt = case id(flags) {
        Ok(id_val) -> option.Some(id_val)
        Error(_) -> option.None
      }
      case parse_delete_args(["delete"], id: recipe_id_opt) {
        Ok(recipe_id) -> {
          case delete_recipe_command(config, recipe_id: recipe_id) {
            Ok(_) -> Ok(Nil)
            Error(msg) -> {
              io.println(msg)
              Error(Nil)
            }
          }
        }
        Error(msg) -> {
          io.println(msg)
          io.println("Usage: mp tandoor delete --id <recipe_id>")
          Error(Nil)
        }
      }
    }
    _ -> {
      io.println("Tandoor commands:")
      io.println("  mp tandoor sync")
      io.println("  mp tandoor categories --limit 100")
      io.println("  mp tandoor update")
      io.println("  mp tandoor delete --id <recipe_id>")
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
/// Delete a recipe
pub fn delete_recipe_command(
  config: Config,
  recipe_id recipe_id: Int,
) -> Result(Nil, String) {
  let tandoor_config =
    client.bearer_config(config.tandoor.base_url, config.tandoor.api_token)

  case recipe.delete_recipe(tandoor_config, recipe_id: recipe_id) {
    Ok(_) -> {
      io.println(
        "Recipe " <> int.to_string(recipe_id) <> " deleted successfully",
      )
      Ok(Nil)
    }
    Error(e) -> {
      let error_msg = client.error_to_string(e)
      Error("Failed to delete recipe: " <> error_msg)
    }
  }
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

// ============================================================================
// Update Recipe Command Functions
// ============================================================================

/// Parse update command args
pub fn parse_update_args(
  _args: List(String),
  id id: option.Option(Int),
) -> Result(Int, String) {
  case id {
    option.Some(recipe_id) if recipe_id > 0 -> Ok(recipe_id)
    option.Some(_) -> Error("Recipe ID must be a positive integer")
    option.None -> Error("Required flag --id is missing")
  }
}

/// Build a RecipeUpdate from CLI flags, validating that at least one field is provided
pub fn build_recipe_update_from_flags(
  name name: option.Option(String),
  description description: option.Option(String),
  servings servings: option.Option(Int),
  servings_text servings_text: option.Option(String),
  working_time working_time: option.Option(Int),
  waiting_time waiting_time: option.Option(Int),
) -> Result(recipe.RecipeUpdate, String) {
  // Validate at least one field is provided
  let has_field = case
    name,
    description,
    servings,
    servings_text,
    working_time,
    waiting_time
  {
    option.None, option.None, option.None, option.None, option.None, option.None
    -> False
    _, _, _, _, _, _ -> True
  }

  case has_field {
    False -> Error("At least one field must be specified for update")
    True -> {
      // Validate field values
      use _ <- result.try(validate_name(name))
      use _ <- result.try(validate_servings(servings))
      use _ <- result.try(validate_working_time(working_time))
      use _ <- result.try(validate_waiting_time(waiting_time))

      Ok(recipe.RecipeUpdate(
        name: name,
        description: description,
        servings: servings,
        servings_text: servings_text,
        working_time: working_time,
        waiting_time: waiting_time,
      ))
    }
  }
}

fn validate_name(name: option.Option(String)) -> Result(Nil, String) {
  case name {
    option.Some("") -> Error("Field 'name' cannot be empty")
    option.Some(_) -> Ok(Nil)
    option.None -> Ok(Nil)
  }
}

fn validate_servings(servings: option.Option(Int)) -> Result(Nil, String) {
  case servings {
    option.Some(s) if s <= 0 -> Error("Field 'servings' must be positive")
    option.Some(_) -> Ok(Nil)
    option.None -> Ok(Nil)
  }
}

fn validate_working_time(
  working_time: option.Option(Int),
) -> Result(Nil, String) {
  case working_time {
    option.Some(t) if t < 0 ->
      Error("Field 'working_time' must be non-negative")
    option.Some(_) -> Ok(Nil)
    option.None -> Ok(Nil)
  }
}

fn validate_waiting_time(
  waiting_time: option.Option(Int),
) -> Result(Nil, String) {
  case waiting_time {
    option.Some(t) if t < 0 ->
      Error("Field 'waiting_time' must be non-negative")
    option.Some(_) -> Ok(Nil)
    option.None -> Ok(Nil)
  }
}

/// Update a recipe using the Tandoor API
pub fn update_recipe_command(
  config: Config,
  recipe_id recipe_id: Int,
  name name: option.Option(String),
  description description: option.Option(String),
  servings servings: option.Option(Int),
  servings_text servings_text: option.Option(String),
  working_time working_time: option.Option(Int),
  waiting_time waiting_time: option.Option(Int),
) -> Result(recipe.RecipeDetail, String) {
  // Build update data from flags
  use update_data <- result.try(build_recipe_update_from_flags(
    name: name,
    description: description,
    servings: servings,
    servings_text: servings_text,
    working_time: working_time,
    waiting_time: waiting_time,
  ))

  let tandoor_config =
    client.bearer_config(config.tandoor.base_url, config.tandoor.api_token)

  case
    recipe.update_recipe(
      tandoor_config,
      recipe_id: recipe_id,
      data: update_data,
    )
  {
    Ok(recipe_detail) -> {
      io.println("Recipe updated successfully!")
      io.println("Recipe ID: " <> int.to_string(recipe_detail.id))
      io.println("Name: " <> recipe_detail.name)
      Ok(recipe_detail)
    }
    Error(e) -> {
      let error_msg = client.error_to_string(e)
      Error(
        "Failed to update recipe "
        <> int.to_string(recipe_id)
        <> ": "
        <> error_msg,
      )
    }
  }
}
