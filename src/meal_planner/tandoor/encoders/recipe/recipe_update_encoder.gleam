/// Recipe update encoder for Tandoor SDK
///
/// This module provides JSON encoders for RecipeUpdate type for the Tandoor API.
/// It follows the gleam/json encoding pattern for type-safe JSON serialization.
///
/// The encoder handles:
/// - Optional fields (only encode if Some)
/// - Clean, minimal JSON output matching Tandoor API expectations for PATCH requests
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import meal_planner/tandoor/types/recipe/recipe_update.{type RecipeUpdate}

// ============================================================================
// Recipe Update Encoder
// ============================================================================

/// Encode a RecipeUpdate to JSON (only include provided fields)
///
/// This encoder creates minimal JSON for recipe update requests.
/// It only includes fields that are Some, allowing partial updates.
///
/// # Example
/// ```gleam
/// let update = RecipeUpdate(
///   name: Some("Updated Recipe"),
///   description: None,
///   servings: Some(6),
///   servings_text: None,
///   working_time: None,
///   waiting_time: None,
/// )
/// let encoded = encode_recipe_update(update)
/// json.to_string(encoded) // "{\"name\":\"Updated Recipe\",\"servings\":6}"
/// ```
///
/// # Arguments
/// * `update` - The recipe update request to encode
///
/// # Returns
/// JSON representation of the recipe update request
pub fn encode_recipe_update(update: RecipeUpdate) -> Json {
  let fields =
    []
    |> add_optional_field("name", update.name, json.string)
    |> add_optional_field("description", update.description, json.string)
    |> add_optional_field("servings", update.servings, json.int)
    |> add_optional_field("servings_text", update.servings_text, json.string)
    |> add_optional_field("working_time", update.working_time, json.int)
    |> add_optional_field("waiting_time", update.waiting_time, json.int)

  json.object(fields)
}

/// Helper to add optional field to JSON object
///
/// Only adds the field if the value is Some.
///
/// # Arguments
/// * `fields` - Current list of fields
/// * `key` - Field name
/// * `value` - Optional value
/// * `encoder` - Encoder function for the value type
///
/// # Returns
/// Updated list of fields
fn add_optional_field(
  fields: List(#(String, Json)),
  key: String,
  value: Option(a),
  encoder: fn(a) -> Json,
) -> List(#(String, Json)) {
  case value {
    Some(v) -> [#(key, encoder(v)), ..fields]
    None -> fields
  }
}
