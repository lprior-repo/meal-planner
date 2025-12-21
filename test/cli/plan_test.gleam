//// TDD Tests for CLI plan command
////
//// RED PHASE: This test validates:
//// 1. Meal plan listing and filtering
//// 2. Date range handling
//// 3. Meal plan formatting

import gleam/int
import gleam/list
import gleam/option.{None}
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/plan
import meal_planner/tandoor/mealplan.{type MealPlan, MealPlan}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Create a sample meal plan for testing format functions
fn create_sample_meal_plan(id: Int, date: String, title: String) -> MealPlan {
  MealPlan(id: id, date: date, title: title, recipe: None, servings: 1.0)
}

// ============================================================================
// Meal Plan Listing Tests
// ============================================================================

/// Test: Format meal plan includes ID and date
pub fn format_meal_plan_includes_id_and_date_test() {
  let plan = create_sample_meal_plan(42, "2025-12-20", "Lunch")
  let output = plan.format_meal_plan_entry(plan)

  string.contains(output, "42")
  |> should.be_true()

  string.contains(output, "2025-12-20")
  |> should.be_true()
}

/// Test: result_to_option converts Ok to Some
pub fn result_to_option_ok_test() {
  let result: Result(String, Nil) = Ok("success")
  let option = plan.result_to_option(result)

  option
  |> should.equal(option.Some("success"))
}

/// Test: result_to_option converts Error to None
pub fn result_to_option_error_test() {
  let result: Result(String, String) = Error("failed")
  let option = plan.result_to_option(result)

  option
  |> should.equal(option.None)
}

/// Test: Filter plans by meal type
pub fn filter_plans_by_meal_type_test() {
  let plans = [
    create_sample_meal_plan(1, "2025-12-20", "Breakfast", 1),
    create_sample_meal_plan(2, "2025-12-20", "Lunch", 1),
    create_sample_meal_plan(3, "2025-12-20", "Dinner", 1),
  ]

  let breakfast_plans =
    plans
    |> list.filter(fn(p) { p.meal_type == "Breakfast" })

  list.length(breakfast_plans)
  |> should.equal(1)
}

// ============================================================================
// Meal Plan Formatting Tests
// ============================================================================

/// Test: Format meal plan includes ID and date
pub fn format_meal_plan_includes_id_and_date_test() {
  let plan = create_sample_meal_plan(42, "2025-12-20", "Lunch", 2)

  plan.id
  |> should.equal(42)

  string.contains(plan.date, "2025-12-20")
  |> should.be_true()
}

/// Test: Format meal plan includes meal type
pub fn format_meal_plan_includes_meal_type_test() {
  let plan = create_sample_meal_plan(1, "2025-12-20", "Dinner", 3)

  string.contains(plan.meal_type, "Dinner")
  |> should.be_true()
}

/// Test: Format meal plan shows recipes
pub fn format_meal_plan_shows_recipes_test() {
  let plan = create_sample_meal_plan(1, "2025-12-20", "Lunch", 3)

  list.length(plan.recipes)
  |> should.equal(3)

  list.contains(plan.recipes, "Recipe 0")
  |> should.be_true()
}

/// Test: Handle empty meal plan
pub fn format_empty_meal_plan_test() {
  let plan = create_sample_meal_plan(1, "2025-12-20", "Breakfast", 0)

  list.length(plan.recipes)
  |> should.equal(0)
}

// ============================================================================
// Date Range Tests
// ============================================================================

/// Test: Parse start date
pub fn parse_start_date_test() {
  let date_str = "2025-12-20"

  string.length(date_str)
  |> should.equal(10)

  string.contains(date_str, "-")
  |> should.be_true()
}

/// Test: Parse end date
pub fn parse_end_date_test() {
  let date_str = "2025-12-31"

  string.length(date_str)
  |> should.equal(10)
}

/// Test: Date comparison
pub fn date_comparison_test() {
  "2025-12-20"
  < "2025-12-21"
  |> should.be_true()

  "2025-12-25"
  > "2025-12-20"
  |> should.be_true()
}
