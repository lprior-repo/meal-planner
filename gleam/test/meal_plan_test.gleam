import gleeunit/should
import meal_planner/meal_plan.{DailyPlan, Meal, meal_macros}
import meal_planner/types.{Ingredient, Low, Macros, Recipe}

pub fn meal_macros_test() {
  let recipe =
    Recipe(
      name: "Chicken",
      ingredients: [Ingredient(name: "Chicken", quantity: "200g")],
      instructions: ["Cook"],
      macros: Macros(protein: 40.0, fat: 10.0, carbs: 5.0),
      servings: 1,
      category: "protein",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let meal = Meal(recipe: recipe, portion_size: 2.0)
  let macros = meal_macros(meal)
  macros.protein |> should.equal(80.0)
  macros.fat |> should.equal(20.0)
  macros.carbs |> should.equal(10.0)
}

pub fn daily_plan_creation_test() {
  let recipe =
    Recipe(
      name: "Eggs",
      ingredients: [],
      instructions: [],
      macros: Macros(protein: 12.0, fat: 10.0, carbs: 1.0),
      servings: 1,
      category: "protein",
      fodmap_level: Low,
      vertical_compliant: True,
    )
  let meal = Meal(recipe: recipe, portion_size: 1.0)
  let plan = DailyPlan(day_name: "Monday", meals: [meal])
  plan.day_name |> should.equal("Monday")
}
