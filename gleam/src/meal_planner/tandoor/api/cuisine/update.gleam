/// Cuisine Update API
///
/// This module provides functions to update existing cuisines in the Tandoor API.
import gleam/int
import gleam/json
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/cuisine/cuisine_decoder
import meal_planner/tandoor/encoders/cuisine/cuisine_encoder
import meal_planner/tandoor/types/cuisine/cuisine.{
  type Cuisine, type CuisineUpdateRequest,
}

/// Update an existing cuisine (supports partial updates)
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `cuisine_id` - ID of the cuisine to update
/// * `update_data` - Fields to update (all optional)
///
/// # Returns
/// Result with updated cuisine or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let update_data = CuisineUpdateRequest(
///   name: Some("Northern Italian"),
///   description: Some(Some("Cuisine from Northern Italy")),
///   icon: None,
///   parent: None,
/// )
/// let result = update_cuisine(config, cuisine_id: 5, data: update_data)
/// ```
pub fn update_cuisine(
  config: ClientConfig,
  cuisine_id cuisine_id: Int,
  data update_data: CuisineUpdateRequest,
) -> Result(Cuisine, TandoorError) {
  let path = "/api/cuisine/" <> int.to_string(cuisine_id) <> "/"
  let body =
    cuisine_encoder.encode_cuisine_update_request(update_data)
    |> json.to_string

  use resp <- result.try(crud_helpers.execute_patch(config, path, body))
  crud_helpers.parse_json_single(resp, cuisine_decoder.cuisine_decoder())
}
