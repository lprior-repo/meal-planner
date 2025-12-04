/// Tests for generator module
import gleam/list
import gleeunit
import gleeunit/should
import meal_planner/generator.{regenerate_slot}
import meal_planner/meal_plan.{DailyPlan, Meal}
import meal_planner/types.{Low, Macros, Recipe}

pub fn main() {
  gleeunit.main()
}

/// Create a test recipe with specified calories
fn create_test_recipe(id: String, name: String, calories: Float) -> Recipe {
  let protein = calories *. 0.3 /. 4.0
  let fat = calories *. 0.3 /. 9.0
  let carbs = calories *. 0.4 /. 4.0

  Recipe(
    id: id,
    name: name,
    ingredients: [],
    instructions: [],
    macros: Macros(protein: protein, fat: fat, carbs: carbs),
    servings: 1,
    category: "test",
    fodmap_level: Low,
    vertical_compliant: False,
  )
}

/// Create a test meal from a recipe
fn create_test_meal(recipe: Recipe) -> Meal {
  Meal(recipe: recipe, portion_size: 1.0)
}

/// Test that regenerate_slot successfully swaps lunch
pub fn test_regenerate_lunch_successfully() {
  // Create recipes: breakfast (600 cal), lunch (800 cal), dinner (900 cal)
  let breakfast_recipe = create_test_recipe("1", "Oats", 600.0)
  let lunch_recipe = create_test_recipe("2", "Chicken Salad", 800.0)
  let dinner_recipe = create_test_recipe("3", "Steak", 900.0)

  // Create a daily plan with these meals
  let day_plan =
    DailyPlan(day_name: "Monday", meals: [
      create_test_meal(breakfast_recipe),
      create_test_meal(lunch_recipe),
      create_test_meal(dinner_recipe),
    ])

  // Available recipes to choose from (different lunch options)
  let new_lunch_option = create_test_recipe("4", "Turkey Sandwich", 800.0)
  let available = [new_lunch_option]

  // Daily calorie target is 2500
  let target = 2500

  // Regenerate lunch (slot 1)
  let result = regenerate_slot(day_plan, "lunch", target, available)

  // Should return the new lunch recipe
  result
  |> should.be_ok
  |> fn(recipe) {
    recipe.id
    |> should.equal("4")
    recipe.name
    |> should.equal("Turkey Sandwich")
  }
}

/// Test that invalid slot names are rejected
pub fn test_regenerate_invalid_slot() {
  let day_plan = DailyPlan(day_name: "Monday", meals: [])
  let available = []

  let result = regenerate_slot(day_plan, "snack", 2500, available)

  result
  |> should.be_error
}

/// Test that missing slot is rejected
pub fn test_regenerate_slot_not_found() {
  let day_plan = DailyPlan(day_name: "Monday", meals: [])

  let result = regenerate_slot(day_plan, "lunch", 2500, [])

  result
  |> should.be_error
}

/// Test that no available recipes returns error
pub fn test_regenerate_no_recipes_available() {
  let breakfast_recipe = create_test_recipe("1", "Oats", 600.0)
  let day_plan =
    DailyPlan(day_name: "Monday", meals: [create_test_meal(breakfast_recipe)])

  let result = regenerate_slot(day_plan, "breakfast", 2500, [])

  result
  |> should.be_error
}
