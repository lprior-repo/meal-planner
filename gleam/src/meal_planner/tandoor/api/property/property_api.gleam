/// Property API operations for Tandoor SDK
///
/// This module provides CRUD operations for managing custom properties via Tandoor API.
/// Properties allow extending recipes and foods with custom metadata fields.
///
/// Operations:
/// - list_properties: Get all properties
/// - get_property: Get a single property by ID
/// - create_property: Create a new property
/// - update_property: Update an existing property
/// - delete_property: Delete a property
import gleam/int
import gleam/json
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/core/ids.{type PropertyId}
import meal_planner/tandoor/decoders/property/property_decoder
import meal_planner/tandoor/encoders/property/property_encoder.{
  type PropertyCreateRequest, type PropertyUpdateRequest,
}
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
    <> int.to_string(ids.property_id_to_int(property_id))
    <> "/"

  use resp <- result.try(crud_helpers.execute_get(config, path, []))

  crud_helpers.parse_json_single(resp, property_decoder.property_decoder())
}

/// Create a new property in Tandoor
///
/// # Arguments
/// * `config` - Client configuration
/// * `create_data` - Property creation data
///
/// # Returns
/// Result with created property or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let request = PropertyCreateRequest(name: "rating", property_type: "number")
/// let result = create_property(config, request)
/// ```
pub fn create_property(
  config: ClientConfig,
  create_data: PropertyCreateRequest,
) -> Result(Property, TandoorError) {
  let path = "/api/property/"

  let request_body =
    property_encoder.encode_property_create_request(create_data)
    |> json.to_string

  use resp <- result.try(crud_helpers.execute_post(config, path, request_body))

  crud_helpers.parse_json_single(resp, property_decoder.property_decoder())
}

/// Update an existing property in Tandoor
///
/// # Arguments
/// * `config` - Client configuration
/// * `property_id` - Property ID to update
/// * `update_data` - Property update data (partial update supported)
///
/// # Returns
/// Result with updated property or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let request = PropertyUpdateRequest(name: option.Some("new_name"), ...)
/// let result = update_property(config, property_id: 1, update_data: request)
/// ```
pub fn update_property(
  config: ClientConfig,
  property_id property_id: PropertyId,
  update_data update_data: PropertyUpdateRequest,
) -> Result(Property, TandoorError) {
  let path =
    "/api/property/"
    <> int.to_string(ids.property_id_to_int(property_id))
    <> "/"

  let request_body =
    property_encoder.encode_property_update_request(update_data)
    |> json.to_string

  use resp <- result.try(crud_helpers.execute_patch(config, path, request_body))

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
    <> int.to_string(ids.property_id_to_int(property_id))
    <> "/"

  use _resp <- result.try(crud_helpers.execute_delete(config, path))

  // DELETE returns 204 No Content on success
  Ok(Nil)
}
