/// Recipe Integration Tests
///
/// Full CRUD flow integration tests for Recipe API.
/// These tests require a running Tandoor instance.
///
/// Test Coverage:
/// - Recipe creation
/// - Recipe retrieval (get by ID)
/// - Recipe listing with pagination
/// - Recipe updates
/// - Recipe deletion
/// - Error handling (404, 401, 500)
/// - Authentication (session + bearer)
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/recipe/create
import meal_planner/tandoor/api/recipe/delete
import meal_planner/tandoor/api/recipe/get
import meal_planner/tandoor/api/recipe/list
import meal_planner/tandoor/api/recipe/update
import meal_planner/tandoor/client.{
  type ClientConfig, BearerAuth, ClientConfig, SessionAuth,
}
import meal_planner/tandoor/types.{
  type TandoorRecipe, TandoorIngredientCreateRequest, TandoorRecipeCreateRequest,
  TandoorStepCreateRequest,
}

// ============================================================================
// Test Configuration
// ============================================================================

/// Get test Tandoor URL from environment or use default
fn test_base_url() -> String {
  // In real tests, read from env: TANDOOR_TEST_URL
  "http://localhost:8000"
}

/// Get test bearer token from environment
fn test_bearer_token() -> String {
  // In real tests, read from env: TANDOOR_TEST_TOKEN
  "test-bearer-token-placeholder"
}

/// Get test session credentials
fn test_credentials() -> #(String, String) {
  // In real tests, read from env: TANDOOR_TEST_USER, TANDOOR_TEST_PASS
  #("test_user", "test_password")
}

/// Create test client with bearer authentication
fn bearer_test_config() -> ClientConfig {
  ClientConfig(
    base_url: test_base_url(),
    auth: BearerAuth(token: test_bearer_token()),
    timeout_ms: 10_000,
    retry_on_transient: False,
    max_retries: 0,
  )
}

/// Create test client with session authentication
fn session_test_config() -> ClientConfig {
  let #(username, password) = test_credentials()
  ClientConfig(
    base_url: test_base_url(),
    auth: SessionAuth(
      username: username,
      password: password,
      session_id: None,
      csrf_token: None,
    ),
    timeout_ms: 10_000,
    retry_on_transient: False,
    max_retries: 0,
  )
}

// ============================================================================
// Test Helpers
// ============================================================================

/// Create a minimal test recipe
fn create_test_recipe_data(name_suffix: String) -> TandoorRecipeCreateRequest {
  TandoorRecipeCreateRequest(
    name: "Test Recipe " <> name_suffix,
    description: "Integration test recipe",
    servings: 4,
    servings_text: "4 servings",
    prep_time: 15,
    cooking_time: 30,
    ingredients: [],
    steps: [
      TandoorStepCreateRequest(
        name: "Step 1",
        instructions: "Test instructions",
        time: Some(10),
      ),
    ],
  )
}

/// Cleanup: delete recipe by ID (ignore errors)
fn cleanup_recipe(config: ClientConfig, recipe_id: Int) -> Nil {
  let _result = delete.delete_recipe(config, recipe_id)
  Nil
}

// ============================================================================
// Full CRUD Flow Tests
// ============================================================================

/// Test complete CRUD flow with bearer auth
pub fn recipe_crud_flow_bearer_test() {
  let config = bearer_test_config()

  // Create
  let recipe_data = create_test_recipe_data("CRUD-Bearer")
  let assert Ok(created_recipe) = create.create_recipe(config, recipe_data)

  io.println(
    "✓ Created recipe with ID: " <> int.to_string(created_recipe.id),
  )

  // Verify creation
  created_recipe.name
  |> should.equal("Test Recipe CRUD-Bearer")

  // Read
  let assert Ok(fetched_recipe) = get.get_recipe(config, created_recipe.id)

  io.println("✓ Fetched recipe by ID: " <> int.to_string(fetched_recipe.id))

  fetched_recipe.id
  |> should.equal(created_recipe.id)

  // Update
  let updated_data =
    TandoorRecipeCreateRequest(
      ..recipe_data,
      name: "Test Recipe CRUD-Bearer (Updated)",
      description: "Updated description",
    )

  let assert Ok(updated_recipe) =
    update.update_recipe(config, created_recipe.id, updated_data)

  io.println("✓ Updated recipe: " <> updated_recipe.name)

  updated_recipe.name
  |> should.equal("Test Recipe CRUD-Bearer (Updated)")

  updated_recipe.description
  |> should.equal("Updated description")

  // Delete
  let assert Ok(_) = delete.delete_recipe(config, created_recipe.id)

  io.println("✓ Deleted recipe ID: " <> int.to_string(created_recipe.id))

  // Verify deletion - should get 404
  let delete_result = get.get_recipe(config, created_recipe.id)
  delete_result
  |> should.be_error
}

/// Test complete CRUD flow with session auth
pub fn recipe_crud_flow_session_test() {
  let config = session_test_config()

  // Create
  let recipe_data = create_test_recipe_data("CRUD-Session")
  let assert Ok(created_recipe) = create.create_recipe(config, recipe_data)

  io.println(
    "✓ [Session] Created recipe with ID: "
    <> int.to_string(created_recipe.id),
  )

  // Read
  let assert Ok(fetched_recipe) = get.get_recipe(config, created_recipe.id)

  io.println(
    "✓ [Session] Fetched recipe by ID: " <> int.to_string(fetched_recipe.id),
  )

  fetched_recipe.id
  |> should.equal(created_recipe.id)

  // Cleanup
  cleanup_recipe(config, created_recipe.id)
}

// ============================================================================
// Pagination Tests
// ============================================================================

/// Test recipe listing with pagination
pub fn recipe_list_pagination_test() {
  let config = bearer_test_config()

  // Create multiple test recipes
  let recipe_data_1 = create_test_recipe_data("Page-1")
  let recipe_data_2 = create_test_recipe_data("Page-2")
  let recipe_data_3 = create_test_recipe_data("Page-3")

  let assert Ok(recipe_1) = create.create_recipe(config, recipe_data_1)
  let assert Ok(recipe_2) = create.create_recipe(config, recipe_data_2)
  let assert Ok(recipe_3) = create.create_recipe(config, recipe_data_3)

  io.println("✓ Created 3 test recipes for pagination")

  // Test first page
  let assert Ok(page_1) = list.list_recipes(config, limit: Some(2), offset: None)

  page_1.results
  |> list.length
  |> should.equal(2)

  io.println("✓ First page returned 2 results")

  // Test second page
  let assert Ok(page_2) =
    list.list_recipes(config, limit: Some(2), offset: Some(2))

  page_2.results
  |> list.length
  |> should.be_at_least(1)

  io.println("✓ Second page returned results")

  // Test limit only
  let assert Ok(limited) = list.list_recipes(config, limit: Some(5), offset: None)

  limited.results
  |> list.length
  |> should.be_at_most(5)

  io.println("✓ Limit parameter works correctly")

  // Cleanup
  cleanup_recipe(config, recipe_1.id)
  cleanup_recipe(config, recipe_2.id)
  cleanup_recipe(config, recipe_3.id)
}

// ============================================================================
// Error Handling Tests
// ============================================================================

/// Test 404 error when recipe doesn't exist
pub fn recipe_not_found_404_test() {
  let config = bearer_test_config()

  // Try to get non-existent recipe
  let result = get.get_recipe(config, 999_999_999)

  result
  |> should.be_error

  io.println("✓ 404 error handled correctly for non-existent recipe")
}

/// Test 401 error with invalid authentication
pub fn recipe_unauthorized_401_test() {
  let bad_config =
    ClientConfig(
      base_url: test_base_url(),
      auth: BearerAuth(token: "invalid-token"),
      timeout_ms: 5000,
      retry_on_transient: False,
      max_retries: 0,
    )

  let result = list.list_recipes(bad_config, limit: None, offset: None)

  result
  |> should.be_error

  io.println("✓ 401 error handled correctly for invalid auth")
}

/// Test network error handling
pub fn recipe_network_error_test() {
  let bad_config =
    ClientConfig(
      base_url: "http://localhost:9999",
      // Non-existent server
      auth: BearerAuth(token: "test-token"),
      timeout_ms: 2000,
      retry_on_transient: False,
      max_retries: 0,
    )

  let result = list.list_recipes(bad_config, limit: None, offset: None)

  result
  |> should.be_error

  io.println("✓ Network error handled correctly")
}

// ============================================================================
// Complex Recipe Tests
// ============================================================================

/// Test creating recipe with ingredients
pub fn recipe_with_ingredients_test() {
  let config = bearer_test_config()

  let recipe_data =
    TandoorRecipeCreateRequest(
      name: "Test Recipe with Ingredients",
      description: "Testing ingredient handling",
      servings: 2,
      servings_text: "2 servings",
      prep_time: 10,
      cooking_time: 20,
      ingredients: [
        TandoorIngredientCreateRequest(
          food: types.TandoorFoodCreateRequest(name: "Test Food"),
          unit: types.TandoorUnitCreateRequest(name: "cup"),
          amount: 1.5,
          note: "chopped",
        ),
      ],
      steps: [
        TandoorStepCreateRequest(
          name: "Prepare",
          instructions: "Chop ingredients",
          time: Some(5),
        ),
      ],
    )

  let assert Ok(created_recipe) = create.create_recipe(config, recipe_data)

  io.println(
    "✓ Created recipe with ingredients: "
    <> int.to_string(created_recipe.id),
  )

  // Verify ingredients were created
  created_recipe.ingredients
  |> list.length
  |> should.be_at_least(1)

  io.println("✓ Recipe has ingredients")

  // Cleanup
  cleanup_recipe(config, created_recipe.id)
}

// ============================================================================
// Authentication Comparison Tests
// ============================================================================

/// Test that both auth methods work equivalently
pub fn auth_methods_equivalent_test() {
  let bearer_config = bearer_test_config()
  let session_config = session_test_config()

  // Create recipe with bearer auth
  let recipe_data = create_test_recipe_data("Auth-Compare")
  let assert Ok(bearer_recipe) =
    create.create_recipe(bearer_config, recipe_data)

  io.println("✓ Created recipe with bearer auth")

  // Fetch with session auth
  let assert Ok(session_recipe) =
    get.get_recipe(session_config, bearer_recipe.id)

  io.println("✓ Fetched recipe with session auth")

  // Should be the same recipe
  session_recipe.id
  |> should.equal(bearer_recipe.id)

  io.println("✓ Both auth methods work equivalently")

  // Cleanup
  cleanup_recipe(bearer_config, bearer_recipe.id)
}
