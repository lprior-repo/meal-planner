import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/types/recipe/recipe_simple.{RecipeSimple}

pub fn recipe_simple_constructor_test() {
  let recipe = RecipeSimple(id: 1, name: "Pasta", image: Some("pasta.jpg"))

  recipe.id
  |> should.equal(1)

  recipe.name
  |> should.equal("Pasta")

  recipe.image
  |> should.equal(Some("pasta.jpg"))
}

pub fn recipe_simple_no_image_test() {
  let recipe = RecipeSimple(id: 2, name: "Salad", image: None)

  recipe.id
  |> should.equal(2)

  recipe.name
  |> should.equal("Salad")

  recipe.image
  |> should.equal(None)
}

pub fn recipe_simple_minimal_fields_test() {
  // RecipeSimple should only have id, name, and optional image
  // This test verifies the type has exactly these fields
  let recipe =
    RecipeSimple(id: 42, name: "Test Recipe", image: Some("test.png"))

  should.equal(recipe.id, 42)
  should.equal(recipe.name, "Test Recipe")
  should.equal(recipe.image, Some("test.png"))
}
