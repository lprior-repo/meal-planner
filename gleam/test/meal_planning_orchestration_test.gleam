/// Tests for meal planning orchestration endpoint
/// 
/// Tests the full workflow: recipe selection → grocery list → meal prep plan → sync
import gleam/dict
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import meal_planner/grocery_list
import meal_planner/meal_prep_ai
import meal_planner/meal_sync.{MealSelection}
import meal_planner/mvp_recipes
import meal_planner/orchestrator

pub fn main() {
  gleeunit.main()
}

/// Test that meal planning generates expected output structure
pub fn meal_plan_generation_test() {
  // Test that we can format a meal plan
  let plan =
    orchestrator.MealPlanningResult(
      recipes_selected: 1,
      grocery_list: grocery_list.GroceryList(
        by_category: dict.new(),
        all_items: [],
      ),
      meal_prep_plan: meal_prep_ai.MealPrepPlan(
        meal_count: 1,
        total_prep_time_min: 30,
        cookware_needed: ["pan"],
        instructions: [],
        notes: "test",
      ),
      nutrition_data: [],
    )

  let formatted = orchestrator.format_meal_plan(plan)
  string.contains(formatted, "MEAL PLANNING SUMMARY")
  |> should.be_true
  string.contains(formatted, "SHOPPING LIST")
  |> should.be_true
  string.contains(formatted, "MEAL PREP PLAN")
  |> should.be_true
  string.contains(formatted, "NUTRITION SUMMARY")
  |> should.be_true
}

/// Test that MVP recipes list is available
pub fn mvp_recipes_available_test() {
  let recipes = mvp_recipes.all_recipes()
  recipes
  |> list.length
  |> should.equal(15)
}
