/// Food Delete API
///
/// This module provides functions to delete food items from the Tandoor API.
import gleam/int
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}

/// Delete a food item from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `food_id` - The ID of the food item to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_food(config, food_id: 42)
/// ```
pub fn delete_food(
  config: ClientConfig,
  food_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/food/" <> int.to_string(food_id) <> "/"

  use _resp <- result.try(crud_helpers.execute_delete(config, path))
  Ok(Nil)
}
