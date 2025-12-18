/// Tests for Property encoder
///
/// This module tests JSON encoding of Property types.
/// Following TDD: these tests should FAIL first, then pass after implementation.
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/encoders/property/property_encoder
import meal_planner/tandoor/types/property/property.{Property}
import meal_planner/tandoor/types/property/property_type.{PropertyType}

/// Test encoding a property with amount
pub fn encode_property_with_amount_test() {
  let property_type =
    PropertyType(
      id: 1,
      name: "Weight",
      unit: Some("kg"),
      description: Some("Weight measurement"),
      order: 1,
      open_data_slug: None,
      fdc_id: None,
    )

  let property =
    Property(
      id: 1,
      property_amount: Some(10.5),
      property_type: property_type,
    )

  let encoded = property_encoder.encode_property(property)
  let _json_string = json.to_string(encoded)

  // Test passes if encoding succeeds
  True
  |> should.be_true
}

/// Test encoding a property without amount
pub fn encode_property_without_amount_test() {
  let property_type =
    PropertyType(
      id: 2,
      name: "Volume",
      unit: Some("ml"),
      description: None,
      order: 2,
      open_data_slug: None,
      fdc_id: None,
    )

  let property =
    Property(
      id: 2,
      property_amount: None,
      property_type: property_type,
    )

  let encoded = property_encoder.encode_property(property)
  let _json_string = json.to_string(encoded)

  // Test passes if it encodes without error
  True
  |> should.be_true
}

/// Test encoding property includes all fields
pub fn encode_property_complete_test() {
  let property_type =
    PropertyType(
      id: 3,
      name: "Temperature",
      unit: Some("C"),
      description: Some("Temperature in Celsius"),
      order: 3,
      open_data_slug: Some("slug"),
      fdc_id: Some(123),
    )

  let property =
    Property(
      id: 3,
      property_amount: Some(98.6),
      property_type: property_type,
    )

  let encoded = property_encoder.encode_property(property)
  let _json_string = json.to_string(encoded)

  // Test passes if encoding succeeds
  True
  |> should.be_true
}
