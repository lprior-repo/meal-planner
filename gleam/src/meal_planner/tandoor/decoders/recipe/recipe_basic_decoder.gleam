/// Recipe decoder for basic Recipe type (list view) from client.gleam
///
/// This module provides JSON decoders for the Recipe type used in Tandoor API
/// list endpoints. This is the basic recipe type without nested steps/ingredients.
import gleam/dynamic
import gleam/dynamic/decode
import gleam/option.{None}
import meal_planner/tandoor/client.{type Recipe, Recipe}
import meal_planner/tandoor/decoders/decoder_combinators

/// Decoder for Recipe from JSON (internal)
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

/// Decode a Recipe from JSON
///
/// This function takes raw JSON dynamic data and decodes it into a Recipe type.
/// It handles all optional fields and provides detailed error messages on failure.
///
/// # Example
/// ```gleam
/// import gleam/json
/// import gleam/dynamic/decode
/// import meal_planner/tandoor/decoders/recipe/recipe_basic_decoder
///
/// let json_str = "{\"id\": 1, \"name\": \"Pasta\", ...}"
/// case json.parse(json_str, using: decode.dynamic) {
///   Ok(json_data) -> {
///     case recipe_basic_decoder.decoder(json_data) {
///       Ok(recipe) -> // Use recipe
///       Error(msg) -> // Handle error
///     }
///   }
///   Error(_) -> // Handle JSON parse error
/// }
/// ```
pub fn decoder(json_value: dynamic.Dynamic) -> Result(Recipe, String) {
  decoder_combinators.run_decoder(
    json_value,
    recipe_decoder_internal(),
    "Failed to decode recipe",
  )
}
