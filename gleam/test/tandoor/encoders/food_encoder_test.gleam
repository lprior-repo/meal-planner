/// Tests for Food encoder
///
/// This module tests JSON encoding of Food and FoodCreate types.
/// Following TDD: these tests should FAIL first, then pass after implementation.
import gleam/json
import gleeunit/should
import meal_planner/tandoor/types.{TandoorFoodCreateRequest}

// Import the encoder module (will fail until we create it)
import meal_planner/tandoor/encoders/food/food_encoder

/// Test encoding a FoodCreateRequest to JSON
pub fn encode_food_create_request_test() {
  let food_request = TandoorFoodCreateRequest(name: "Tomato")

  let encoded = food_encoder.encode_food_create(food_request)
  let json_string = json.to_string(encoded)

  // Should produce: {"name": "Tomato"}
  json_string
  |> should.equal("{\"name\":\"Tomato\"}")
}

/// Test encoding a FoodCreateRequest with special characters
pub fn encode_food_create_with_special_chars_test() {
  let food_request = TandoorFoodCreateRequest(name: "Jalapeño Pepper")

  let encoded = food_encoder.encode_food_create(food_request)
  let json_string = json.to_string(encoded)

  // Should handle unicode properly
  json_string
  |> should.equal("{\"name\":\"Jalapeño Pepper\"}")
}

/// Test encoding a FoodCreateRequest with empty name
pub fn encode_food_create_empty_name_test() {
  let food_request = TandoorFoodCreateRequest(name: "")

  let encoded = food_encoder.encode_food_create(food_request)
  let json_string = json.to_string(encoded)

  // Should encode empty string as valid JSON
  json_string
  |> should.equal("{\"name\":\"\"}")
}

/// Test encoding multiple FoodCreateRequests
pub fn encode_multiple_food_creates_test() {
  let foods = [
    TandoorFoodCreateRequest(name: "Carrot"),
    TandoorFoodCreateRequest(name: "Onion"),
    TandoorFoodCreateRequest(name: "Garlic"),
  ]

  let encoded = json.array(foods, food_encoder.encode_food_create)
  let json_string = json.to_string(encoded)

  // Should produce array of food objects
  json_string
  |> should.equal(
    "[{\"name\":\"Carrot\"},{\"name\":\"Onion\"},{\"name\":\"Garlic\"}]",
  )
}
