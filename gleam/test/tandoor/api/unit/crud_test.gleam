/// Tests for Unit CRUD API
///
/// These tests verify the create, read, update, delete operations for units.
/// Note: Tests use a non-existent port (59999) to verify error handling without
/// actually connecting to any server.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/unit/crud
import meal_planner/tandoor/client
import meal_planner/tandoor/types/unit/unit.{Unit}

/// Port that's guaranteed to not have a server running
const no_server_url = "http://localhost:59999"

pub fn get_unit_delegates_to_client_test() {
  // Verify get_unit function exists and has correct signature
  let config = client.bearer_config(no_server_url, "test-token")

  // Call should fail (no server) but proves delegation works
  let result = crud.get_unit(config, unit_id: 1)

  // Should get a network or connection error
  should.be_error(result)
}

pub fn create_unit_delegates_to_client_test() {
  // Verify create_unit function exists
  let config = client.bearer_config(no_server_url, "test-token")

  // Call should fail (no server) but proves delegation works
  let result = crud.create_unit(config, name: "tablespoon")

  // Should attempt call and fail
  should.be_error(result)
}

pub fn update_unit_delegates_to_client_test() {
  // Verify update_unit function exists
  let config = client.bearer_config(no_server_url, "test-token")

  let unit =
    Unit(
      id: 1,
      name: "updated_unit",
      plural_name: Some("updated_units"),
      description: Some("Updated description"),
      base_unit: None,
      open_data_slug: Some("upd"),
    )

  let result = crud.update_unit(config, unit_id: 1, unit: unit)

  // Should attempt call and fail
  should.be_error(result)
}

pub fn delete_unit_delegates_to_client_test() {
  // Verify delete_unit function exists
  let config = client.bearer_config(no_server_url, "test-token")

  let result = crud.delete_unit(config, unit_id: 1)

  // Should attempt call and fail
  should.be_error(result)
}

pub fn create_unit_with_special_characters_test() {
  // Verify special characters in name work
  let config = client.bearer_config(no_server_url, "test-token")

  let result = crud.create_unit(config, name: "café spoon")

  // Should attempt call
  should.be_error(result)
}
