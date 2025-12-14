/// Recipe Update API
///
/// This module provides functions to update existing recipes in the Tandoor API.
import gleam/int
import gleam/json
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/recipe/recipe_decoder
import meal_planner/tandoor/encoders/recipe/recipe_update_encoder
import meal_planner/tandoor/types.{type TandoorRecipe}
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
) -> Result(TandoorRecipe, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  // Encode update data to JSON
  let request_body =
    recipe_update_encoder.encode_recipe_update(update_data)
    |> json.to_string

  // Build and execute PATCH request
  use resp <- result.try(crud_helpers.execute_patch(config, path, request_body))

  // Parse JSON response using generic helper and standard recipe decoder
  crud_helpers.parse_json_single(resp, recipe_decoder.recipe_decoder())
}
