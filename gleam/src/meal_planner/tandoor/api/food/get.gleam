/// Food Get API
///
/// This module provides functions to get a single food item by ID from the
/// Tandoor API.
import gleam/dynamic/decode
import gleam/httpc
import gleam/int
import gleam/json
import gleam/result
import gleam/string
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError, ParseError,
}
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
  let path = "/api/food/" <> int.to_string(food_id) <> "/"

  // Build and execute request
  use req <- result.try(client.build_get_request(config, path, []))

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // Parse JSON response
  case json.parse(resp.body, using: decode.dynamic) {
    Ok(json_data) -> {
      case decode.run(json_data, food_decoder.food_decoder()) {
        Ok(food) -> Ok(food)
        Error(errors) -> {
          let error_msg =
            "Failed to decode food: "
            <> string.inspect(errors)
          Error(ParseError(error_msg))
        }
      }
    }
    Error(_) -> Error(ParseError("Failed to parse JSON response"))
  }
}
