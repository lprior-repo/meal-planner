/// Recipe Create API
///
/// This module provides functions to create new recipes in the Tandoor API.
import meal_planner/tandoor/client.{
  type ClientConfig, type CreateRecipeRequest, type Recipe, type TandoorError,
}

/// Create a new recipe in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `request` - Recipe data to create
///
/// # Returns
/// Result with created recipe or error
pub fn create_recipe(
  config: ClientConfig,
  request: CreateRecipeRequest,
) -> Result(Recipe, TandoorError) {
  // Use the existing client method - delegate to it
  // This provides a cleaner API surface while reusing existing implementation
  client.create_recipe(config, request)
}
