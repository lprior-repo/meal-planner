/// Cuisine Update API
///
/// This module provides functions to update existing cuisines in the Tandoor API.
import gleam/json
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/ids.{type CuisineId, cuisine_id_to_int}
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
/// let cuisine_id = ids.cuisine_id_from_int(5)
/// let update_data = CuisineUpdateRequest(
///   name: Some("Northern Italian"),
///   description: Some(Some("Cuisine from Northern Italy")),
///   icon: None,
///   parent: None,
/// )
/// let result = update_cuisine(config, cuisine_id: cuisine_id, data: update_data)
/// ```
pub fn update_cuisine(
  config: ClientConfig,
  cuisine_id cuisine_id: CuisineId,
  data update_data: CuisineUpdateRequest,
) -> Result(Cuisine, TandoorError) {
  let body =
    cuisine_encoder.encode_cuisine_update_request(update_data)
    |> json.to_string

  generic_crud.update(
    config,
    "/api/cuisine/",
    cuisine_id_to_int(cuisine_id),
    body,
    cuisine_decoder.cuisine_decoder(),
  )
}
