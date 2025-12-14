/// Recipe Delete API
///
/// This module provides functions to delete recipes from the Tandoor API.
import gleam/int
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}

/// Delete a recipe from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `recipe_id` - The ID of the recipe to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_recipe(config, recipe_id: 42)
/// ```
pub fn delete_recipe(
  config: ClientConfig,
  recipe_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/recipe/" <> int.to_string(recipe_id) <> "/"

  use _resp <- result.try(crud_helpers.execute_delete(config, path))

  // DELETE returns 204 No Content on success
  Ok(Nil)
}
