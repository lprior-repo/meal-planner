/// Food Create API
///
/// This module provides functions to create new food items in the Tandoor API.
import gleam/dynamic/decode
import gleam/httpc
import gleam/json
import gleam/result
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
import meal_planner/tandoor/decoders/recipe/recipe_decoder
import meal_planner/tandoor/encoders/food/food_encoder
import meal_planner/tandoor/types.{
  type TandoorFood, type TandoorFoodCreateRequest,
}

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
) -> Result(TandoorFood, TandoorError) {
  let path = "/api/food/"

  // Encode food data to JSON
  let body =
    food_encoder.encode_food_create(food_data)
    |> json.to_string

  // Build and execute request
  use req <- result.try(client.build_post_request(config, path, body))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Convert to ApiResponse and parse JSON
  let api_resp = client.ApiResponse(resp.status, resp.headers, resp.body)
  client.parse_json_body(api_resp, fn(dyn) {
    decode.run(dyn, recipe_decoder.food_decoder())
    |> result.map_error(fn(_) { "Failed to decode created food" })
  })
}
