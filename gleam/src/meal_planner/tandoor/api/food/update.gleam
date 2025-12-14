/// Food Update API
///
/// This module provides functions to update existing food items in the Tandoor API.
import gleam/dynamic/decode
import gleam/httpc
import gleam/int
import gleam/json
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
import meal_planner/tandoor/decoders/recipe/recipe_decoder
import meal_planner/tandoor/encoders/food/food_encoder
import meal_planner/tandoor/types.{
  type TandoorFood, type TandoorFoodCreateRequest,
}

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
) -> Result(TandoorFood, TandoorError) {
  let path = "/api/food/" <> int.to_string(food_id) <> "/"

  // Encode food data to JSON
  let request_body =
    food_encoder.encode_food_create(food_data)
    |> json.to_string

  // Build and execute PATCH request
  use req <- result.try(client.build_patch_request(config, path, request_body))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, recipe_decoder.food_decoder()) {
        Ok(food) -> Ok(food)
        Error(errors) -> {
          let error_msg =
            "Failed to decode updated food: "
            <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}
