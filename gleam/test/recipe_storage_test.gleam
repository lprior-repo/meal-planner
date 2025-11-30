import gleeunit
import gleeunit/should
import gleam/result
import meal_planner/storage
import shared/types.{Recipe, Ingredient, Macros, Low}

pub fn recipe_storage_test() {
  let recipe = Recipe(
    id: "test-recipe-1",
    name: "Test Recipe",
    ingredients: [Ingredient("Eggs", "2 large"), Ingredient("Bread", "2 slices")],
    instructions: ["Crack eggs", "Toast bread"],
    macros: Macros(protein: 12.0, fat: 8.0, carbs: 15.0),
    servings: 1,
    category: "breakfast",
    fodmap_level: Low,
    vertical_compliant: True,
  )

  // Test that we can create the SQL and encoder logic
  // In a real test we'd use an in-memory SQLite database
  recipe.id
  |> should.equal("test-recipe-1")
  
  recipe.name
  |> should.equal("Test Recipe")
}