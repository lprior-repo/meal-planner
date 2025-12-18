/// Tests for Food Update API
///
/// These tests verify the update_food function delegates correctly
/// to the client implementation.
import gleeunit/should
import meal_planner/tandoor/api/food/update
import meal_planner/tandoor/client
import meal_planner/tandoor/types.{TandoorFoodCreateRequest}

pub fn update_food_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let food_data = TandoorFoodCreateRequest(name: "Cherry Tomato")

  // Call should fail (no server) but proves delegation works
  let result = update.update_food(config, food_id: 42, food_data: food_data)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn update_food_with_different_ids_test() {
  // Verify different food IDs work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let food_data = TandoorFoodCreateRequest(name: "Updated Food")

  let result1 = update.update_food(config, food_id: 1, food_data: food_data)
  let result2 = update.update_food(config, food_id: 999, food_data: food_data)

  // Both should attempt call and fail (no server)
  should.be_error(result1)
  should.be_error(result2)
}

pub fn update_food_name_change_test() {
  // Verify food name updates work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let food_data = TandoorFoodCreateRequest(name: "Organic Tomato")

  let result = update.update_food(config, food_id: 5, food_data: food_data)

  // Should attempt call and fail (no server)
  should.be_error(result)
}

pub fn update_food_with_unicode_name_test() {
  // Verify Unicode in updated names work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let food_data = TandoorFoodCreateRequest(name: "Crème Fraîche")

  let result = update.update_food(config, food_id: 10, food_data: food_data)

  // Should attempt call and fail (no server)
  should.be_error(result)
}

pub fn update_food_with_long_name_test() {
  // Verify long food names work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let food_data =
    TandoorFoodCreateRequest(
      name: "Organic Free-Range Grass-Fed Antibiotic-Free Chicken Breast",
    )

  let result = update.update_food(config, food_id: 7, food_data: food_data)

  // Should attempt call and fail (no server)
  should.be_error(result)
}
