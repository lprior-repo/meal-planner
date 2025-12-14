/// Tests for TandoorSDK Facade
///
/// This test suite validates the unified SDK facade that combines
/// all Tandoor API modules into a single entry point.
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/sdk
import meal_planner/tandoor/testing/builders
import meal_planner/tandoor/testing/mock_transport

/// Test: Create SDK with Bearer auth
pub fn create_sdk_with_bearer_test() {
  let sdk =
    sdk.new(
      base_url: "http://localhost:8000",
      auth: sdk.BearerAuth("test-token"),
    )

  sdk.base_url |> should.equal("http://localhost:8000")
}

/// Test: Create SDK with Session auth
pub fn create_sdk_with_session_test() {
  let sdk =
    sdk.new(
      base_url: "http://localhost:8000",
      auth: sdk.SessionAuth(username: "test", password: "pass"),
    )

  sdk.base_url |> should.equal("http://localhost:8000")
}

/// Test: SDK recipe operations
pub fn sdk_recipe_operations_test() {
  let mock =
    mock_transport.new()
    |> mock_transport.with_response(
      builders.recipe_response(id: 1, name: "Test Recipe", servings: 4),
    )

  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.BearerAuth("token"))
    |> sdk.with_transport(mock_transport.as_transport(mock))

  // Test get recipe
  let assert Ok(recipe) = sdk.recipes.get(sdk, recipe_id: 1)
  recipe.id |> should.equal(1)
  recipe.name |> should.equal("Test Recipe")
}

/// Test: SDK food operations
pub fn sdk_food_operations_test() {
  let mock =
    mock_transport.new()
    |> mock_transport.with_response(
      builders.food_response(id: 42, name: "Tomato"),
    )

  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.BearerAuth("token"))
    |> sdk.with_transport(mock_transport.as_transport(mock))

  // Test get food
  let assert Ok(food) = sdk.foods.get(sdk, food_id: 42)
  food.id |> should.equal(42)
  food.name |> should.equal("Tomato")
}

/// Test: SDK mealplan operations
pub fn sdk_mealplan_operations_test() {
  let mock =
    mock_transport.new()
    |> mock_transport.with_response(
      builders.success()
      |> builders.with_body("{\"id\": 1, \"recipe\": {\"id\": 1}}"),
    )

  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.BearerAuth("token"))
    |> sdk.with_transport(mock_transport.as_transport(mock))

  // Test get mealplan
  let assert Ok(mealplan) = sdk.mealplans.get(sdk, mealplan_id: 1)
  mealplan.id |> should.equal(1)
}

/// Test: SDK keyword operations
pub fn sdk_keyword_operations_test() {
  let mock =
    mock_transport.new()
    |> mock_transport.with_response(
      builders.success()
      |> builders.with_body(
        "{\"count\": 1, \"results\": [{\"id\": 1, \"name\": \"vegan\"}]}",
      ),
    )

  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.BearerAuth("token"))
    |> sdk.with_transport(mock_transport.as_transport(mock))

  // Test list keywords
  let assert Ok(paginated) = sdk.keywords.list(sdk)
  paginated.count |> should.equal(1)
}

/// Test: SDK unit operations
pub fn sdk_unit_operations_test() {
  let mock =
    mock_transport.new()
    |> mock_transport.with_response(
      builders.success()
      |> builders.with_body("{\"id\": 1, \"name\": \"gram\"}"),
    )

  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.BearerAuth("token"))
    |> sdk.with_transport(mock_transport.as_transport(mock))

  // Test get unit
  let assert Ok(unit) = sdk.units.get(sdk, unit_id: 1)
  unit.id |> should.equal(1)
  unit.name |> should.equal("gram")
}

/// Test: SDK with custom timeout
pub fn sdk_with_custom_timeout_test() {
  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.BearerAuth("token"))
    |> sdk.with_timeout(5000)

  sdk.timeout_ms |> should.equal(5000)
}

/// Test: SDK with retry configuration
pub fn sdk_with_retry_test() {
  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.BearerAuth("token"))
    |> sdk.with_retry(max_retries: 5)

  sdk.max_retries |> should.equal(5)
}

/// Test: SDK error handling
pub fn sdk_error_handling_test() {
  let mock =
    mock_transport.new()
    |> mock_transport.with_response(builders.not_found())

  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.BearerAuth("token"))
    |> sdk.with_transport(mock_transport.as_transport(mock))

  // Test error response
  let assert Error(error) = sdk.recipes.get(sdk, recipe_id: 999)

  case error {
    sdk.NotFoundError(_) -> should.be_true(True)
    _ -> should.be_true(False)
  }
}

/// Test: SDK fluent API
pub fn sdk_fluent_api_test() {
  let sdk =
    sdk.new(base_url: "http://localhost:8000", auth: sdk.BearerAuth("token"))
    |> sdk.with_timeout(3000)
    |> sdk.with_retry(max_retries: 3)

  sdk.timeout_ms |> should.equal(3000)
  sdk.max_retries |> should.equal(3)
}
