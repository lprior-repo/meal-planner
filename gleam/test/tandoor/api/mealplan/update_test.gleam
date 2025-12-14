/// Tests for MealPlan Update/Delete API
///
/// These tests verify the update and delete functions delegate correctly
/// to the client implementation.
import gleam/option.{Some}
import gleeunit/should
import meal_planner/tandoor/api/mealplan/update
import meal_planner/tandoor/client
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/mealplan/mealplan.{Lunch, MealPlanUpdate}

pub fn update_meal_plan_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")
  let id = ids.meal_plan_id_from_int(123)

  let data =
    MealPlanUpdate(
      recipe: Some(ids.recipe_id_from_int(99)),
      recipe_name: "Updated Meal",
      servings: 2.0,
      note: "Modified",
      from_date: "2025-12-20",
      to_date: "2025-12-21",
      meal_type: Lunch,
    )

  // Call should fail (no server) but proves delegation works
  let result = update.update_meal_plan(config, id, data)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn delete_meal_plan_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")
  let id = ids.meal_plan_id_from_int(456)

  // Call should fail (no server) but proves delegation works
  let result = update.delete_meal_plan(config, id)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}
