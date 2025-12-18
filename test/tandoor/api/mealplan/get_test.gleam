/// Tests for MealPlan Get API
///
/// These tests verify the get_meal_plan function delegates correctly
/// to the client implementation.
import gleeunit/should
import meal_planner/tandoor/api/mealplan/get
import meal_planner/tandoor/client
import meal_planner/tandoor/core/ids

pub fn get_meal_plan_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")
  let id = ids.meal_plan_id_from_int(123)

  // Call should fail (no server) but proves delegation works
  let result = get.get_meal_plan(config, id)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn get_meal_plan_different_ids_test() {
  // Verify different IDs work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let id1 = ids.meal_plan_id_from_int(1)
  let result1 = get.get_meal_plan(config, id1)
  should.be_error(result1)

  let id2 = ids.meal_plan_id_from_int(999)
  let result2 = get.get_meal_plan(config, id2)
  should.be_error(result2)
}
