/// Recipe Get API
///
/// This module provides functions to get a single recipe by ID from the
/// Tandoor API.
import meal_planner/tandoor/client.{
  type ClientConfig, type Recipe, type TandoorError,
}

/// Get a single recipe by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `recipe_id` - The ID of the recipe to fetch
///
/// # Returns
/// Result with recipe details or error
pub fn get_recipe(
  config: ClientConfig,
  recipe_id recipe_id: Int,
) -> Result(Recipe, TandoorError) {
  // Use the existing client method - delegate to it
  // This provides a cleaner API surface while reusing existing implementation
  client.get_recipe_by_id(config, recipe_id)
}
