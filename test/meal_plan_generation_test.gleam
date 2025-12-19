//// RED Phase: Failing test for meal plan generation
////
//// Test: meal_plan_respects_calorie_budget
//// Behavior: Daily calories must be within ±10% of target
//// Fixture: test/fixtures/meal_plan/complete_week_balanced.json
//// Expected: FAIL (no generation implementation yet)

import gleam/json
import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/types/macros
import meal_planner/types/meal_plan.{
  daily_macros_calories, meal_plan_days, meal_plan_decoder,
  meal_plan_target_macros,
}
import simplifile

pub fn main() {
  gleeunit.main()
}

/// Test that all days in a meal plan stay within ±10% of target calories
///
/// RED PHASE: This test MUST FAIL because:
/// - No generation implementation exists yet
/// - This validates the test fixture structure
/// - Proves test fails for the RIGHT reason (calorie budget violation)
pub fn meal_plan_respects_calorie_budget_test() {
  // Load fixture
  let fixture_path = "test/fixtures/meal_plan/complete_week_balanced.json"
  let assert Ok(json_string) = simplifile.read(fixture_path)

  // Decode meal plan from JSON string
  let assert Ok(meal_plan) = json.parse(json_string, meal_plan_decoder())

  // Get target calories from target macros
  let target_macros = meal_plan_target_macros(meal_plan)
  let target_calories = macros.calories(target_macros)

  // Calculate ±10% tolerance bounds
  let lower_bound = target_calories *. 0.9
  let upper_bound = target_calories *. 1.1

  // Check each day's calories against budget
  let days = meal_plan_days(meal_plan)

  days
  |> list.each(fn(day) {
    let daily_macros = meal_plan.day_meals_macros(day)
    let actual_calories = daily_macros_calories(daily_macros)

    // Assert: actual calories within ±10% of target
    // This WILL FAIL if generation doesn't respect budget
    let within_budget =
      actual_calories >=. lower_bound && actual_calories <=. upper_bound
    should.be_true(within_budget)
  })
}
