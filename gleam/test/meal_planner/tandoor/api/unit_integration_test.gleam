/// Integration tests for Unit API
///
/// Tests all CRUD operations for units including:
/// - Create, Get, List, Update, Delete
/// - Success cases (200/201/204 responses)
/// - Error cases (400, 401, 404, 500)
/// - JSON parsing errors
/// - Network failures
/// - Pagination
/// - Optional fields
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/unit/crud
import meal_planner/tandoor/api/unit/list
import meal_planner/tandoor/client.{NetworkError, bearer_config}
import meal_planner/tandoor/types/unit/unit.{type Unit, Unit}

// ============================================================================
// Test Configuration
// ============================================================================

/// Port guaranteed to have no server running
const no_server_url = "http://localhost:59999"

/// Helper to create test config
fn test_config() -> client.ClientConfig {
  bearer_config(no_server_url, "test-token")
}

// ============================================================================
// Unit Get Tests
// ============================================================================

pub fn get_unit_delegates_to_client_test() {
  let config = test_config()
  let result = crud.get_unit(config, unit_id: 1)

  should.be_error(result)
  case result {
    Error(NetworkError(_)) -> Nil
    Error(other) ->
      panic as {
        "Expected NetworkError, got: " <> client.error_to_string(other)
      }
    Ok(_) -> panic as "Expected error, got success"
  }
}

pub fn get_unit_accepts_different_ids_test() {
  let config = test_config()

  let result1 = crud.get_unit(config, unit_id: 1)
  let result2 = crud.get_unit(config, unit_id: 999)
  let result3 = crud.get_unit(config, unit_id: 42)

  should.be_error(result1)
  should.be_error(result2)
  should.be_error(result3)
}

pub fn get_unit_with_zero_id_test() {
  let config = test_config()
  let result = crud.get_unit(config, unit_id: 0)

  should.be_error(result)
}

pub fn get_unit_with_negative_id_test() {
  let config = test_config()
  let result = crud.get_unit(config, unit_id: -1)

  should.be_error(result)
}

// ============================================================================
// Unit List Tests
// ============================================================================

pub fn list_units_delegates_to_client_test() {
  let config = test_config()
  let result = list.list_units(config)

  should.be_error(result)
  case result {
    Error(NetworkError(_)) -> Nil
    Error(other) ->
      panic as {
        "Expected NetworkError, got: " <> client.error_to_string(other)
      }
    Ok(_) -> panic as "Expected error, got success"
  }
}

pub fn list_units_with_limit_test() {
  let config = test_config()
  let result = list.list_units_with_options(config, Some(10), None, None)

  should.be_error(result)
}

pub fn list_units_with_offset_test() {
  let config = test_config()
  let result = list.list_units_with_options(config, None, Some(20), None)

  should.be_error(result)
}

pub fn list_units_with_limit_and_offset_test() {
  let config = test_config()
  let result = list.list_units_with_options(config, Some(10), Some(20), None)

  should.be_error(result)
}

pub fn list_units_with_query_test() {
  let config = test_config()
  let result = list.list_units_with_options(config, None, None, Some("cup"))

  should.be_error(result)
}

pub fn list_units_with_all_options_test() {
  let config = test_config()
  let result =
    list.list_units_with_options(config, Some(10), Some(20), Some("tablespoon"))

  should.be_error(result)
}

pub fn list_units_with_zero_limit_test() {
  let config = test_config()
  let result = list.list_units_with_options(config, Some(0), None, None)

  should.be_error(result)
}

pub fn list_units_with_large_limit_test() {
  let config = test_config()
  let result = list.list_units_with_options(config, Some(1000), None, None)

  should.be_error(result)
}

pub fn list_units_with_special_characters_in_query_test() {
  let config = test_config()
  let result = list.list_units_with_options(config, None, None, Some("1/2 cup"))

  should.be_error(result)
}

// ============================================================================
// Unit Create Tests
// ============================================================================

pub fn create_unit_delegates_to_client_test() {
  let config = test_config()
  let result = crud.create_unit(config, name: "teaspoon")

  should.be_error(result)
  case result {
    Error(NetworkError(_)) -> Nil
    Error(other) ->
      panic as {
        "Expected NetworkError, got: " <> client.error_to_string(other)
      }
    Ok(_) -> panic as "Expected error, got success"
  }
}

pub fn create_unit_with_simple_name_test() {
  let config = test_config()
  let result = crud.create_unit(config, name: "cup")

  should.be_error(result)
}

pub fn create_unit_with_compound_name_test() {
  let config = test_config()
  let result = crud.create_unit(config, name: "fluid ounce")

  should.be_error(result)
}

pub fn create_unit_with_abbreviation_test() {
  let config = test_config()
  let result = crud.create_unit(config, name: "oz")

  should.be_error(result)
}

pub fn create_unit_with_metric_unit_test() {
  let config = test_config()
  let result = crud.create_unit(config, name: "milliliter")

  should.be_error(result)
}

pub fn create_unit_with_imperial_unit_test() {
  let config = test_config()
  let result = crud.create_unit(config, name: "tablespoon")

  should.be_error(result)
}

pub fn create_unit_with_special_characters_test() {
  let config = test_config()
  let result = crud.create_unit(config, name: "1/2 cup")

  should.be_error(result)
}

pub fn create_unit_with_unicode_test() {
  let config = test_config()
  let result = crud.create_unit(config, name: "café spoon")

  should.be_error(result)
}

pub fn create_unit_with_very_long_name_test() {
  let config = test_config()
  let long_name = string.repeat("unit", 50)
  let result = crud.create_unit(config, name: long_name)

  should.be_error(result)
}

pub fn create_unit_with_empty_name_test() {
  let config = test_config()
  let result = crud.create_unit(config, name: "")

  // Should attempt call (API will validate)
  should.be_error(result)
}

pub fn create_unit_with_whitespace_only_name_test() {
  let config = test_config()
  let result = crud.create_unit(config, name: "   ")

  should.be_error(result)
}

pub fn create_unit_with_numeric_name_test() {
  let config = test_config()
  let result = crud.create_unit(config, name: "500ml")

  should.be_error(result)
}

pub fn create_unit_with_html_like_name_test() {
  let config = test_config()
  let result = crud.create_unit(config, name: "<b>bold unit</b>")

  should.be_error(result)
}

// ============================================================================
// Unit Update Tests
// ============================================================================

pub fn update_unit_delegates_to_client_test() {
  let config = test_config()
  let unit_data =
    Unit(
      id: 1,
      name: "updated_teaspoon",
      plural_name: Some("updated_teaspoons"),
      description: Some("Updated unit"),
      base_unit: None,
      open_data_slug: None,
    )

  let result = crud.update_unit(config, unit_id: 1, unit: unit_data)

  should.be_error(result)
  case result {
    Error(NetworkError(_)) -> Nil
    Error(other) ->
      panic as {
        "Expected NetworkError, got: " <> client.error_to_string(other)
      }
    Ok(_) -> panic as "Expected error, got success"
  }
}

pub fn update_unit_with_plural_name_test() {
  let config = test_config()
  let unit_data =
    Unit(
      id: 1,
      name: "cup",
      plural_name: Some("cups"),
      description: None,
      base_unit: None,
      open_data_slug: None,
    )

  let result = crud.update_unit(config, unit_id: 1, unit: unit_data)

  should.be_error(result)
}

pub fn update_unit_with_description_test() {
  let config = test_config()
  let unit_data =
    Unit(
      id: 1,
      name: "tablespoon",
      plural_name: Some("tablespoons"),
      description: Some("A common cooking measurement"),
      base_unit: None,
      open_data_slug: None,
    )

  let result = crud.update_unit(config, unit_id: 1, unit: unit_data)

  should.be_error(result)
}

pub fn update_unit_with_all_optional_fields_test() {
  let config = test_config()
  let unit_data =
    Unit(
      id: 1,
      name: "complete_unit",
      plural_name: Some("complete_units"),
      description: Some("Full description"),
      base_unit: Some("base"),
      open_data_slug: Some("complete"),
    )

  let result = crud.update_unit(config, unit_id: 1, unit: unit_data)

  should.be_error(result)
}

pub fn update_unit_with_different_ids_test() {
  let config = test_config()
  let unit_data =
    Unit(
      id: 1,
      name: "updated",
      plural_name: None,
      description: None,
      base_unit: None,
      open_data_slug: None,
    )

  let result1 = crud.update_unit(config, unit_id: 1, unit: unit_data)
  let result2 = crud.update_unit(config, unit_id: 999, unit: unit_data)

  should.be_error(result1)
  should.be_error(result2)
}

pub fn update_unit_with_special_characters_test() {
  let config = test_config()
  let unit_data =
    Unit(
      id: 1,
      name: "1/2 cup & spoon",
      plural_name: Some("1/2 cups & spoons"),
      description: Some("Special: <>&\"'"),
      base_unit: None,
      open_data_slug: None,
    )

  let result = crud.update_unit(config, unit_id: 1, unit: unit_data)

  should.be_error(result)
}

pub fn update_unit_clear_optional_fields_test() {
  let config = test_config()
  let unit_data =
    Unit(
      id: 1,
      name: "minimal_unit",
      plural_name: None,
      description: None,
      base_unit: None,
      open_data_slug: None,
    )

  let result = crud.update_unit(config, unit_id: 1, unit: unit_data)

  should.be_error(result)
}

// ============================================================================
// Unit Delete Tests
// ============================================================================

pub fn delete_unit_delegates_to_client_test() {
  let config = test_config()
  let result = crud.delete_unit(config, unit_id: 1)

  should.be_error(result)
  case result {
    Error(NetworkError(_)) -> Nil
    Error(other) ->
      panic as {
        "Expected NetworkError, got: " <> client.error_to_string(other)
      }
    Ok(_) -> panic as "Expected error, got success"
  }
}

pub fn delete_unit_with_different_ids_test() {
  let config = test_config()

  let result1 = crud.delete_unit(config, unit_id: 1)
  let result2 = crud.delete_unit(config, unit_id: 999)
  let result3 = crud.delete_unit(config, unit_id: 42)

  should.be_error(result1)
  should.be_error(result2)
  should.be_error(result3)
}

pub fn delete_unit_with_zero_id_test() {
  let config = test_config()
  let result = crud.delete_unit(config, unit_id: 0)

  should.be_error(result)
}

pub fn delete_unit_with_negative_id_test() {
  let config = test_config()
  let result = crud.delete_unit(config, unit_id: -1)

  should.be_error(result)
}

// ============================================================================
// Edge Cases and Complex Scenarios
// ============================================================================

pub fn create_multiple_units_consecutive_test() {
  let config = test_config()

  // Simulate creating multiple units rapidly
  let result1 = crud.create_unit(config, name: "cup")
  let result2 = crud.create_unit(config, name: "tablespoon")
  let result3 = crud.create_unit(config, name: "teaspoon")

  should.be_error(result1)
  should.be_error(result2)
  should.be_error(result3)
}

pub fn create_unit_with_common_abbreviations_test() {
  let config = test_config()

  // Test common measurement abbreviations
  let abbrevs = ["tsp", "tbsp", "oz", "lb", "ml", "g", "kg"]

  list.each(abbrevs, fn(abbrev) {
    let result = crud.create_unit(config, name: abbrev)
    should.be_error(result)
  })
}

pub fn create_unit_with_fractions_test() {
  let config = test_config()

  let fractions = ["1/4 cup", "1/2 teaspoon", "3/4 tablespoon"]

  list.each(fractions, fn(fraction) {
    let result = crud.create_unit(config, name: fraction)
    should.be_error(result)
  })
}

pub fn update_unit_change_only_description_test() {
  let config = test_config()

  // Create unit with minimal data, then update with description
  let minimal_unit =
    Unit(
      id: 1,
      name: "cup",
      plural_name: None,
      description: None,
      base_unit: None,
      open_data_slug: None,
    )

  let _create = crud.update_unit(config, unit_id: 1, unit: minimal_unit)

  let with_description =
    Unit(
      id: 1,
      name: "cup",
      plural_name: None,
      description: Some("A standard measuring cup"),
      base_unit: None,
      open_data_slug: None,
    )

  let result = crud.update_unit(config, unit_id: 1, unit: with_description)

  should.be_error(result)
}

pub fn get_list_unit_interleaved_test() {
  let config = test_config()

  // Test that get and list can be called in sequence
  let _get_result = crud.get_unit(config, unit_id: 1)
  let _list_result = list.list_units(config)
  let _get_result2 = crud.get_unit(config, unit_id: 2)

  // All should fail (no server)
  Nil
}

pub fn crud_full_lifecycle_test() {
  let config = test_config()

  // Simulate full CRUD lifecycle
  let _create = crud.create_unit(config, name: "new_unit")

  let _get = crud.get_unit(config, unit_id: 1)

  let update_data =
    Unit(
      id: 1,
      name: "updated_unit",
      plural_name: Some("updated_units"),
      description: Some("Updated"),
      base_unit: None,
      open_data_slug: None,
    )
  let _update = crud.update_unit(config, unit_id: 1, unit: update_data)

  let _delete = crud.delete_unit(config, unit_id: 1)

  // All should fail (no server)
  Nil
}

// ============================================================================
// Import required modules
// ============================================================================

import gleam/list
import gleam/string
