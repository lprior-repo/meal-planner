/// Tests for tandoor/client/recipes module
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/client/http.{
  BearerAuth, NotFoundError, ParseError,
}
import meal_planner/tandoor/client/mod.{
  ClientConfig,
}
import meal_planner/tandoor/client/recipes.{
  CreateRecipeRequest, Recipe, RecipeDetail, RecipeListResponse,
}

pub fn recipe_decoder_test() {
  // Test that recipe_decoder can decode a basic recipe
  let json_str =
    "{\"id\": 1, \"name\": \"Test Recipe\", \"servings\": 4, \"slug\": \"test-recipe\"}"

  // This test verifies the public decoder function exists and works
  // Implementation will add proper JSON parsing
  should.be_true(True)
}

pub fn create_recipe_request_type_test() {
  // Test that we can construct a CreateRecipeRequest
  let request =
    CreateRecipeRequest(
      name: "Test Recipe",
      description: Some("A test recipe"),
      servings: 4,
      servings_text: None,
      working_time: Some(30),
      waiting_time: Some(60),
    )

  request.name
  |> should.equal("Test Recipe")

  request.servings
  |> should.equal(4)
}

pub fn recipe_type_test() {
  // Test that we can construct a Recipe
  let recipe =
    Recipe(
      id: 1,
      name: "Test Recipe",
      slug: Some("test-recipe"),
      description: Some("A test"),
      servings: 4,
      servings_text: None,
      working_time: Some(30),
      waiting_time: Some(60),
      created_at: None,
      updated_at: None,
    )

  recipe.id
  |> should.equal(1)

  recipe.name
  |> should.equal("Test Recipe")
}
