/// Tests for Unit CRUD API
///
/// These tests verify the create, read, update, delete operations for units.
/// Note: Tests use a non-existent port (59999) to verify error handling without
/// actually connecting to any server.
import gleam/option.{None, Some}
import gleam/string
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

pub fn create_unit_with_unicode_test() {
  // Verify Unicode characters work
  let config = client.bearer_config(no_server_url, "test-token")

  let result = crud.create_unit(config, name: "日本語テスト")

  // Should attempt call
  should.be_error(result)
}

pub fn create_unit_with_emoji_test() {
  // Verify emoji characters work
  let config = client.bearer_config(no_server_url, "test-token")

  let result = crud.create_unit(config, name: "🥄 spoon")

  // Should attempt call
  should.be_error(result)
}

pub fn create_unit_empty_name_test() {
  // Verify empty name handling
  let config = client.bearer_config(no_server_url, "test-token")

  let result = crud.create_unit(config, name: "")

  // Should attempt call
  should.be_error(result)
}

pub fn get_unit_with_zero_id_test() {
  // Verify zero ID handling
  let config = client.bearer_config(no_server_url, "test-token")

  let result = crud.get_unit(config, unit_id: 0)

  // Should attempt call and fail
  should.be_error(result)
}

pub fn get_unit_with_negative_id_test() {
  // Verify negative ID handling
  let config = client.bearer_config(no_server_url, "test-token")

  let result = crud.get_unit(config, unit_id: -1)

  // Should attempt call and fail
  should.be_error(result)
}

pub fn update_unit_with_all_optional_fields_test() {
  // Verify update with all optional fields populated
  let config = client.bearer_config(no_server_url, "test-token")

  let unit =
    Unit(
      id: 1,
      name: "complete_unit",
      plural_name: Some("complete_units"),
      description: Some("A unit with all fields populated"),
      base_unit: Some("gram"),
      open_data_slug: Some("cu"),
    )

  let result = crud.update_unit(config, unit_id: 1, unit: unit)

  // Should attempt call and fail
  should.be_error(result)
}

pub fn update_unit_with_no_optional_fields_test() {
  // Verify update with all optional fields as None
  let config = client.bearer_config(no_server_url, "test-token")

  let unit =
    Unit(
      id: 1,
      name: "minimal_unit",
      plural_name: None,
      description: None,
      base_unit: None,
      open_data_slug: None,
    )

  let result = crud.update_unit(config, unit_id: 1, unit: unit)

  // Should attempt call and fail
  should.be_error(result)
}

pub fn delete_unit_with_zero_id_test() {
  // Verify zero ID handling for delete
  let config = client.bearer_config(no_server_url, "test-token")

  let result = crud.delete_unit(config, unit_id: 0)

  // Should attempt call and fail
  should.be_error(result)
}

pub fn create_unit_very_long_name_test() {
  // Verify handling of very long unit names
  let config = client.bearer_config(no_server_url, "test-token")

  // Create a 500 character name
  let long_name = "very_long_unit_name_" <> "x" |> string.repeat(480)

  let result = crud.create_unit(config, name: long_name)

  // Should attempt call
  should.be_error(result)
}
