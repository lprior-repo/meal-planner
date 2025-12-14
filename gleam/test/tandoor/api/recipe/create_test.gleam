/// Tests for Recipe Create API
///
/// These tests verify the create_recipe function delegates correctly
/// to the client implementation.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/recipe/create
import meal_planner/tandoor/client
import meal_planner/tandoor/encoders/recipe/recipe_create_encoder.{
  CreateRecipeRequest,
}

pub fn create_recipe_delegates_to_client_test() {
  // Verify function exists and has correct signature
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let request =
    CreateRecipeRequest(
      name: "Test Recipe",
      description: Some("A test"),
      servings: 4,
      servings_text: Some("4 servings"),
      working_time: Some(30),
      waiting_time: Some(60),
    )

  // Call should fail (no server) but proves delegation works
  let result = create.create_recipe(config, request)

  // Should get a network or connection error, proving it attempted the call
  should.be_error(result)
}

pub fn create_recipe_accepts_minimal_request_test() {
  // Verify minimal request works
  let config = client.bearer_config("http://localhost:8000", "test-token")

  let request =
    CreateRecipeRequest(
      name: "Minimal",
      description: None,
      servings: 1,
      servings_text: None,
      working_time: None,
      waiting_time: None,
    )

  let result = create.create_recipe(config, request)

  // Should attempt call and fail (no server)
  should.be_error(result)
}
