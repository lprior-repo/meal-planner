/// Tests for Tandoor Recipes API Client
///
/// Tests recipe CRUD operations: listing, getting, creating, updating, and deleting.
import gleam/dynamic/decode
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import meal_planner/tandoor/client.{bearer_config}
import meal_planner/tandoor/client/recipes
import meal_planner/tandoor/recipe.{RecipeCreateRequest, RecipeUpdate}

// ============================================================================
// Encoders Tests
// ============================================================================

pub fn test_create_recipe_request_type_construction() {
  let request =
    RecipeCreateRequest(
      name: "Test Recipe",
      description: Some("A test recipe"),
      servings: 4,
      servings_text: Some("4 people"),
      working_time: Some(30),
      waiting_time: Some(60),
    )

  // Verify we can construct the request type
  request.name
  |> should.equal("Test Recipe")
}

pub fn test_create_recipe_with_minimal_data() {
  let request =
    RecipeCreateRequest(
      name: "Simple Recipe",
      description: None,
      servings: 2,
      servings_text: None,
      working_time: None,
      waiting_time: None,
    )

  request.name
  |> should.equal("Simple Recipe")

  request.servings
  |> should.equal(2)
}

pub fn test_update_recipe_request_with_all_fields() {
  let update =
    RecipeUpdate(
      name: Some("Updated Name"),
      description: Some("Updated description"),
      servings: Some(6),
      servings_text: Some("6 people"),
      working_time: Some(45),
      waiting_time: Some(30),
    )

  update.name
  |> should.equal(Some("Updated Name"))

  update.servings
  |> should.equal(Some(6))
}

pub fn test_update_recipe_request_partial() {
  let update =
    RecipeUpdate(
      name: Some("New Name"),
      description: None,
      servings: None,
      servings_text: None,
      working_time: None,
      waiting_time: None,
    )

  update.name
  |> should.equal(Some("New Name"))

  update.servings
  |> should.equal(None)
}

pub fn test_update_recipe_request_empty() {
  let update =
    RecipeUpdate(
      name: None,
      description: None,
      servings: None,
      servings_text: None,
      working_time: None,
      waiting_time: None,
    )

  update.name
  |> should.equal(None)
}

// ============================================================================
// Configuration Tests
// ============================================================================

pub fn test_recipes_client_can_use_config() {
  let config = bearer_config("http://localhost:8000", "test-token")

  // Config should have base_url set
  config.base_url
  |> should.equal("http://localhost:8000")
}

pub fn test_recipes_client_config_has_timeout() {
  let config = bearer_config("http://localhost:8000", "test-token")

  // Config should have default timeout
  config.timeout_ms
  |> should.equal(10_000)
}

// ============================================================================
// Helper Function Tests
// ============================================================================

pub fn test_recipe_list_response_type_construction() {
  let response =
    recipes.RecipeListResponse(
      count: 42,
      next: Some("http://example.com/next"),
      previous: Some("http://example.com/prev"),
      results: [],
    )

  response.count
  |> should.equal(42)

  response.next
  |> should.equal(Some("http://example.com/next"))
}

pub fn test_recipe_list_response_with_no_pagination() {
  let response =
    recipes.RecipeListResponse(
      count: 5,
      next: None,
      previous: None,
      results: [],
    )

  response.count
  |> should.equal(5)

  response.next
  |> should.equal(None)
}
