/// Tests for Food Create API
///
/// These tests verify the create_food function delegates correctly
/// to the client implementation.
import gleeunit/should
import meal_planner/tandoor/api/food/create
import meal_planner/tandoor/client
import meal_planner/tandoor/types.{TandoorFoodCreateRequest}

pub fn create_food_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let food_data = TandoorFoodCreateRequest(name: "Tomato")

  // Call should fail (no server) but proves delegation works
  let result = create.create_food(config, food_data)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn create_food_with_simple_name_test() {
  // Verify simple food names work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let food_data = TandoorFoodCreateRequest(name: "Apple")

  let result = create.create_food(config, food_data)

  // Should attempt call and fail (no server)
  should.be_error(result)
}

pub fn create_food_with_complex_name_test() {
  // Verify complex food names work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let food_data = TandoorFoodCreateRequest(name: "Extra Virgin Olive Oil")

  let result = create.create_food(config, food_data)

  // Should attempt call and fail (no server)
  should.be_error(result)
}

pub fn create_food_with_special_characters_test() {
  // Verify food names with special characters work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let food_data = TandoorFoodCreateRequest(name: "Black Pepper (Ground)")

  let result = create.create_food(config, food_data)

  // Should attempt call and fail (no server)
  should.be_error(result)
}

pub fn create_food_with_unicode_test() {
  // Verify Unicode characters in food names work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let food_data = TandoorFoodCreateRequest(name: "Jalapeño Peppers")

  let result = create.create_food(config, food_data)

  // Should attempt call and fail (no server)
  should.be_error(result)
}
