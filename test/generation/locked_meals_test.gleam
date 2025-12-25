//// Tests for locked meal handling and validation
////
//// This module tests the locked_meals module which provides:
//// - Applying locked meals to a generated plan
//// - Validating for conflicts (2 locks for same slot)

import gleam/list
import gleeunit/should
import meal_planner/generation/locked_meals.{
  LockConflict, apply_locked_meals, check_lock_conflicts,
}
import meal_planner/generator/weekly.{
  type DayMeals, Breakfast, Constraints, DayMeals, Dinner, LockedMeal, Lunch,
}
import meal_planner/id
import meal_planner/types/recipe.{type Recipe, Recipe, Low}
import meal_planner/types/macros.{Macros}

// ============================================================================
// Test Fixtures
// ============================================================================

fn test_recipe(name: String, protein: Float, fat: Float, carbs: Float) -> Recipe {
  Recipe(
    id: id.recipe_id("1"),
    name: name,
    ingredients: [],
    instructions: [],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: "test",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

fn test_plan() -> List(DayMeals) {
  [
    DayMeals(
      day: "Monday",
      breakfast: test_recipe("Default Breakfast", 20.0, 10.0, 30.0),
      lunch: test_recipe("Default Lunch", 30.0, 15.0, 40.0),
      dinner: test_recipe("Default Dinner", 35.0, 20.0, 45.0),
    ),
    DayMeals(
      day: "Friday",
      breakfast: test_recipe("Default Breakfast", 20.0, 10.0, 30.0),
      lunch: test_recipe("Default Lunch", 30.0, 15.0, 40.0),
      dinner: test_recipe("Default Dinner", 35.0, 20.0, 45.0),
    ),
  ]
}

// ============================================================================
// Conflict Detection Tests
// ============================================================================

pub fn no_conflicts_with_empty_locks_test() {
  let constraints = Constraints(locked_meals: [], travel_dates: [])
  let result = check_lock_conflicts(constraints)
  result |> should.be_ok
}

pub fn no_conflicts_with_different_slots_test() {
  let lock1 =
    LockedMeal(
      day: "Monday",
      meal_type: Breakfast,
      recipe: test_recipe("Pancakes", 25.0, 12.0, 35.0),
    )
  let lock2 =
    LockedMeal(
      day: "Monday",
      meal_type: Dinner,
      recipe: test_recipe("Pasta", 40.0, 18.0, 60.0),
    )
  let constraints = Constraints(locked_meals: [lock1, lock2], travel_dates: [])

  let result = check_lock_conflicts(constraints)
  result |> should.be_ok
}

pub fn detects_conflict_same_day_same_meal_test() {
  let lock1 =
    LockedMeal(
      day: "Friday",
      meal_type: Dinner,
      recipe: test_recipe("Pasta", 40.0, 18.0, 60.0),
    )
  let lock2 =
    LockedMeal(
      day: "Friday",
      meal_type: Dinner,
      recipe: test_recipe("Pizza", 35.0, 20.0, 70.0),
    )
  let constraints = Constraints(locked_meals: [lock1, lock2], travel_dates: [])

  let result = check_lock_conflicts(constraints)
  result
  |> should.be_error
  |> should.equal(LockConflict(day: "Friday", meal_type: Dinner))
}

pub fn allows_same_recipe_different_days_test() {
  let recipe = test_recipe("Pasta", 40.0, 18.0, 60.0)
  let lock1 = LockedMeal(day: "Monday", meal_type: Dinner, recipe: recipe)
  let lock2 = LockedMeal(day: "Friday", meal_type: Dinner, recipe: recipe)
  let constraints = Constraints(locked_meals: [lock1, lock2], travel_dates: [])

  let result = check_lock_conflicts(constraints)
  result |> should.be_ok
}

// ============================================================================
// Apply Locked Meals Tests
// ============================================================================

pub fn apply_locked_meals_replaces_correct_position_test() {
  let plan = test_plan()
  let locked_recipe = test_recipe("Locked Pasta", 45.0, 20.0, 80.0)
  let lock = LockedMeal(day: "Friday", meal_type: Dinner, recipe: locked_recipe)
  let constraints = Constraints(locked_meals: [lock], travel_dates: [])

  let result = apply_locked_meals(plan, constraints)
  result |> should.be_ok

  // Verify Friday dinner was replaced
  case result {
    Ok(updated_plan) -> {
      let friday =
        list.find(updated_plan, fn(d) { d.day == "Friday" }) |> should.be_ok
      friday.dinner.name |> should.equal("Locked Pasta")
    }
    Error(_) -> should.fail()
  }
}

pub fn apply_locked_meals_preserves_other_meals_test() {
  let plan = test_plan()
  let locked_recipe = test_recipe("Locked Pancakes", 25.0, 12.0, 35.0)
  let lock =
    LockedMeal(day: "Monday", meal_type: Breakfast, recipe: locked_recipe)
  let constraints = Constraints(locked_meals: [lock], travel_dates: [])

  let result = apply_locked_meals(plan, constraints)
  result |> should.be_ok

  case result {
    Ok(updated_plan) -> {
      let monday =
        list.find(updated_plan, fn(d) { d.day == "Monday" }) |> should.be_ok
      // Breakfast should be locked
      monday.breakfast.name |> should.equal("Locked Pancakes")
      // Lunch and dinner should be unchanged
      monday.lunch.name |> should.equal("Default Lunch")
      monday.dinner.name |> should.equal("Default Dinner")
    }
    Error(_) -> should.fail()
  }
}

pub fn apply_locked_meals_with_conflicts_returns_error_test() {
  let plan = test_plan()
  let lock1 =
    LockedMeal(
      day: "Friday",
      meal_type: Dinner,
      recipe: test_recipe("Pasta", 40.0, 18.0, 60.0),
    )
  let lock2 =
    LockedMeal(
      day: "Friday",
      meal_type: Dinner,
      recipe: test_recipe("Pizza", 35.0, 20.0, 70.0),
    )
  let constraints = Constraints(locked_meals: [lock1, lock2], travel_dates: [])

  let result = apply_locked_meals(plan, constraints)
  result |> should.be_error
}

pub fn apply_locked_meals_ignores_missing_days_test() {
  let plan = test_plan()
  // Lock a day that doesn't exist in the plan
  let locked_recipe = test_recipe("Special Lunch", 30.0, 15.0, 40.0)
  let lock =
    LockedMeal(day: "Wednesday", meal_type: Lunch, recipe: locked_recipe)
  let constraints = Constraints(locked_meals: [lock], travel_dates: [])

  let result = apply_locked_meals(plan, constraints)
  result |> should.be_ok

  // Plan should be unchanged since Wednesday doesn't exist
  case result {
    Ok(updated_plan) -> {
      list.length(updated_plan) |> should.equal(list.length(plan))
    }
    Error(_) -> should.fail()
  }
}
