/// Tests for Property decoder
///
/// This module tests JSON decoding of Property types.
/// Following TDD: these tests should FAIL first, then pass after implementation.
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/decoders/property/property_decoder
import meal_planner/tandoor/types/property/property.{
  type Property, FoodProperty, Property, RecipeProperty,
}

/// Test decoding a recipe property
pub fn decode_property_recipe_test() {
  let json_string =
    "{\"id\":1,\"name\":\"Allergens\",\"description\":\"Contains allergen information\",\"property_type\":\"RECIPE\",\"unit\":null,\"order\":10,\"created_at\":\"2024-01-01T00:00:00Z\",\"updated_at\":\"2024-01-01T00:00:00Z\"}"

  let result =
    json.parse(json_string, using: decode.dynamic)
    |> should.be_ok
    |> decode.run(property_decoder.property_decoder())

  result
  |> should.be_ok
  |> should.equal(Property(
    id: 1,
    name: "Allergens",
    description: "Contains allergen information",
    property_type: RecipeProperty,
    unit: None,
    order: 10,
    created_at: "2024-01-01T00:00:00Z",
    updated_at: "2024-01-01T00:00:00Z",
  ))
}

/// Test decoding a food property with unit
pub fn decode_property_food_with_unit_test() {
  let json_string =
    "{\"id\":2,\"name\":\"Protein\",\"description\":\"Custom protein measurement\",\"property_type\":\"FOOD\",\"unit\":\"grams\",\"order\":5,\"created_at\":\"2024-01-02T00:00:00Z\",\"updated_at\":\"2024-01-02T00:00:00Z\"}"

  let result =
    json.parse(json_string, using: decode.dynamic)
    |> should.be_ok
    |> decode.run(property_decoder.property_decoder())

  result
  |> should.be_ok
  |> should.equal(Property(
    id: 2,
    name: "Protein",
    description: "Custom protein measurement",
    property_type: FoodProperty,
    unit: Some("grams"),
    order: 5,
    created_at: "2024-01-02T00:00:00Z",
    updated_at: "2024-01-02T00:00:00Z",
  ))
}

/// Test decoding property with empty description
pub fn decode_property_empty_description_test() {
  let json_string =
    "{\"id\":3,\"name\":\"Simple\",\"description\":\"\",\"property_type\":\"RECIPE\",\"unit\":null,\"order\":1,\"created_at\":\"2024-01-03T00:00:00Z\",\"updated_at\":\"2024-01-03T00:00:00Z\"}"

  let result =
    json.parse(json_string, using: decode.dynamic)
    |> should.be_ok
    |> decode.run(property_decoder.property_decoder())

  result
  |> should.be_ok
  |> fn(p: Property) {
    p.description
    |> should.equal("")
  }
}

/// Test decoding list of properties
pub fn decode_property_list_test() {
  let json_string =
    "[{\"id\":1,\"name\":\"Prop1\",\"description\":\"First\",\"property_type\":\"RECIPE\",\"unit\":null,\"order\":1,\"created_at\":\"2024-01-01T00:00:00Z\",\"updated_at\":\"2024-01-01T00:00:00Z\"},{\"id\":2,\"name\":\"Prop2\",\"description\":\"Second\",\"property_type\":\"FOOD\",\"unit\":\"ml\",\"order\":2,\"created_at\":\"2024-01-02T00:00:00Z\",\"updated_at\":\"2024-01-02T00:00:00Z\"}]"

  let result =
    json.parse(json_string, using: decode.dynamic)
    |> should.be_ok
    |> decode.run(decode.list(property_decoder.property_decoder()))

  result
  |> should.be_ok
  |> list.length
  |> should.equal(2)
}

/// Test decoding property with minimal fields
pub fn decode_property_minimal_test() {
  let json_string =
    "{\"id\":4,\"name\":\"Min\",\"description\":\"\",\"property_type\":\"RECIPE\",\"unit\":null,\"order\":0,\"created_at\":\"2024-01-04T00:00:00Z\",\"updated_at\":\"2024-01-04T00:00:00Z\"}"

  let result =
    json.parse(json_string, using: decode.dynamic)
    |> should.be_ok
    |> decode.run(property_decoder.property_decoder())

  result
  |> should.be_ok
  |> fn(p: Property) {
    p.name
    |> should.equal("Min")
    p.unit
    |> should.equal(None)
  }
}
