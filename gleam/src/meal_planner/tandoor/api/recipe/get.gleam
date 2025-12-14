/// Recipe Get API
///
/// This module provides functions to get a single recipe by ID from the
/// Tandoor API.
import gleam/int
import gleam/result
import meal_planner/tandoor/api/crud_helpers
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
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  // Execute GET request using CRUD helper
  use resp <- result.try(crud_helpers.execute_get(config, path, []))

  // Parse JSON response using generic helper and standard recipe decoder
  crud_helpers.parse_json_single(resp, recipe_decoder.recipe_decoder())
}
