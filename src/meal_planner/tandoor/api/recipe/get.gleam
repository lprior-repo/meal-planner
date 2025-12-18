/// Recipe Get API
///
/// This module provides functions to get a single recipe by ID from the
/// Tandoor API.
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/recipe/recipe_decoder
import meal_planner/tandoor/types.{type TandoorRecipe}

/// Get a single recipe by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `recipe_id` - The ID of the recipe to fetch
///
/// # Returns
/// Result with recipe details or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_recipe(config, recipe_id: 42)
/// ```
pub fn get_recipe(
  config: ClientConfig,
  recipe_id recipe_id: Int,
) -> Result(TandoorRecipe, TandoorError) {
  // Get recipe using generic CRUD function
  generic_crud.get(
    config,
    "/api/recipe/",
    recipe_id,
    recipe_decoder.recipe_decoder(),
  )
}
