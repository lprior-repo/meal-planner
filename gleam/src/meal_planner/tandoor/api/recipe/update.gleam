/// Recipe Update API
///
/// This module provides functions to update existing recipes in the Tandoor API.

import gleam/int
import gleam/json
import gleam/option.{type Option, Some}
import gleam/result
import meal_planner/logger
import meal_planner/tandoor/client.{
  type ClientConfig, type Recipe, type TandoorError,
}
import gleam/dynamic/decode

/// Request to update a recipe (partial update)
pub type RecipeUpdate {
  RecipeUpdate(
    name: Option(String),
    description: Option(String),
    servings: Option(Int),
    servings_text: Option(String),
    working_time: Option(Int),
    waiting_time: Option(Int),
  )
}

/// Update an existing recipe in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `recipe_id` - The ID of the recipe to update
/// * `update_data` - Partial recipe data to update
///
/// # Returns
/// Result with updated recipe or error
pub fn update_recipe(
  config: ClientConfig,
  recipe_id: Int,
  update_data: RecipeUpdate,
) -> Result(Recipe, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  // Build JSON body with only provided fields
  let body = encode_update(update_data)

  use req <- result.try(client.build_patch_request(config, path, body))
  logger.debug("Tandoor PATCH " <> path)

  use resp <- result.try(client.execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case client.recipe_decoder(json_data) {
        Ok(recipe) -> Ok(recipe)
        Error(error_msg) -> Error(client.ParseError(error_msg))
      }
    }
    Error(_) -> Error(client.ParseError("Invalid JSON response"))
  }
}

/// Encode RecipeUpdate to JSON string (only include provided fields)
fn encode_update(update: RecipeUpdate) -> String {
  let fields =
    []
    |> add_optional_field("name", update.name, json.string)
    |> add_optional_field("description", update.description, json.string)
    |> add_optional_field("servings", update.servings, json.int)
    |> add_optional_field("servings_text", update.servings_text, json.string)
    |> add_optional_field("working_time", update.working_time, json.int)
    |> add_optional_field("waiting_time", update.waiting_time, json.int)

  json.object(fields)
  |> json.to_string
}

/// Helper to add optional field to JSON object
fn add_optional_field(
  fields: List(#(String, json.Json)),
  key: String,
  value: Option(a),
  encoder: fn(a) -> json.Json,
) -> List(#(String, json.Json)) {
  case value {
    Some(v) -> [#(key, encoder(v)), ..fields]
    None -> fields
  }
}
