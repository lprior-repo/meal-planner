//// Tandoor Meal Plans Client Tests
////
//// Tests for the extracted meal plans client module

import gleam/option
import gleeunit/should
import meal_planner/tandoor/clients/meal_plans.{
  type CreateMealPlanRequest, CreateMealPlanRequest,
}
import meal_planner/tandoor/types/mealplan/meal_type

pub fn meal_plans_module_exists_test() {
  // This test verifies the module can be imported
  // We'll test actual functions after extraction
  should.equal(1, 1)
}

pub fn create_meal_plan_request_type_exists_test() {
  // Verify CreateMealPlanRequest type was extracted
  let _request =
    CreateMealPlanRequest(
      title: "Test Meal",
      recipe: option.None,
      servings: 1.0,
      note: "Test note",
      from_date: "2025-12-18",
      to_date: "2025-12-18",
      meal_type: meal_type.meal_type_from_string("BREAKFAST"),
    )
  should.equal(1, 1)
}
