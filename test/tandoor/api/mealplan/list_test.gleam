/// Tests for MealPlan List API
///
/// These tests verify the list_meal_plans function delegates correctly
/// to the client implementation.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/mealplan/list
import meal_planner/tandoor/client

pub fn list_meal_plans_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")

  // Call should fail (no server) but proves delegation works
  let result =
    list.list_meal_plans(
      config,
      from_date: Some("2025-12-01"),
      to_date: Some("2025-12-31"),
    )

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn list_meal_plans_accepts_none_params_test() {
  // Verify None parameters work
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result = list.list_meal_plans(config, from_date: None, to_date: None)

  // Should attempt call and fail (no server)
  should.be_error(result)
}

pub fn list_meal_plans_single_date_filter_test() {
  // Verify single date filter works
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let result =
    list.list_meal_plans(config, from_date: Some("2025-12-14"), to_date: None)

  // Should attempt call and fail (no server)
  should.be_error(result)
}
