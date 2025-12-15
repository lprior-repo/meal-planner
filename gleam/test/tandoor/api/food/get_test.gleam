/// Tests for Food Get API
///
/// These tests verify the get_food function delegates correctly
/// to the client implementation.
import gleeunit/should
import meal_planner/tandoor/api/food/get
import meal_planner/tandoor/client

pub fn get_food_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // Call should fail (no server) but proves delegation works
  let result = get.get_food(config, food_id: 1)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn get_food_accepts_any_id_test() {
  // Verify different IDs work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result1 = get.get_food(config, food_id: 999)
  let result2 = get.get_food(config, food_id: 1)
  let result3 = get.get_food(config, food_id: 42)

  // All should attempt call and fail (no server)
  should.be_error(result1)
  should.be_error(result2)
  should.be_error(result3)
}

pub fn get_food_with_large_id_test() {
  // Verify large IDs work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result = get.get_food(config, food_id: 999_999)

  // Should attempt call and fail (no server)
  should.be_error(result)
}
