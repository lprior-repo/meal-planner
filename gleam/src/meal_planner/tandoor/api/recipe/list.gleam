/// Recipe List API
///
/// This module provides functions to list recipes from the Tandoor API
/// with pagination support.
import gleam/option.{type Option}
import meal_planner/tandoor/client.{
  type ClientConfig, type RecipeListResponse, type TandoorError,
}

/// List recipes from Tandoor API with pagination
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `limit` - Optional number of results per page
/// * `offset` - Optional offset for pagination
///
/// # Returns
/// Result with paginated recipe list or error
pub fn list_recipes(
  config: ClientConfig,
  limit limit: Option(Int),
  offset offset: Option(Int),
) -> Result(RecipeListResponse, TandoorError) {
  // Use the existing client method - delegate to it
  // This provides a cleaner API surface while reusing existing implementation
  client.get_recipes(config, limit, offset)
}
