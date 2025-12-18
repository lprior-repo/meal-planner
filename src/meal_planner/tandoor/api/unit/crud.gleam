/// Unit CRUD API
///
/// This module provides create, read, update, delete operations for units.
import gleam/int
import gleam/json
import gleam/result
import meal_planner/tandoor/api/crud_helpers
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
import meal_planner/tandoor/decoders/unit/unit_decoder
import meal_planner/tandoor/encoders/unit/unit_encoder
import meal_planner/tandoor/types/unit/unit.{type Unit}

/// Get a single unit by ID
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `unit_id` - The unit ID to retrieve
///
/// # Returns
/// Result with the unit or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = get_unit(config, unit_id: 1)
/// ```
pub fn get_unit(
  config: ClientConfig,
  unit_id unit_id: Int,
) -> Result(Unit, TandoorError) {
  let path = "/api/unit/" <> int.to_string(unit_id) <> "/"

  use resp <- result.try(crud_helpers.execute_get(config, path, []))

  crud_helpers.parse_json_single(resp, unit_decoder.decode_unit())
}

/// Create a new unit
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `name` - The unit name (required)
///
/// # Returns
/// Result with the created unit or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = create_unit(config, name: "tablespoon")
/// ```
pub fn create_unit(
  config: ClientConfig,
  name name: String,
) -> Result(Unit, TandoorError) {
  let path = "/api/unit/"

  // Encode unit name to JSON using the encoder
  let request_body =
    unit_encoder.encode_unit_create(name)
    |> json.to_string

  use resp <- result.try(crud_helpers.execute_post(config, path, request_body))

  crud_helpers.parse_json_single(resp, unit_decoder.decode_unit())
}

/// Update an existing unit
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `unit_id` - The unit ID to update
/// * `unit` - The updated unit data
///
/// # Returns
/// Result with the updated unit or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let unit = Unit(id: 1, name: "gram", ...)
/// let result = update_unit(config, unit_id: 1, unit: unit)
/// ```
pub fn update_unit(
  config: ClientConfig,
  unit_id unit_id: Int,
  unit unit: Unit,
) -> Result(Unit, TandoorError) {
  let path = "/api/unit/" <> int.to_string(unit_id) <> "/"

  // Encode unit data to JSON
  let request_body =
    unit_encoder.encode_unit(unit)
    |> json.to_string

  use resp <- result.try(crud_helpers.execute_patch(config, path, request_body))

  crud_helpers.parse_json_single(resp, unit_decoder.decode_unit())
}

/// Delete a unit
///
/// # Arguments
/// * `config` - Client configuration with authentication
/// * `unit_id` - The unit ID to delete
///
/// # Returns
/// Result with Nil on success or error
///
/// # Example
/// ```gleam
/// let config = client.bearer_config("http://localhost:8000", "token")
/// let result = delete_unit(config, unit_id: 1)
/// ```
pub fn delete_unit(
  config: ClientConfig,
  unit_id unit_id: Int,
) -> Result(Nil, TandoorError) {
  let path = "/api/unit/" <> int.to_string(unit_id) <> "/"

  use _resp <- result.try(crud_helpers.execute_delete(config, path))

  // DELETE returns 204 No Content on success
  Ok(Nil)
}
