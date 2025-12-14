/// Food Get API
///
/// This module provides functions to get a single food item by ID from the
/// Tandoor API.
import gleam/dynamic/decode
import gleam/httpc
import gleam/int
import gleam/result
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
import meal_planner/tandoor/decoders/recipe/recipe_decoder
import meal_planner/tandoor/types.{type TandoorFood}

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
) -> Result(TandoorFood, TandoorError) {
  let path = "/api/food/" <> int.to_string(food_id) <> "/"

  // Build and execute request
  use req <- result.try(client.build_get_request(config, path))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  use body <- result.try(client.parse_json_body(resp.body))

  // Decode food item
  decode.run(body, recipe_decoder.food_decoder())
  |> result.map_error(fn(err) { ParseError("Failed to decode food: " <> err) })
}
