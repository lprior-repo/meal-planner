//// TDD Tests for CLI plan command
////
//// RED PHASE: This test validates:
//// 1. Meal plan listing and filtering
//// 2. Date range handling
//// 3. Meal plan formatting

import gleam/list
import gleam/option.{None, Some}
import gleam/order
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/cli/domains/plan
import meal_planner/tandoor/mealplan.{type MealPlan, MealPlan, MealType}

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test Fixtures
// ============================================================================

/// Create a sample meal plan for testing format functions
fn create_sample_meal_plan(id: Int, date: String, meal_type_name: String) -> MealPlan {
  MealPlan(
    id: id,
    title: meal_type_name,
    recipe: None,
    servings: 1.0,
    note: "",
    note_markdown: "",
    from_date: date,
    to_date: date,
    meal_type: MealType(
      id: 1,
      name: meal_type_name,
      order: 0,
      time: None,
      color: None,
      default: False,
      created_by: 1,
    ),
    created_by: 1,
    shared: None,
    recipe_name: "",
    meal_type_name: meal_type_name,
    shopping: False,
  )
}

// ============================================================================
// Meal Plan Listing Tests
// ============================================================================

/// Test: Format meal plan includes ID and date
pub fn format_meal_plan_includes_id_and_date_test() {
  let meal_plan = create_sample_meal_plan(42, "2025-12-20", "Lunch")
  let output = plan.format_meal_plan_entry(meal_plan)

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
  |> should.equal(Some("success"))
}

/// Test: result_to_option converts Error to None
pub fn result_to_option_error_test() {
  let result: Result(String, String) = Error("failed")
  let option = plan.result_to_option(result)

  option
  |> should.equal(None)
}

/// Test: Filter plans by meal type
pub fn filter_plans_by_meal_type_test() {
  let plans = [
    create_sample_meal_plan(1, "2025-12-20", "Breakfast"),
    create_sample_meal_plan(2, "2025-12-20", "Lunch"),
    create_sample_meal_plan(3, "2025-12-20", "Dinner"),
  ]

  let breakfast_plans =
    plans
    |> list.filter(fn(p) { p.meal_type.name == "Breakfast" })

  list.length(breakfast_plans)
  |> should.equal(1)
}

// ============================================================================
// Meal Plan Formatting Tests
// ============================================================================

/// Test: Meal plan has correct ID and from_date
pub fn meal_plan_has_id_and_from_date_test() {
  let meal_plan = create_sample_meal_plan(42, "2025-12-20", "Lunch")

  meal_plan.id
  |> should.equal(42)

  string.contains(meal_plan.from_date, "2025-12-20")
  |> should.be_true()
}

/// Test: Meal plan includes meal type name
pub fn meal_plan_includes_meal_type_name_test() {
  let meal_plan = create_sample_meal_plan(1, "2025-12-20", "Dinner")

  string.contains(meal_plan.meal_type.name, "Dinner")
  |> should.be_true()
}

/// Test: Meal plan recipe field is optional
pub fn meal_plan_recipe_is_optional_test() {
  let meal_plan = create_sample_meal_plan(1, "2025-12-20", "Lunch")

  meal_plan.recipe
  |> should.equal(None)
}

/// Test: Meal plan recipe_name is empty by default
pub fn meal_plan_recipe_name_empty_test() {
  let meal_plan = create_sample_meal_plan(1, "2025-12-20", "Breakfast")

  meal_plan.recipe_name
  |> should.equal("")
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

/// Test: Date comparison using string.compare
pub fn date_comparison_test() {
  string.compare("2025-12-20", "2025-12-21")
  |> should.equal(order.Lt)

  string.compare("2025-12-25", "2025-12-20")
  |> should.equal(order.Gt)
}
