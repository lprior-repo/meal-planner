/// Property API operations for Tandoor SDK
///
/// This module provides CRUD operations for managing custom properties via Tandoor API.
/// Properties allow extending recipes and foods with custom metadata fields.
///
/// Operations:
/// - list_properties: Get all properties
/// - get_property: Get a single property by ID
/// - delete_property: Delete a property
import gleam/int
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/ids.{type PropertyId, property_id_to_int}
import meal_planner/tandoor/decoders/property/property_decoder
import meal_planner/tandoor/types/property/property.{type Property}

/// Get all properties from Tandoor API
///
/// # Arguments
/// * `config` - Client configuration
///
/// # Returns
/// Result with list of properties or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = list_properties(config)
/// ```
pub fn list_properties(
  config: ClientConfig,
) -> Result(List(Property), TandoorError) {
  let path = "/api/property/"

  use resp <- result.try(crud_helpers.execute_get(config, path, []))

  crud_helpers.parse_json_list(resp, property_decoder.property_decoder())
}

/// Get a single property by ID
///
/// # Arguments
/// * `config` - Client configuration
/// * `property_id` - Property ID
///
/// # Returns
/// Result with property or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_property(config, property_id: 1)
/// ```
pub fn get_property(
  config: ClientConfig,
  property_id property_id: PropertyId,
) -> Result(Property, TandoorError) {
  let path =
    "/api/property/"
    <> int.to_string(property_id_to_int(property_id))
    <> "/"

  use resp <- result.try(crud_helpers.execute_get(config, path, []))

  crud_helpers.parse_json_single(resp, property_decoder.property_decoder())
}

/// Delete a property from Tandoor
///
/// # Arguments
/// * `config` - Client configuration
/// * `property_id` - Property ID to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_property(config, property_id: 1)
/// ```
pub fn delete_property(
  config: ClientConfig,
  property_id property_id: PropertyId,
) -> Result(Nil, TandoorError) {
  let path =
    "/api/property/"
    <> int.to_string(property_id_to_int(property_id))
    <> "/"

  use _resp <- result.try(crud_helpers.execute_delete(config, path))

  // DELETE returns 204 No Content on success
  Ok(Nil)
}
