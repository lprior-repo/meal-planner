/// Integration Tests for TandoorSDK
///
/// This test suite validates end-to-end SDK workflows using mock transport.
import gleeunit/should
import meal_planner/tandoor/sdk
import meal_planner/tandoor/testing/builders
import meal_planner/tandoor/testing/fixtures
import meal_planner/tandoor/testing/mock_transport

/// Test: Complete recipe CRUD workflow
pub fn recipe_crud_workflow_test() {
  // Setup mock with response queue
  let mock =
    mock_transport.new()
    // Create response
    |> mock_transport.queue_response(
      builders.created()
      |> builders.with_body(fixtures.to_json(fixtures.recipe())),
    )
    // Get response
    |> mock_transport.queue_response(
      builders.success()
      |> builders.with_body(fixtures.to_json(fixtures.recipe())),
    )
    // Update response
    |> mock_transport.queue_response(
      builders.success()
      |> builders.with_body(
        fixtures.to_json(
          fixtures.recipe() |> fixtures.with_name("Updated Recipe"),
        ),
      ),
    )
    // Delete response
    |> mock_transport.queue_response(builders.no_content())

  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.BearerAuth("token"))
    |> sdk.with_transport(mock_transport.as_transport(mock))

  // Create
  let assert Ok(created) =
    sdk.recipes.create(sdk, name: "Test Recipe", servings: 4)
  created.name |> should.equal("Test Recipe")

  // Read
  let assert Ok(fetched) = sdk.recipes.get(sdk, recipe_id: created.id)
  fetched.id |> should.equal(created.id)

  // Update
  let assert Ok(updated) =
    sdk.recipes.update(sdk, recipe_id: created.id, name: "Updated Recipe")
  updated.name |> should.equal("Updated Recipe")

  // Delete
  let assert Ok(_) = sdk.recipes.delete(sdk, recipe_id: created.id)
}

/// Test: Recipe search and filter workflow
pub fn recipe_search_workflow_test() {
  let mock =
    mock_transport.new()
    |> mock_transport.with_response(
      builders.paginated(
        count: 50,
        next: "http://api/recipes?page=2",
        previous: "",
        results: fixtures.to_json([
          fixtures.recipe() |> fixtures.with_id(1),
          fixtures.recipe() |> fixtures.with_id(2),
        ]),
      ),
    )

  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.BearerAuth("token"))
    |> sdk.with_transport(mock_transport.as_transport(mock))

  // List with filters
  let assert Ok(paginated) =
    sdk.recipes.list(sdk, query: "chocolate", keywords: ["dessert"])

  paginated.count |> should.equal(50)
  paginated.results |> should.have_length(2)
}

/// Test: Food inventory workflow
pub fn food_inventory_workflow_test() {
  let mock =
    mock_transport.new()
    // Create food
    |> mock_transport.queue_response(
      builders.created()
      |> builders.with_body(fixtures.to_json(fixtures.food())),
    )
    // Link to recipe
    |> mock_transport.queue_response(builders.success())

  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.BearerAuth("token"))
    |> sdk.with_transport(mock_transport.as_transport(mock))

  // Create food
  let assert Ok(food) = sdk.foods.create(sdk, name: "Tomato")
  food.name |> should.equal("Tomato")

  // Link to recipe ingredient
  let assert Ok(_) =
    sdk.recipes.add_ingredient(sdk, recipe_id: 1, food_id: food.id, amount: 2.0)
}

/// Test: Meal planning workflow
pub fn meal_planning_workflow_test() {
  let mock =
    mock_transport.new()
    // Get recipe
    |> mock_transport.queue_response(
      builders.success()
      |> builders.with_body(fixtures.to_json(fixtures.recipe())),
    )
    // Create mealplan
    |> mock_transport.queue_response(
      builders.created()
      |> builders.with_body(fixtures.to_json(fixtures.mealplan())),
    )
    // List mealplans
    |> mock_transport.queue_response(
      builders.paginated(
        count: 7,
        next: "",
        previous: "",
        results: fixtures.to_json([fixtures.mealplan()]),
      ),
    )

  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.BearerAuth("token"))
    |> sdk.with_transport(mock_transport.as_transport(mock))

  // Get recipe to plan
  let assert Ok(recipe) = sdk.recipes.get(sdk, recipe_id: 1)

  // Add to meal plan
  let assert Ok(mealplan) =
    sdk.mealplans.create(
      sdk,
      recipe_id: recipe.id,
      date: "2025-12-15",
      meal_type: "dinner",
    )

  mealplan.recipe.id |> should.equal(recipe.id)

  // List week's meals
  let assert Ok(week) = sdk.mealplans.list(sdk, from_date: "2025-12-14")
  week.count |> should.equal(7)
}

/// Test: Error recovery workflow
pub fn error_recovery_workflow_test() {
  let mock =
    mock_transport.new()
    // First attempt fails
    |> mock_transport.queue_response(builders.server_error())
    // Retry succeeds
    |> mock_transport.queue_response(
      builders.success()
      |> builders.with_body(fixtures.to_json(fixtures.recipe())),
    )

  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.BearerAuth("token"))
    |> sdk.with_transport(mock_transport.as_transport(mock))
    |> sdk.with_retry(max_retries: 3)

  // Should retry and succeed
  let assert Ok(recipe) = sdk.recipes.get(sdk, recipe_id: 1)
  recipe.id |> should.equal(1)
}

/// Test: Authentication workflow
pub fn authentication_workflow_test() {
  let mock =
    mock_transport.new()
    // Login
    |> mock_transport.queue_response(
      builders.success()
      |> builders.with_header("Set-Cookie", "sessionid=abc123")
      |> builders.with_body("{\"token\": \"bearer-token\"}"),
    )
    // Authenticated request
    |> mock_transport.queue_response(
      builders.success()
      |> builders.with_body(fixtures.to_json(fixtures.recipe())),
    )

  // Initial SDK without auth
  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.NoAuth)
    |> sdk.with_transport(mock_transport.as_transport(mock))

  // Login
  let assert Ok(token) = sdk.auth.login(sdk, username: "test", password: "pass")

  // Update SDK with token
  let authenticated_sdk = sdk |> sdk.with_auth(sdk.BearerAuth(token))

  // Make authenticated request
  let assert Ok(recipe) = authenticated_sdk.recipes.get(recipe_id: 1)
  recipe.id |> should.equal(1)
}

/// Test: Batch operations workflow
pub fn batch_operations_workflow_test() {
  let mock =
    mock_transport.new()
    // Batch create
    |> mock_transport.with_response(
      builders.success()
      |> builders.with_body(
        fixtures.to_json([
          fixtures.food() |> fixtures.with_food_id(1),
          fixtures.food() |> fixtures.with_food_id(2),
          fixtures.food() |> fixtures.with_food_id(3),
        ]),
      ),
    )

  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.BearerAuth("token"))
    |> sdk.with_transport(mock_transport.as_transport(mock))

  // Batch create foods
  let assert Ok(foods) =
    sdk.foods.batch_create(sdk, names: ["Tomato", "Onion", "Garlic"])

  foods |> should.have_length(3)
}
