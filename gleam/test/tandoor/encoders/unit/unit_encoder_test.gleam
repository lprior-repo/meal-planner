/// Tests for Unit encoder
///
/// This module tests JSON encoding of Unit and UnitCreate types.
/// Following TDD: these tests should FAIL first, then pass after implementation.
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/encoders/unit/unit_encoder
import meal_planner/tandoor/types/unit/unit.{Unit}

/// Test encoding a Unit with all fields to JSON
pub fn encode_unit_full_test() {
  let unit =
    Unit(
      id: 1,
      name: "gram",
      plural_name: Some("grams"),
      description: Some("Metric unit of mass"),
      base_unit: Some("kilogram"),
      open_data_slug: Some("g"),
    )

  let encoded = unit_encoder.encode_unit(unit)
  let json_string = json.to_string(encoded)

  // Should produce complete JSON with all fields
  json_string
  |> should.equal(
    "{\"id\":1,\"name\":\"gram\",\"plural_name\":\"grams\",\"description\":\"Metric unit of mass\",\"base_unit\":\"kilogram\",\"open_data_slug\":\"g\"}",
  )
}

/// Test encoding a Unit with only required fields
pub fn encode_unit_minimal_test() {
  let unit =
    Unit(
      id: 2,
      name: "piece",
      plural_name: None,
      description: None,
      base_unit: None,
      open_data_slug: None,
    )

  let encoded = unit_encoder.encode_unit(unit)
  let json_string = json.to_string(encoded)

  // Should produce JSON with null for optional fields
  json_string
  |> should.equal(
    "{\"id\":2,\"name\":\"piece\",\"plural_name\":null,\"description\":null,\"base_unit\":null,\"open_data_slug\":null}",
  )
}

/// Test encoding a Unit with partial fields
pub fn encode_unit_partial_test() {
  let unit =
    Unit(
      id: 3,
      name: "liter",
      plural_name: Some("liters"),
      description: Some("Metric unit of volume"),
      base_unit: None,
      open_data_slug: Some("l"),
    )

  let encoded = unit_encoder.encode_unit(unit)
  let json_string = json.to_string(encoded)

  // Should mix Some and None values correctly
  json_string
  |> should.equal(
    "{\"id\":3,\"name\":\"liter\",\"plural_name\":\"liters\",\"description\":\"Metric unit of volume\",\"base_unit\":null,\"open_data_slug\":\"l\"}",
  )
}

/// Test encoding a UnitCreateRequest (only name field)
pub fn encode_unit_create_test() {
  let encoded = unit_encoder.encode_unit_create("tablespoon")
  let json_string = json.to_string(encoded)

  // Should produce simple JSON with just name
  json_string
  |> should.equal("{\"name\":\"tablespoon\"}")
}

/// Test encoding a UnitCreateRequest with special characters
pub fn encode_unit_create_special_chars_test() {
  let encoded = unit_encoder.encode_unit_create("café spoon")
  let json_string = json.to_string(encoded)

  // Should handle unicode properly
  json_string
  |> should.equal("{\"name\":\"café spoon\"}")
}

/// Test encoding multiple Units as array
pub fn encode_multiple_units_test() {
  let units = [
    Unit(
      id: 1,
      name: "gram",
      plural_name: Some("grams"),
      description: None,
      base_unit: None,
      open_data_slug: Some("g"),
    ),
    Unit(
      id: 2,
      name: "liter",
      plural_name: Some("liters"),
      description: None,
      base_unit: None,
      open_data_slug: Some("l"),
    ),
  ]

  let encoded = json.array(units, unit_encoder.encode_unit)
  let json_string = json.to_string(encoded)

  // Should produce array of unit objects
  json_string
  |> should.equal(
    "[{\"id\":1,\"name\":\"gram\",\"plural_name\":\"grams\",\"description\":null,\"base_unit\":null,\"open_data_slug\":\"g\"},{\"id\":2,\"name\":\"liter\",\"plural_name\":\"liters\",\"description\":null,\"base_unit\":null,\"open_data_slug\":\"l\"}]",
  )
}
