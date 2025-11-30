import gleeunit/should
import meal_planner/types.{
  Ingredient, Macros, Recipe, macros_add, macros_calories, macros_scale,
}

pub fn macros_calories_test() {
  // 4cal/g protein, 9cal/g fat, 4cal/g carbs
  let m = Macros(protein: 30.0, fat: 10.0, carbs: 50.0)
  // (30 * 4) + (10 * 9) + (50 * 4) = 120 + 90 + 200 = 410
  macros_calories(m)
  |> should.equal(410.0)
}

pub fn macros_calories_zero_test() {
  let m = Macros(protein: 0.0, fat: 0.0, carbs: 0.0)
  macros_calories(m)
  |> should.equal(0.0)
}

pub fn macros_add_test() {
  let m1 = Macros(protein: 20.0, fat: 10.0, carbs: 30.0)
  let m2 = Macros(protein: 15.0, fat: 5.0, carbs: 25.0)
  let result = macros_add(m1, m2)
  result.protein |> should.equal(35.0)
  result.fat |> should.equal(15.0)
  result.carbs |> should.equal(55.0)
}

pub fn macros_scale_test() {
  let m = Macros(protein: 10.0, fat: 5.0, carbs: 20.0)
  let result = macros_scale(m, 2.0)
  result.protein |> should.equal(20.0)
  result.fat |> should.equal(10.0)
  result.carbs |> should.equal(40.0)
}

// Ingredient tests

pub fn ingredient_creation_test() {
  let ing = Ingredient(name: "Chicken breast", quantity: "200g")
  ing.name |> should.equal("Chicken breast")
  ing.quantity |> should.equal("200g")
}

// Recipe tests

pub fn recipe_creation_test() {
  let macros = Macros(protein: 40.0, fat: 10.0, carbs: 5.0)
  let ingredients = [
    Ingredient(name: "Chicken breast", quantity: "200g"),
    Ingredient(name: "Olive oil", quantity: "1 tbsp"),
  ]
  let instructions = ["Season chicken", "Grill for 6 min per side"]
  let recipe =
    Recipe(
      name: "Grilled Chicken",
      ingredients: ingredients,
      instructions: instructions,
      macros: macros,
      servings: 2,
      category: "protein",
      fodmap_level: "low",
      vertical_compliant: True,
    )
  recipe.name |> should.equal("Grilled Chicken")
  recipe.servings |> should.equal(2)
  recipe.vertical_compliant |> should.be_true()
}
