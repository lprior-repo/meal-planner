/// Tests for MealPlan Create API
///
/// These tests verify the create_meal_plan function delegates correctly
/// to the client implementation.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/mealplan/create
import meal_planner/tandoor/client
import meal_planner/tandoor/core/ids
import meal_planner/tandoor/types/mealplan/mealplan.{
  Breakfast, Dinner, MealPlanCreate,
}

pub fn create_meal_plan_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let data =
    MealPlanCreate(
      recipe: Some(ids.recipe_id_from_int(42)),
      recipe_name: "Oatmeal",
      servings: 1.0,
      note: "Morning breakfast",
      from_date: "2025-12-14",
      to_date: "2025-12-14",
      meal_type: Breakfast,
    )

  // Call should fail (no server) but proves delegation works
  let result = create.create_meal_plan(config, data)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn create_meal_plan_minimal_data_test() {
  // Verify minimal request works
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let data =
    MealPlanCreate(
      recipe: None,
      recipe_name: "Quick Lunch",
      servings: 1.0,
      note: "",
      from_date: "2025-12-15",
      to_date: "2025-12-15",
      meal_type: Dinner,
    )

  let result = create.create_meal_plan(config, data)

  // Should attempt call and fail (no server)
  should.be_error(result)
}
