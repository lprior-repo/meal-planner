/// Food Integration Tests
///
/// Full CRUD flow integration tests for Food API.
/// These tests require a running Tandoor instance.
///
/// Test Coverage:
/// - Food creation
/// - Food retrieval (get by ID)
/// - Food listing with pagination
/// - Food updates
/// - Food deletion
/// - Error handling (404, 401)
/// - Authentication (bearer)
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import meal_planner/tandoor/api/food/create
import meal_planner/tandoor/api/food/delete
import meal_planner/tandoor/api/food/get
import meal_planner/tandoor/api/food/list
import meal_planner/tandoor/api/food/update
import meal_planner/tandoor/client.{
  type ClientConfig, BearerAuth, ClientConfig,
}
import meal_planner/tandoor/types.{TandoorFoodCreateRequest}

// ============================================================================
// Test Configuration
// ============================================================================

fn test_base_url() -> String {
  "http://localhost:8000"
}

fn test_bearer_token() -> String {
  "test-bearer-token-placeholder"
}

fn test_config() -> ClientConfig {
  ClientConfig(
    base_url: test_base_url(),
    auth: BearerAuth(token: test_bearer_token()),
    timeout_ms: 10_000,
    retry_on_transient: False,
    max_retries: 0,
  )
}

// ============================================================================
// Test Helpers
// ============================================================================

fn create_test_food_data(name_suffix: String) -> TandoorFoodCreateRequest {
  TandoorFoodCreateRequest(name: "Test Food " <> name_suffix)
}

fn cleanup_food(config: ClientConfig, food_id: Int) -> Nil {
  let _result = delete.delete_food(config, food_id)
  Nil
}

// ============================================================================
// Full CRUD Flow Tests
// ============================================================================

/// Test complete CRUD flow for Food
pub fn food_crud_flow_test() {
  let config = test_config()

  // Create
  let food_data = create_test_food_data("CRUD")
  let assert Ok(created_food) = create.create_food(config, food_data)

  io.println("✓ Created food with ID: " <> int.to_string(created_food.id))

  created_food.name
  |> should.equal("Test Food CRUD")

  // Read
  let assert Ok(fetched_food) = get.get_food(config, created_food.id)

  io.println("✓ Fetched food by ID: " <> int.to_string(fetched_food.id))

  fetched_food.id
  |> should.equal(created_food.id)

  // Update
  let updated_data = TandoorFoodCreateRequest(name: "Test Food CRUD (Updated)")

  let assert Ok(updated_food) =
    update.update_food(config, created_food.id, updated_data)

  io.println("✓ Updated food: " <> updated_food.name)

  updated_food.name
  |> should.equal("Test Food CRUD (Updated)")

  // Delete
  let assert Ok(_) = delete.delete_food(config, created_food.id)

  io.println("✓ Deleted food ID: " <> int.to_string(created_food.id))

  // Verify deletion - should get 404
  let delete_result = get.get_food(config, created_food.id)
  delete_result
  |> should.be_error
}

// ============================================================================
// Pagination Tests
// ============================================================================

/// Test food listing with pagination
pub fn food_list_pagination_test() {
  let config = test_config()

  // Create test foods
  let food_data_1 = create_test_food_data("Page-1")
  let food_data_2 = create_test_food_data("Page-2")
  let food_data_3 = create_test_food_data("Page-3")

  let assert Ok(food_1) = create.create_food(config, food_data_1)
  let assert Ok(food_2) = create.create_food(config, food_data_2)
  let assert Ok(food_3) = create.create_food(config, food_data_3)

  io.println("✓ Created 3 test foods for pagination")

  // Test first page
  let assert Ok(page_1) = list.list_foods(config, limit: Some(2), page: None)

  page_1.results
  |> list.length
  |> should.equal(2)

  io.println("✓ First page returned 2 results")

  // Test second page
  let assert Ok(page_2) = list.list_foods(config, limit: Some(2), page: Some(2))

  page_2.results
  |> list.length
  |> should.be_at_least(1)

  io.println("✓ Second page returned results")

  // Test limit only
  let assert Ok(limited) = list.list_foods(config, limit: Some(5), page: None)

  limited.results
  |> list.length
  |> should.be_at_most(5)

  io.println("✓ Limit parameter works correctly")

  // Cleanup
  cleanup_food(config, food_1.id)
  cleanup_food(config, food_2.id)
  cleanup_food(config, food_3.id)
}

// ============================================================================
// Error Handling Tests
// ============================================================================

/// Test 404 error when food doesn't exist
pub fn food_not_found_404_test() {
  let config = test_config()

  let result = get.get_food(config, 999_999_999)

  result
  |> should.be_error

  io.println("✓ 404 error handled correctly for non-existent food")
}

/// Test 401 error with invalid authentication
pub fn food_unauthorized_401_test() {
  let bad_config =
    ClientConfig(
      base_url: test_base_url(),
      auth: BearerAuth(token: "invalid-token"),
      timeout_ms: 5000,
      retry_on_transient: False,
      max_retries: 0,
    )

  let result = list.list_foods(bad_config, limit: None, page: None)

  result
  |> should.be_error

  io.println("✓ 401 error handled correctly for invalid auth")
}

/// Test network error handling
pub fn food_network_error_test() {
  let bad_config =
    ClientConfig(
      base_url: "http://localhost:9999",
      auth: BearerAuth(token: "test-token"),
      timeout_ms: 2000,
      retry_on_transient: False,
      max_retries: 0,
    )

  let result = list.list_foods(bad_config, limit: None, page: None)

  result
  |> should.be_error

  io.println("✓ Network error handled correctly")
}

// ============================================================================
// Bulk Operations Tests
// ============================================================================

/// Test creating multiple foods in sequence
pub fn food_bulk_create_test() {
  let config = test_config()

  let foods_to_create = [
    create_test_food_data("Bulk-1"),
    create_test_food_data("Bulk-2"),
    create_test_food_data("Bulk-3"),
    create_test_food_data("Bulk-4"),
    create_test_food_data("Bulk-5"),
  ]

  // Create all foods
  let created_foods =
    foods_to_create
    |> list.map(fn(food_data) {
      let assert Ok(food) = create.create_food(config, food_data)
      food
    })

  created_foods
  |> list.length
  |> should.equal(5)

  io.println("✓ Created 5 foods in bulk")

  // Cleanup all
  created_foods
  |> list.each(fn(food) { cleanup_food(config, food.id) })

  io.println("✓ Cleaned up bulk foods")
}

// ============================================================================
// Search/Filter Tests
// ============================================================================

/// Test listing all foods without filters
pub fn food_list_all_test() {
  let config = test_config()

  // Create a test food to ensure at least one exists
  let food_data = create_test_food_data("List-All")
  let assert Ok(created_food) = create.create_food(config, food_data)

  io.println("✓ Created test food for list all")

  // List all foods
  let assert Ok(response) = list.list_foods(config, limit: None, page: None)

  response.results
  |> list.length
  |> should.be_at_least(1)

  io.println(
    "✓ Listed all foods, count: " <> int.to_string(list.length(response.results)),
  )

  // Cleanup
  cleanup_food(config, created_food.id)
}
