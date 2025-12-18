/// Cuisine Get API
///
/// This module provides functions to retrieve a single cuisine by ID.
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/ids.{type CuisineId, cuisine_id_to_int}
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
/// let cuisine_id = ids.cuisine_id_from_int(5)
/// let result = get_cuisine(config, cuisine_id: cuisine_id)
/// ```
pub fn get_cuisine(
  config: ClientConfig,
  cuisine_id cuisine_id: CuisineId,
) -> Result(Cuisine, TandoorError) {
  generic_crud.get(
    config,
    "/api/cuisine/",
    cuisine_id_to_int(cuisine_id),
    cuisine_decoder.cuisine_decoder(),
  )
}
