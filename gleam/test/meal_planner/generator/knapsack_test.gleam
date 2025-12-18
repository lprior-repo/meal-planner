import gleeunit/should
import meal_planner/generator/knapsack
import meal_planner/id.{recipe_id}
import meal_planner/types.{type Recipe, Low, Macros, Recipe}

fn test_recipe() -> Recipe {
  Recipe(
    id: recipe_id("1"),
    name: "Test Recipe",
    ingredients: [],
    instructions: [],
    macros: Macros(protein: 20.0, carbs: 30.0, fat: 10.0),
    servings: 1,
    category: "Test",
    fodmap_level: Low,
    vertical_compliant: True,
  )
}

pub fn solve_with_zero_meals_test() {
  let recipes = [test_recipe()]

  knapsack.solve(2000, recipes, 0)
  |> should.be_error
}

pub fn solve_with_negative_meals_test() {
  let recipes = [test_recipe()]

  knapsack.solve(2000, recipes, -5)
  |> should.be_error
}
