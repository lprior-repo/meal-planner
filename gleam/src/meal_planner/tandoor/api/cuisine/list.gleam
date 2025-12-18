/// Cuisine List API
///
/// This module provides functions to list cuisines from the Tandoor API.
import gleam/int
import gleam/option.{type Option, None, Some}
import meal_planner/tandoor/api/generic_crud
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/ids.{type CuisineId, cuisine_id_to_int}
import meal_planner/tandoor/decoders/cuisine/cuisine_decoder
import meal_planner/tandoor/types/cuisine/cuisine.{type Cuisine}

/// List all cuisines from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration with authentication
///
/// # Returns
/// Result with list of cuisines or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_cuisines(config)
/// ```
pub fn list_cuisines(
  config: ClientConfig,
) -> Result(List(Cuisine), TandoorError) {
  list_cuisines_by_parent(config, None)
}

/// List cuisines filtered by parent ID (None for root cuisines)
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `parent_id` - Optional parent cuisine ID (None for root level)
///
/// # Returns
/// Result with list of cuisines or error
///
/// # Example
/// ```gleam
/// // Get root cuisines
/// let root = list_cuisines_by_parent(config, None)
///
/// // Get sub-cuisines of Asian (ID=5)
/// let cuisine_id = ids.cuisine_id_from_int(5)
/// let asian_subs = list_cuisines_by_parent(config, Some(cuisine_id))
/// ```
pub fn list_cuisines_by_parent(
  config: ClientConfig,
  parent_id: Option(CuisineId),
) -> Result(List(Cuisine), TandoorError) {
  let query_params = case parent_id {
    Some(id) -> [#("parent", int.to_string(cuisine_id_to_int(id)))]
    None -> [#("parent", "null")]
  }
  generic_crud.list(
    config,
    "/api/cuisine/",
    query_params,
    cuisine_decoder.cuisine_decoder(),
  )
}
