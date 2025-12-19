//// Tests for constraint satisfaction solver
////
//// These tests verify:
//// - Constraint evaluation
//// - Conflict detection
//// - Schedule optimization
//// - Preference weighting

import gleam/list
import gleam/option
import gleeunit/should
import meal_planner/id
import meal_planner/scheduler/advanced
import meal_planner/scheduler/constraint_solver
import meal_planner/types/macros.{Macros}

pub fn evaluate_budget_constraint_satisfied_test() {
  let schedule = create_test_schedule_with_cost(100.0)
  let constraint = advanced.Budget(max_cost: 150.0, currency: "USD")

  constraint_solver.evaluate_constraint(constraint, schedule)
  |> should.equal(advanced.Satisfied)
}

pub fn evaluate_budget_constraint_violated_test() {
  let schedule = create_test_schedule_with_cost(200.0)
  let constraint = advanced.Budget(max_cost: 150.0, currency: "USD")

  case constraint_solver.evaluate_constraint(constraint, schedule) {
    advanced.Violated(_, advanced.Hard) -> True
    _ -> False
  }
  |> should.be_true
}

pub fn evaluate_nutrition_constraint_satisfied_test() {
  let schedule = create_test_schedule_with_nutrition(2000.0, 150.0, 200.0, 70.0)
  let target =
    advanced.NutritionTarget(
      calories: advanced.FloatRange(min: 1800.0, max: 2200.0),
      protein: advanced.FloatRange(min: 120.0, max: 180.0),
      carbs: advanced.FloatRange(min: 180.0, max: 220.0),
      fat: advanced.FloatRange(min: 60.0, max: 80.0),
      fiber: option.None,
    )
  let constraint = advanced.Nutrition(target)

  constraint_solver.evaluate_constraint(constraint, schedule)
  |> should.equal(advanced.Satisfied)
}

pub fn evaluate_repetition_constraint_satisfied_test() {
  let schedule = create_test_schedule_with_varied_recipes()
  let constraint = advanced.MaxRepetition(max_times: 2)

  constraint_solver.evaluate_constraint(constraint, schedule)
  |> should.equal(advanced.Satisfied)
}

pub fn evaluate_repetition_constraint_violated_test() {
  let schedule = create_test_schedule_with_repeated_recipes()
  let constraint = advanced.MaxRepetition(max_times: 1)

  case constraint_solver.evaluate_constraint(constraint, schedule) {
    advanced.Violated(_, advanced.Soft) -> True
    _ -> False
  }
  |> should.be_true
}

pub fn evaluate_must_include_constraint_satisfied_test() {
  let recipe1 = id.recipe_id("recipe_1")
  let recipe2 = id.recipe_id("recipe_2")
  let schedule = create_test_schedule_with_recipes([recipe1, recipe2])
  let constraint = advanced.MustInclude([recipe1, recipe2])

  constraint_solver.evaluate_constraint(constraint, schedule)
  |> should.equal(advanced.Satisfied)
}

pub fn evaluate_must_include_constraint_violated_test() {
  let recipe1 = id.recipe_id("recipe_1")
  let recipe2 = id.recipe_id("recipe_2")
  let recipe3 = id.recipe_id("recipe_3")
  let schedule = create_test_schedule_with_recipes([recipe1, recipe2])
  let constraint = advanced.MustInclude([recipe1, recipe2, recipe3])

  case constraint_solver.evaluate_constraint(constraint, schedule) {
    advanced.Violated(_, advanced.Hard) -> True
    _ -> False
  }
  |> should.be_true
}

pub fn evaluate_must_exclude_constraint_satisfied_test() {
  let recipe1 = id.recipe_id("recipe_1")
  let recipe2 = id.recipe_id("recipe_2")
  let recipe3 = id.recipe_id("recipe_3")
  let schedule = create_test_schedule_with_recipes([recipe1, recipe2])
  let constraint = advanced.MustExclude([recipe3])

  constraint_solver.evaluate_constraint(constraint, schedule)
  |> should.equal(advanced.Satisfied)
}

pub fn evaluate_constraints_all_satisfied_test() {
  let schedule = create_test_schedule_with_cost(100.0)
  let constraints = [
    advanced.Budget(max_cost: 150.0, currency: "USD"),
    advanced.TimeLimit(max_minutes: 300),
  ]

  constraint_solver.evaluate_constraints(constraints, schedule)
  |> should.be_true(fn(score) { score >=. 0.9 })
}

pub fn detect_time_conflicts_none_test() {
  let schedule = create_test_schedule_no_conflicts()

  constraint_solver.detect_conflicts(schedule)
  |> list.is_empty
  |> should.be_true
}

pub fn detect_time_conflicts_found_test() {
  let schedule = create_test_schedule_with_time_conflicts()

  constraint_solver.detect_conflicts(schedule)
  |> list.is_empty
  |> should.be_false
}

pub fn optimize_schedule_minimize_cost_test() {
  let schedule = create_test_schedule_with_cost(100.0)
  let objective = advanced.MinimizeCost
  let constraints = []

  case constraint_solver.optimize_schedule(schedule, objective, constraints) {
    Ok(result) -> result.score >. 0.0
    Error(_) -> False
  }
  |> should.be_true
}

// ============================================================================
// Test Helpers
// ============================================================================

fn create_test_schedule_with_cost(cost: Float) -> advanced.MealSchedule {
  advanced.MealSchedule(
    user_id: id.user_id("user_1"),
    start_date: "2025-01-01",
    end_date: "2025-01-07",
    meals: [],
    nutrition_summary: Macros(protein: 150.0, fat: 70.0, carbs: 200.0),
    total_cost: option.Some(cost),
    recurrence: option.None,
  )
}

fn create_test_schedule_with_nutrition(
  calories: Float,
  protein: Float,
  carbs: Float,
  fat: Float,
) -> advanced.MealSchedule {
  let _ = calories
  advanced.MealSchedule(
    user_id: id.user_id("user_1"),
    start_date: "2025-01-01",
    end_date: "2025-01-07",
    meals: [],
    nutrition_summary: Macros(protein: protein, fat: fat, carbs: carbs),
    total_cost: option.None,
    recurrence: option.None,
  )
}

fn create_test_schedule_with_varied_recipes() -> advanced.MealSchedule {
  let meals = [
    create_test_meal("recipe_1", "2025-01-01", "08:00"),
    create_test_meal("recipe_2", "2025-01-01", "12:00"),
    create_test_meal("recipe_3", "2025-01-01", "18:00"),
    create_test_meal("recipe_1", "2025-01-02", "08:00"),
  ]

  advanced.MealSchedule(
    user_id: id.user_id("user_1"),
    start_date: "2025-01-01",
    end_date: "2025-01-07",
    meals: meals,
    nutrition_summary: Macros(protein: 150.0, fat: 70.0, carbs: 200.0),
    total_cost: option.None,
    recurrence: option.None,
  )
}

fn create_test_schedule_with_repeated_recipes() -> advanced.MealSchedule {
  let meals = [
    create_test_meal("recipe_1", "2025-01-01", "08:00"),
    create_test_meal("recipe_1", "2025-01-01", "12:00"),
    create_test_meal("recipe_1", "2025-01-01", "18:00"),
  ]

  advanced.MealSchedule(
    user_id: id.user_id("user_1"),
    start_date: "2025-01-01",
    end_date: "2025-01-07",
    meals: meals,
    nutrition_summary: Macros(protein: 150.0, fat: 70.0, carbs: 200.0),
    total_cost: option.None,
    recurrence: option.None,
  )
}

fn create_test_schedule_with_recipes(
  recipe_ids: List(id.RecipeId),
) -> advanced.MealSchedule {
  let meals =
    recipe_ids
    |> list.index_map(fn(recipe_id, idx) {
      let time = case idx {
        0 -> "08:00"
        1 -> "12:00"
        _ -> "18:00"
      }
      advanced.ScheduledMeal(
        recipe_id: recipe_id,
        date: "2025-01-01",
        time: time,
        meal_type: advanced.Breakfast,
        nutrition: Macros(protein: 50.0, fat: 20.0, carbs: 60.0),
        prep_time: option.Some(30),
        cost: option.Some(15.0),
      )
    })

  advanced.MealSchedule(
    user_id: id.user_id("user_1"),
    start_date: "2025-01-01",
    end_date: "2025-01-07",
    meals: meals,
    nutrition_summary: Macros(protein: 150.0, fat: 70.0, carbs: 200.0),
    total_cost: option.None,
    recurrence: option.None,
  )
}

fn create_test_schedule_no_conflicts() -> advanced.MealSchedule {
  let meals = [
    create_test_meal("recipe_1", "2025-01-01", "08:00"),
    create_test_meal("recipe_2", "2025-01-01", "12:00"),
    create_test_meal("recipe_3", "2025-01-01", "18:00"),
  ]

  advanced.MealSchedule(
    user_id: id.user_id("user_1"),
    start_date: "2025-01-01",
    end_date: "2025-01-07",
    meals: meals,
    nutrition_summary: Macros(protein: 150.0, fat: 70.0, carbs: 200.0),
    total_cost: option.None,
    recurrence: option.None,
  )
}

fn create_test_schedule_with_time_conflicts() -> advanced.MealSchedule {
  let meals = [
    create_test_meal("recipe_1", "2025-01-01", "08:00"),
    create_test_meal("recipe_2", "2025-01-01", "08:00"),
  ]

  advanced.MealSchedule(
    user_id: id.user_id("user_1"),
    start_date: "2025-01-01",
    end_date: "2025-01-07",
    meals: meals,
    nutrition_summary: Macros(protein: 150.0, fat: 70.0, carbs: 200.0),
    total_cost: option.None,
    recurrence: option.None,
  )
}

fn create_test_meal(
  recipe: String,
  date: String,
  time: String,
) -> advanced.ScheduledMeal {
  advanced.ScheduledMeal(
    recipe_id: id.recipe_id(recipe),
    date: date,
    time: time,
    meal_type: advanced.Breakfast,
    nutrition: Macros(protein: 50.0, fat: 20.0, carbs: 60.0),
    prep_time: option.Some(30),
    cost: option.Some(15.0),
  )
}
