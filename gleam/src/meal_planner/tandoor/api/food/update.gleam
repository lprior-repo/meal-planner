/// Food Update API
///
/// This module provides functions to update existing food items in the Tandoor API.
import gleam/json
import meal_planner/tandoor/api/generic_crud
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
  let body = food_encoder.encode_food_create(food_data) |> json.to_string

  generic_crud.update(
    config,
    "/api/food/",
    food_id,
    body,
    food_decoder.food_decoder(),
  )
}
