/// Tandoor Recipes API client
///
/// This module provides functions for interacting with the Tandoor Recipes API.
/// It handles recipe CRUD operations: list, get, create, update, and delete.
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import meal_planner/logger
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, ParseError, build_delete_request,
  build_get_request, build_patch_request, build_post_request, execute_and_parse,
}
import meal_planner/tandoor/recipe.{
  type Recipe, type RecipeCreateRequest, type RecipeDetail, type RecipeUpdate,
  recipe_decoder, recipe_detail_decoder,
}

// ============================================================================
// Public Types
// ============================================================================

/// Paginated recipe list response
pub type RecipeListResponse {
  RecipeListResponse(
    count: Int,
    next: Option(String),
    previous: Option(String),
    results: List(Recipe),
  )
}

// ============================================================================
// Recipe API Methods
// ============================================================================

/// List recipes from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `limit` - Optional limit for number of results (default: 100)
/// * `offset` - Optional offset for pagination (default: 0)
///
/// # Returns
/// Result with paginated recipe list or error
pub fn list_recipes(
  config: ClientConfig,
  limit: Option(Int),
  offset: Option(Int),
) -> Result(RecipeListResponse, TandoorError) {
  let limit_val = option.unwrap(limit, 100)
  let offset_val = option.unwrap(offset, 0)

  let query_params = [
    #("limit", int.to_string(limit_val)),
    #("offset", int.to_string(offset_val)),
  ]

  use req <- result.try(build_get_request(config, "/api/recipe/", query_params))
  logger.debug("Tandoor GET /api/recipe/")

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, recipe_list_decoder_internal()) {
        Ok(recipe_list) -> Ok(recipe_list)
        Error(errors) -> {
          let error_msg =
            "Failed to decode recipe list: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
}

/// Get a single recipe by ID from Tandoor API
///
/// Returns a RecipeDetail with full recipe information including steps,
/// ingredients, nutrition, and keywords.
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `recipe_id` - The ID of the recipe to fetch
///
/// # Returns
/// Result with recipe details or error
pub fn get_recipe(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(RecipeDetail, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  use req <- result.try(build_get_request(config, path, []))
  logger.debug("Tandoor GET " <> path)

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, recipe_detail_decoder()) {
        Ok(recipe) -> Ok(recipe)
        Error(errors) -> {
          let error_msg =
            "Failed to decode recipe detail: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
}

/// Create a new recipe in Tandoor API
///
/// Creates a new recipe with the provided data. Returns the created recipe
/// as a RecipeDetail with all fields populated by the server.
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `recipe_request` - Recipe data to create
///
/// # Returns
/// Result with created recipe details or error
pub fn create_recipe(
  config: ClientConfig,
  recipe_request: RecipeCreateRequest,
) -> Result(RecipeDetail, TandoorError) {
  let body = encode_create_recipe(recipe_request)

  use req <- result.try(build_post_request(config, "/api/recipe/", body))
  logger.debug("Tandoor POST /api/recipe/")

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, recipe_detail_decoder()) {
        Ok(recipe) -> Ok(recipe)
        Error(errors) -> {
          let error_msg =
            "Failed to decode created recipe: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
}

/// Update an existing recipe (supports partial updates)
///
/// Updates a recipe with the provided data. Only fields present in the
/// RecipeUpdate will be modified. Returns the updated RecipeDetail.
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `recipe_id` - The ID of the recipe to update
/// * `update_data` - Recipe update data
///
/// # Returns
/// Result with updated recipe details or error
pub fn update_recipe(
  config: ClientConfig,
  recipe_id: Int,
  update_data: RecipeUpdate,
) -> Result(RecipeDetail, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"
  let body = encode_update_recipe(update_data)

  use req <- result.try(build_patch_request(config, path, body))
  logger.debug("Tandoor PATCH " <> path)

  use resp <- result.try(execute_and_parse(req))

  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, recipe_detail_decoder()) {
        Ok(recipe) -> Ok(recipe)
        Error(errors) -> {
          let error_msg =
            "Failed to decode updated recipe: "
            <> string.join(
              list.map(errors, fn(e) {
                case e {
                  decode.DecodeError(expected, _found, path) ->
                    expected <> " at " <> string.join(path, ".")
                }
              }),
              ", ",
            )
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Invalid JSON response"))
  }
}

/// Delete a recipe from Tandoor API
///
/// Permanently deletes the recipe with the given ID.
///
/// # Arguments
/// * `config` - Client configuration with API token
/// * `recipe_id` - The ID of the recipe to delete
///
/// # Returns
/// Result with unit or error
pub fn delete_recipe(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  use req <- result.try(build_delete_request(config, path))
  logger.debug("Tandoor DELETE " <> path)

  use _resp <- result.try(execute_and_parse(req))
  Ok(Nil)
}


// ============================================================================
// Encoders
// ============================================================================

/// Encode a RecipeCreateRequest to JSON string
fn encode_create_recipe(request: RecipeCreateRequest) -> String {
  let working_time_json = case request.working_time {
    Some(val) -> json.int(val)
    None -> json.int(0)
  }

  let waiting_time_json = case request.waiting_time {
    Some(val) -> json.int(val)
    None -> json.int(0)
  }

  let description_json = case request.description {
    Some(val) -> json.string(val)
    None -> json.null()
  }

  let servings_text_json = case request.servings_text {
    Some(val) -> json.string(val)
    None -> json.null()
  }

  // Tandoor requires steps with ingredients array
  let empty_step =
    json.object([
      #("instruction", json.string("")),
      #("ingredients", json.array([], json.object)),
    ])

  let body =
    json.object([
      #("name", json.string(request.name)),
      #("description", description_json),
      #("servings", json.int(request.servings)),
      #("servings_text", servings_text_json),
      #("working_time", working_time_json),
      #("waiting_time", waiting_time_json),
      #("steps", json.array([empty_step], fn(x) { x })),
    ])

  json.to_string(body)
}

/// Encode a RecipeUpdate to JSON (only include provided fields)
fn encode_update_recipe(update: RecipeUpdate) -> String {
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

// ============================================================================
// Decoders
// ============================================================================

/// Decode a paginated recipe list response
fn recipe_list_decoder_internal() -> decode.Decoder(RecipeListResponse) {
  use count <- decode.field("count", decode.int)
  use next <- decode.field("next", decode.optional(decode.string))
  use previous <- decode.field("previous", decode.optional(decode.string))
  use results <- decode.field("results", decode.list(recipe_decoder()))

  decode.success(RecipeListResponse(
    count: count,
    next: next,
    previous: previous,
    results: results,
  ))
}
