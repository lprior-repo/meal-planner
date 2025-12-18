/// Ingredient Delete API
///
/// This module provides functions to delete ingredient items from the Tandoor API.
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}

/// Delete an ingredient item from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `ingredient_id` - The ID of the ingredient item to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_ingredient(config, ingredient_id: 42)
/// ```
pub fn delete_ingredient(
  config: ClientConfig,
  ingredient_id: Int,
) -> Result(Nil, TandoorError) {
  generic_crud.delete(config, "/api/ingredient/", ingredient_id)
}
