/// Unit CRUD API
///
/// This module provides create, read, update, delete operations for units.
import meal_planner/tandoor/client.{type ClientConfig, type TandoorError}
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
  // TODO: Implement when client helpers are available
  let _config = config
  let _unit_id = unit_id
  Error(client.NetworkError("Not implemented yet"))
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
  // TODO: Implement when client helpers are available
  let _config = config
  let _name = name
  Error(client.NetworkError("Not implemented yet"))
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
  // TODO: Implement when client helpers are available
  let _config = config
  let _unit_id = unit_id
  let _unit = unit
  Error(client.NetworkError("Not implemented yet"))
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
  // TODO: Implement when client helpers are available
  let _config = config
  let _unit_id = unit_id
  Error(client.NetworkError("Not implemented yet"))
}
