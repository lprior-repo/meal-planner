/// Food Create API
///
/// This module provides functions to create new food items in the Tandoor API.
import gleam/json
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/food/food_decoder
import meal_planner/tandoor/encoders/food/food_encoder
import meal_planner/tandoor/types.{type TandoorFoodCreateRequest}
import meal_planner/tandoor/types/food/food.{type Food}

/// Create a new food item in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `food_data` - Food data to create (name)
///
/// # Returns
/// Result with created food item or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let food_data = TandoorFoodCreateRequest(name: "Tomato")
/// let result = create_food(config, food_data)
/// ```
pub fn create_food(
  config: ClientConfig,
  food_data: TandoorFoodCreateRequest,
) -> Result(Food, TandoorError) {
  let body = food_encoder.encode_food_create(food_data) |> json.to_string

  generic_crud.create(config, "/api/food/", body, food_decoder.food_decoder())
}
