/// Food Get API
///
/// This module provides functions to get a single food item by ID from the
/// Tandoor API.
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/food/food_decoder
import meal_planner/tandoor/types/food/food.{type Food}

/// Get a single food item by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `food_id` - The ID of the food item to fetch
///
/// # Returns
/// Result with food details or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_food(config, food_id: 42)
/// ```
pub fn get_food(
  config: ClientConfig,
  food_id food_id: Int,
) -> Result(Food, TandoorError) {
  generic_crud.get(config, "/api/food/", food_id, food_decoder.food_decoder())
}
