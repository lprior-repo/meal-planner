/// Tests for Property encoder
///
/// This module tests JSON encoding of Property types.
/// Following TDD: these tests should FAIL first, then pass after implementation.
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import meal_planner/tandoor/encoders/property/property_encoder
import meal_planner/tandoor/types/property/property.{
  FoodProperty, RecipeProperty,
}

/// Test encoding PropertyCreateRequest for recipe
pub fn encode_property_create_recipe_test() {
  let create_req =
    property_encoder.PropertyCreateRequest(
      name: "Allergens",
      description: "Allergen info",
      property_type: RecipeProperty,
      unit: None,
      order: 10,
    )

  let encoded = property_encoder.encode_property_create_request(create_req)
  let json_string = json.to_string(encoded)

  // Should produce complete JSON
  json_string
  |> should.equal(
    "{\"name\":\"Allergens\",\"description\":\"Allergen info\",\"property_type\":\"RECIPE\",\"unit\":null,\"order\":10}",
  )
}

/// Test encoding PropertyCreateRequest for food with unit
pub fn encode_property_create_food_with_unit_test() {
  let create_req =
    property_encoder.PropertyCreateRequest(
      name: "Protein",
      description: "Protein content",
      property_type: FoodProperty,
      unit: Some("grams"),
      order: 5,
    )

  let encoded = property_encoder.encode_property_create_request(create_req)
  let json_string = json.to_string(encoded)

  // Should include unit
  string.contains(json_string, "\"unit\":\"grams\"")
  |> should.be_true
  string.contains(json_string, "\"property_type\":\"FOOD\"")
  |> should.be_true
}

/// Test encoding PropertyUpdateRequest (partial)
pub fn encode_property_update_partial_test() {
  let update_req =
    property_encoder.PropertyUpdateRequest(
      name: Some("Updated Name"),
      description: None,
      property_type: None,
      unit: Some("ml"),
      order: None,
    )

  let encoded = property_encoder.encode_property_update_request(update_req)
  let json_string = json.to_string(encoded)

  // Should only include provided fields
  string.contains(json_string, "\"name\":\"Updated Name\"")
  |> should.be_true
  string.contains(json_string, "\"unit\":\"ml\"")
  |> should.be_true
}

/// Test encoding with empty description
pub fn encode_property_empty_description_test() {
  let create_req =
    property_encoder.PropertyCreateRequest(
      name: "Simple",
      description: "",
      property_type: RecipeProperty,
      unit: None,
      order: 1,
    )

  let encoded = property_encoder.encode_property_create_request(create_req)
  let json_string = json.to_string(encoded)

  string.contains(json_string, "\"description\":\"\"")
  |> should.be_true
}
