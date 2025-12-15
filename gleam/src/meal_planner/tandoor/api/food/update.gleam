/// Food Update API
///
/// This module provides functions to update existing food items in the Tandoor API.
import gleam/int
import gleam/json
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/food/food_decoder
import meal_planner/tandoor/encoders/food/food_encoder
import meal_planner/tandoor/types.{type TandoorFoodCreateRequest}
import meal_planner/tandoor/types/food/food.{type Food}

/// Update an existing food item in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `food_id` - The ID of the food item to update
/// * `food_data` - Updated food data (name)
///
/// # Returns
/// Result with updated food item or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let food_data = TandoorFoodCreateRequest(name: "Cherry Tomato")
/// let result = update_food(config, food_id: 42, food_data: food_data)
/// ```
pub fn update_food(
  config: ClientConfig,
  food_id food_id: Int,
  food_data food_data: TandoorFoodCreateRequest,
) -> Result(Food, TandoorError) {
  let path = "/api/food/" <> int.to_string(food_id) <> "/"
  let body = food_encoder.encode_food_create(food_data) |> json.to_string

  use resp <- result.try(crud_helpers.execute_patch(config, path, body))
  crud_helpers.parse_json_single(resp, food_decoder.food_decoder())
}
