/// Cuisine Get API
///
/// This module provides functions to retrieve a single cuisine by ID.
import gleam/int
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/cuisine/cuisine_decoder
import meal_planner/tandoor/types/cuisine/cuisine.{type Cuisine}

/// Get a single cuisine by ID from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `cuisine_id` - ID of the cuisine to retrieve
///
/// # Returns
/// Result with cuisine data or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_cuisine(config, cuisine_id: 5)
/// ```
pub fn get_cuisine(
  config: ClientConfig,
  cuisine_id cuisine_id: Int,
) -> Result(Cuisine, TandoorError) {
  let path = "/api/cuisine/" <> int.to_string(cuisine_id) <> "/"
  use resp <- result.try(crud_helpers.execute_get(config, path, []))
  crud_helpers.parse_json_single(resp, cuisine_decoder.cuisine_decoder())
}
