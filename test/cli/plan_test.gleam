//// TDD Tests for CLI plan command

import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/plan

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Meal Plan Day Formatting Tests
// ============================================================================

pub fn format_meal_plan_day_test() {
  let day =
    plan.MealPlanDay(
      day: "Monday",
      breakfast: "Oatmeal with berries",
      lunch: "Chicken salad",
      dinner: "Grilled salmon",
      total_calories: 2050.0,
    )
  let output = plan.format_meal_plan_day(day)

  string.contains(output, "Monday")
  |> should.be_true()

  string.contains(output, "Breakfast")
  |> should.be_true()

  string.contains(output, "Oatmeal with berries")
  |> should.be_true()

  string.contains(output, "2050")
  |> should.be_true()
}

pub fn format_meal_plan_day_includes_all_meals_test() {
  let day =
    plan.MealPlanDay(
      day: "Wednesday",
      breakfast: "Eggs and toast",
      lunch: "Tuna salad",
      dinner: "Turkey tacos",
      total_calories: 2100.0,
    )
  let output = plan.format_meal_plan_day(day)

  string.contains(output, "Lunch")
  |> should.be_true()

  string.contains(output, "Dinner")
  |> should.be_true()

  string.contains(output, "Tuna salad")
  |> should.be_true()

  string.contains(output, "Turkey tacos")
  |> should.be_true()
}

// ============================================================================
// Meal Plan Generation Tests
// ============================================================================

pub fn generate_sample_plan_test() {
  let plan_days = plan.generate_sample_plan()

  plan_days
  |> list.length
  |> should.equal(7)
}

pub fn generate_sample_plan_has_variety_test() {
  let plan_days = plan.generate_sample_plan()

  let breakfasts =
    plan_days
    |> list.map(fn(d) { d.breakfast })
    |> list.fold("", fn(acc, b) { acc <> b })

  string.contains(breakfasts, "Oatmeal")
  |> should.be_true()

  string.contains(breakfasts, "Yogurt")
  |> should.be_true()
}

pub fn generate_sample_plan_calorie_range_test() {
  let plan_days = plan.generate_sample_plan()

  plan_days
  |> list.each(fn(day) {
    let cals = day.total_calories
    // Each day should be between 1800 and 2300
    cals
    |> should.be_greater_than(1800.0)
    cals
    |> should.be_less_than(2400.0)
  })
}

pub fn generate_sample_plan_each_day_has_meals_test() {
  let plan_days = plan.generate_sample_plan()

  plan_days
  |> list.each(fn(day) {
    string.length(day.breakfast)
    |> should.be_greater_than(0)
    string.length(day.lunch)
    |> should.be_greater_than(0)
    string.length(day.dinner)
    |> should.be_greater_than(0)
  })
}
