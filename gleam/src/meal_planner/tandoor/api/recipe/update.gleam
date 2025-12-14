/// Recipe Update API
///
/// This module provides functions to update existing recipes in the Tandoor API.
import gleam/dynamic/decode
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{
  type ClientConfig, type Recipe, type TandoorError, NetworkError, ParseError,
  Recipe,
}
import meal_planner/tandoor/encoders/recipe/recipe_update_encoder
import meal_planner/tandoor/types/recipe/recipe_update.{type RecipeUpdate}

/// Update an existing recipe in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `recipe_id` - The ID of the recipe to update
/// * `update_data` - Partial recipe data to update
///
/// # Returns
/// Result with updated recipe or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let update_data = RecipeUpdate(
///   name: Some("Updated Recipe"),
///   description: None,
///   servings: Some(6),
///   servings_text: None,
///   working_time: None,
///   waiting_time: None,
/// )
/// let result = update_recipe(config, recipe_id: 42, update_data: update_data)
/// ```
pub fn update_recipe(
  config: ClientConfig,
  recipe_id recipe_id: Int,
  update_data update_data: RecipeUpdate,
) -> Result(Recipe, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  // Encode update data to JSON
  let request_body =
    recipe_update_encoder.encode_recipe_update(update_data)
    |> json.to_string

  // Build and execute PATCH request
  use req <- result.try(client.build_patch_request(config, path, request_body))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, recipe_decoder_internal()) {
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
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}

// ============================================================================
// Internal Decoder (matches client.gleam pattern)
// ============================================================================

/// Internal decoder for Recipe type
/// Matches the decoder pattern from client.gleam for consistency
fn recipe_decoder_internal() -> decode.Decoder(Recipe) {
  use id <- decode.field("id", decode.int)
  use name <- decode.field("name", decode.string)
  use slug <- decode.optional_field(
    "slug",
    None,
    decode.optional(decode.string),
  )
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use servings <- decode.field("servings", decode.int)
  use servings_text <- decode.optional_field(
    "servings_text",
    None,
    decode.optional(decode.string),
  )
  use working_time <- decode.optional_field(
    "working_time",
    None,
    decode.optional(decode.int),
  )
  use waiting_time <- decode.optional_field(
    "waiting_time",
    None,
    decode.optional(decode.int),
  )
  use created_at <- decode.optional_field(
    "created_at",
    None,
    decode.optional(decode.string),
  )
  use updated_at <- decode.optional_field(
    "updated_at",
    None,
    decode.optional(decode.string),
  )

  decode.success(Recipe(
    id: id,
    name: name,
    slug: slug,
    description: description,
    servings: servings,
    servings_text: servings_text,
    working_time: working_time,
    waiting_time: waiting_time,
    created_at: created_at,
    updated_at: updated_at,
  ))
}
