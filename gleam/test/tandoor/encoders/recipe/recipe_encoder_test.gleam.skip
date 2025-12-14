/// Tests for Recipe encoder
///
/// Following TDD: Tests written FIRST, then implementation
import gleam/json
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/encoders/recipe/recipe_encoder
import meal_planner/tandoor/types.{
  TandoorFood, TandoorIngredient, TandoorKeyword, TandoorNutrition,
  TandoorRecipe, TandoorStep, TandoorUnit,
}

pub fn encode_minimal_recipe_test() {
  let recipe =
    TandoorRecipe(
      id: 123,
      name: "Test Recipe",
      description: "A simple test recipe",
      servings: 4,
      servings_text: "4 people",
      prep_time: 15,
      cooking_time: 30,
      ingredients: [],
      steps: [],
      nutrition: None,
      keywords: [],
      image: None,
      internal_id: None,
      created_at: "2024-01-01T00:00:00Z",
      updated_at: "2024-01-01T00:00:00Z",
    )

  let encoded = recipe_encoder.encode(recipe)
  let json_string = json.to_string(encoded)

  // Should contain all required fields
  json_string |> should.contain("\"id\":123")
  json_string |> should.contain("\"name\":\"Test Recipe\"")
  json_string |> should.contain("\"servings\":4")
}
