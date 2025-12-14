/// Food Delete API
///
/// This module provides functions to delete food items from the Tandoor API.
import gleam/httpc
import gleam/int
import gleam/result
import meal_planner/tandoor/client.{
  type ClientConfig, type TandoorError, NetworkError,
}

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

  // Build and execute DELETE request
  use req <- result.try(client.build_delete_request(config, path))

  use _resp <- result.try(
    httpc.send(req)
    |> result.map_error(fn(_err) { NetworkError("Failed to connect to API") }),
  )

  // DELETE returns 204 No Content on success
  Ok(Nil)
}
