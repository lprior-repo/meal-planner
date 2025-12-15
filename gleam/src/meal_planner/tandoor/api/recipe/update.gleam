/// Recipe Update API
///
/// This module provides functions to update existing recipes in the Tandoor API.
import gleam/json
import meal_planner/tandoor/api/generic_crud
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
  // Encode update data to JSON
  let request_body =
    recipe_update_encoder.encode_recipe_update(update_data)
    |> json.to_string

  // Update recipe using generic CRUD function
  generic_crud.update(
    config,
    "/api/recipe/",
    recipe_id,
    request_body,
    recipe_decoder.recipe_decoder(),
  )
}
