/// Cuisine Create API
///
/// This module provides functions to create new cuisines in the Tandoor API.
import gleam/json
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/cuisine/cuisine_decoder
import meal_planner/tandoor/encoders/cuisine/cuisine_encoder
import meal_planner/tandoor/types/cuisine/cuisine.{
  type Cuisine, type CuisineCreateRequest,
}

/// Create a new cuisine in Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `cuisine_data` - Cuisine data to create (name, description, icon, parent)
///
/// # Returns
/// Result with created cuisine or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let cuisine_data = CuisineCreateRequest(
///   name: "Italian",
///   description: Some("Traditional Italian cuisine"),
///   icon: Some("🇮🇹"),
///   parent: None,
/// )
/// let result = create_cuisine(config, cuisine_data)
/// ```
pub fn create_cuisine(
  config: ClientConfig,
  cuisine_data: CuisineCreateRequest,
) -> Result(Cuisine, TandoorError) {
  let body =
    cuisine_encoder.encode_cuisine_create_request(cuisine_data)
    |> json.to_string

  generic_crud.create(
    config,
    "/api/cuisine/",
    body,
    cuisine_decoder.cuisine_decoder(),
  )
}
